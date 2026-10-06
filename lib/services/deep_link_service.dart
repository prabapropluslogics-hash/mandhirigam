import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../features/book_details/presentation/screens/book_details_screen.dart';
import '../routing/app_routes.dart';
import 'book_link.dart';
import 'local_preferences.dart';

enum InstallReferrerStatus { ok, unsupported, unavailable }

class InstallReferrerResult {
  const InstallReferrerResult(this.status, [this.referrer]);

  final InstallReferrerStatus status;
  final String? referrer;
}

/// Where incoming links come from. The app ships a platform implementation;
/// a third-party link provider would be another implementation of this.
abstract class DeepLinkSource {
  /// The link that launched the app, returned at most once.
  Future<String?> initialLink();

  /// Links delivered while the app is running.
  Stream<String> get links;

  /// The Google Play install referrer (Android only).
  Future<InstallReferrerResult> installReferrer();

  void dispose();
}

/// Talks to `MainActivity` over the `maanthirigam/deep_links` channel.
class PlatformDeepLinkSource implements DeepLinkSource {
  static const MethodChannel _channel = MethodChannel('maanthirigam/deep_links');

  final StreamController<String> _links = StreamController<String>.broadcast();
  bool _listening = false;

  void _listen() {
    if (_listening) return;
    _listening = true;
    _channel.setMethodCallHandler((MethodCall call) async {
      if (call.method == 'onLink' && call.arguments is String) {
        _links.add(call.arguments as String);
      }
      return null;
    });
  }

  @override
  Stream<String> get links {
    _listen();
    return _links.stream;
  }

  @override
  Future<String?> initialLink() async {
    _listen();
    try {
      return await _channel.invokeMethod<String>('getInitialLink');
    } on MissingPluginException {
      return null;
    } on PlatformException {
      return null;
    }
  }

  @override
  Future<InstallReferrerResult> installReferrer() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return const InstallReferrerResult(InstallReferrerStatus.unsupported);
    }
    try {
      final Map<Object?, Object?>? result = await _channel
          .invokeMapMethod<Object?, Object?>('getInstallReferrer')
          .timeout(const Duration(seconds: 10), onTimeout: () => null);
      final Object? status = result?['status'];
      final Object? referrer = result?['referrer'];
      if (status == 'ok') {
        return InstallReferrerResult(
          InstallReferrerStatus.ok,
          referrer is String ? referrer : '',
        );
      }
      if (status == 'unsupported') {
        return const InstallReferrerResult(InstallReferrerStatus.unsupported);
      }
      return const InstallReferrerResult(InstallReferrerStatus.unavailable);
    } on MissingPluginException {
      return const InstallReferrerResult(InstallReferrerStatus.unavailable);
    } on PlatformException {
      return const InstallReferrerResult(InstallReferrerStatus.unavailable);
    }
  }

  @override
  void dispose() {
    if (_listening) _channel.setMethodCallHandler(null);
    _links.close();
  }
}

/// Turns validated book links into a single push of Book Details.
///
/// Links are only acted on once the app is ready (past splash, not on the
/// login screen or over a sheet/dialog); until then the latest one waits.
/// Book Details then runs the normal access, sign-in and purchase flow.
class DeepLinkService {
  DeepLinkService({
    required LocalPreferences preferences,
    DeepLinkSource? source,
    BookLinks? links,
    DateTime Function()? clock,
  })  : _preferences = preferences,
        _source = source ?? PlatformDeepLinkSource(),
        _links = links ?? BookLinks.current,
        _clock = clock ?? DateTime.now;

  static const String _referrerCheckedKey = 'deeplink.referrerChecked';
  static const String _referrerAttemptsKey = 'deeplink.referrerAttempts';
  static const String _pendingKey = 'deeplink.pending';
  static const int _maxReferrerAttempts = 3;
  static const Duration _pendingLifetime = Duration(days: 1);
  static const Duration _duplicateWindow = Duration(seconds: 3);

  final LocalPreferences _preferences;
  final DeepLinkSource _source;
  final BookLinks _links;
  final DateTime Function() _clock;

  late final DeepLinkRouteObserver observer =
      DeepLinkRouteObserver(onChanged: _flush);

  GlobalKey<NavigatorState>? _navigatorKey;
  StreamSubscription<String>? _subscription;
  bool _started = false;
  bool _disposed = false;

  String? _pendingBookId;
  bool _pendingPersisted = false;
  String? _lastDeliveredId;
  DateTime? _lastDeliveredAt;

  @visibleForTesting
  String? get pendingBookId => _pendingBookId;

  /// Starts listening. Safe to call more than once; only the first call runs.
  Future<void> start(GlobalKey<NavigatorState> navigatorKey) async {
    if (_started || _disposed) return;
    _started = true;
    _navigatorKey = navigatorKey;
    if (!_links.isConfigured) return;

    _subscription = _source.links.listen(_onLink);

    final String? initial = await _source.initialLink();
    if (_disposed) return;
    final String? initialId = initial == null ? null : _links.parseLink(initial);
    if (initialId != null) {
      _setPending(initialId);
      await _clearPersistedPending();
      await _markReferrerChecked();
      _flush();
      return;
    }

    final String? restored = await _restorePersistedPending();
    if (_disposed) return;
    if (restored != null && _pendingBookId == null) {
      _pendingBookId = restored;
      _pendingPersisted = true;
    }

    if (_pendingBookId == null) await _checkInstallReferrer();
    _flush();
  }

  void dispose() {
    _disposed = true;
    _subscription?.cancel();
    _source.dispose();
  }

  void _onLink(String raw) {
    final String? id = _links.parseLink(raw);
    if (id == null) return;
    _setPending(id);
    _flush();
  }

  void _setPending(String id) {
    if (_pendingPersisted) {
      _pendingPersisted = false;
      _clearPersistedPending();
    }
    _pendingBookId = id;
  }

  Future<void> _checkInstallReferrer() async {
    if (await _preferences.read(_referrerCheckedKey) == 'true') return;
    final int attempts =
        int.tryParse(await _preferences.read(_referrerAttemptsKey) ?? '') ?? 0;
    if (attempts >= _maxReferrerAttempts) {
      await _markReferrerChecked();
      return;
    }
    await _preferences.write(_referrerAttemptsKey, '${attempts + 1}');
    final InstallReferrerResult result = await _source.installReferrer();
    if (_disposed) return;
    if (result.status == InstallReferrerStatus.unavailable) return;
    await _markReferrerChecked();
    final String? id = result.status == InstallReferrerStatus.ok
        ? _links.parseInstallReferrer(result.referrer ?? '')
        : null;
    if (id == null || _pendingBookId != null) return;
    _pendingBookId = id;
    _pendingPersisted = true;
    await _preferences.write(
      _pendingKey,
      jsonEncode(<String, Object>{
        'bookId': id,
        'at': _clock().millisecondsSinceEpoch,
      }),
    );
  }

  Future<void> _markReferrerChecked() async {
    await _preferences.write(_referrerCheckedKey, 'true');
    await _preferences.remove(_referrerAttemptsKey);
  }

  Future<String?> _restorePersistedPending() async {
    final String? raw = await _preferences.read(_pendingKey);
    if (raw == null) return null;
    try {
      final Object? decoded = jsonDecode(raw);
      if (decoded is Map) {
        final Object? id = decoded['bookId'];
        final Object? at = decoded['at'];
        if (id is String && at is int && BookLinks.isValidBookId(id)) {
          final DateTime stored = DateTime.fromMillisecondsSinceEpoch(at);
          final Duration age = _clock().difference(stored);
          if (!age.isNegative && age < _pendingLifetime) return id;
        }
      }
    } on FormatException {
      // Fall through and drop the unreadable value.
    }
    await _clearPersistedPending();
    return null;
  }

  Future<void> _clearPersistedPending() => _preferences.remove(_pendingKey);

  void _flush() {
    final String? id = _pendingBookId;
    final NavigatorState? navigator = _navigatorKey?.currentState;
    if (_disposed || id == null || navigator == null || !observer.isReady) {
      return;
    }
    _pendingBookId = null;
    if (_pendingPersisted) {
      _pendingPersisted = false;
      _clearPersistedPending();
    }
    final DateTime now = _clock();
    final bool repeated = _lastDeliveredId == id &&
        _lastDeliveredAt != null &&
        now.difference(_lastDeliveredAt!) < _duplicateWindow;
    if (repeated || observer.topBookId == id) return;
    _lastDeliveredId = id;
    _lastDeliveredAt = now;
    navigator.pushNamed(
      AppRoutes.bookDetails,
      arguments: BookDetailsArgs(bookId: id),
    );
  }
}

/// Follows the root navigator so links wait for the right moment.
class DeepLinkRouteObserver extends NavigatorObserver {
  DeepLinkRouteObserver({required this.onChanged});

  final VoidCallback onChanged;
  final List<Route<dynamic>> _stack = <Route<dynamic>>[];
  bool _reachedHome = false;

  Route<dynamic>? get _top => _stack.isEmpty ? null : _stack.last;

  bool get isReady {
    final Route<dynamic>? top = _top;
    if (!_reachedHome || top == null || top is PopupRoute) return false;
    final String? name = top.settings.name;
    return name != AppRoutes.splash && name != AppRoutes.login;
  }

  String? get topBookId {
    final Route<dynamic>? top = _top;
    if (top == null || top.settings.name != AppRoutes.bookDetails) return null;
    final Object? args = top.settings.arguments;
    if (args is BookDetailsArgs) return args.bookId;
    return args is String ? args : null;
  }

  void _changed() {
    if (_stack.any((Route<dynamic> r) => r.settings.name == AppRoutes.home)) {
      _reachedHome = true;
    }
    // Navigator callbacks run mid-transition; act once it has settled.
    scheduleMicrotask(onChanged);
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.add(route);
    _changed();
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _changed();
  }

  @override
  void didRemove(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _stack.remove(route);
    _changed();
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    final int index = oldRoute == null ? -1 : _stack.indexOf(oldRoute);
    if (newRoute != null) {
      if (index >= 0) {
        _stack[index] = newRoute;
      } else {
        _stack.add(newRoute);
      }
    } else if (index >= 0) {
      _stack.removeAt(index);
    }
    _changed();
  }
}

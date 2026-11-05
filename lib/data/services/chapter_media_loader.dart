import 'dart:collection';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';

import '../../core/network/api_client.dart';

/// In-memory loader for entitlement-protected chapter images.
///
/// Fetches `GET /media/:id` with the existing Bearer flow. Bytes are kept
/// only in process memory (no disk cache) and are cleared on logout or
/// account change so a later user cannot see a previous account's images.
class ChapterMediaLoader {
  ChapterMediaLoader(this._client);

  final ApiClient _client;

  /// Soft cap on retained decoded-ready byte payloads.
  static const int maxEntries = 48;
  static const int maxBytes = 24 * 1024 * 1024;

  final LinkedHashMap<String, Uint8List> _memory =
      LinkedHashMap<String, Uint8List>();
  final Map<String, Future<Uint8List>> _inFlight =
      <String, Future<Uint8List>>{};
  int _byteTotal = 0;
  String? _userScope;

  /// Bind the cache to the signed-in user id (or `null` for guest).
  void bindUser(String? userId) {
    if (_userScope == userId) return;
    clear();
    _userScope = userId;
  }

  void clear() {
    _memory.clear();
    _inFlight.clear();
    _byteTotal = 0;
    // Drop any decoded frames that belonged to the previous session.
    // Guard for unit tests that never start a Widgets binding.
    try {
      PaintingBinding.instance.imageCache.clear();
      PaintingBinding.instance.imageCache.clearLiveImages();
    } catch (_) {
      // Binding not initialized (pure unit test).
    }
  }

  /// Loads bytes for [mediaId] via the configured API base (never via a
  /// caller-supplied host). Optional auth matches chapter content access.
  Future<Uint8List> load(String mediaId) {
    final Uint8List? cached = _memory[mediaId];
    if (cached != null) {
      // LRU touch.
      _memory.remove(mediaId);
      _memory[mediaId] = cached;
      return SynchronousFuture<Uint8List>(cached);
    }
    return _inFlight.putIfAbsent(mediaId, () async {
      try {
        final Uint8List bytes = await _client.getMediaBytes(
          '/media/$mediaId',
          auth: AuthMode.optional,
        );
        _store(mediaId, bytes);
        return bytes;
      } finally {
        _inFlight.remove(mediaId);
      }
    });
  }

  void _store(String mediaId, Uint8List bytes) {
    // Do not retain huge single frames; still return them to the caller.
    if (bytes.lengthInBytes > 4 * 1024 * 1024) return;
    while ((_memory.length >= maxEntries ||
            _byteTotal + bytes.lengthInBytes > maxBytes) &&
        _memory.isNotEmpty) {
      final String oldest = _memory.keys.first;
      final Uint8List? removed = _memory.remove(oldest);
      if (removed != null) _byteTotal -= removed.lengthInBytes;
    }
    _memory[mediaId] = bytes;
    _byteTotal += bytes.lengthInBytes;
  }
}

/// Image provider that loads a chapter media id through [ChapterMediaLoader].
class AuthenticatedMediaImageProvider
    extends ImageProvider<AuthenticatedMediaImageProvider> {
  const AuthenticatedMediaImageProvider({
    required this.mediaId,
    required this.loader,
  });

  final String mediaId;
  final ChapterMediaLoader loader;

  @override
  Future<AuthenticatedMediaImageProvider> obtainKey(
    ImageConfiguration configuration,
  ) {
    return SynchronousFuture<AuthenticatedMediaImageProvider>(this);
  }

  @override
  ImageStreamCompleter loadImage(
    AuthenticatedMediaImageProvider key,
    ImageDecoderCallback decode,
  ) {
    return MultiFrameImageStreamCompleter(
      codec: _load(decode),
      scale: 1,
      debugLabel: 'AuthenticatedMediaImageProvider($mediaId)',
      informationCollector: () => <DiagnosticsNode>[
        DiagnosticsProperty<String>('mediaId', mediaId),
      ],
    );
  }

  Future<ui.Codec> _load(ImageDecoderCallback decode) async {
    final Uint8List bytes = await loader.load(mediaId);
    final ui.ImmutableBuffer buffer =
        await ui.ImmutableBuffer.fromUint8List(bytes);
    return decode(buffer);
  }

  @override
  bool operator ==(Object other) {
    return other is AuthenticatedMediaImageProvider &&
        other.mediaId == mediaId &&
        other.loader == loader;
  }

  @override
  int get hashCode => Object.hash(mediaId, loader);
}

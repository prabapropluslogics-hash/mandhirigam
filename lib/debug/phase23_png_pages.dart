import 'phase23_png_catalog.dart';

/// Owns decoded page values for the PNG debug reader.
///
/// One in-flight decode per page. A finished decode is published only for
/// the ticket that started it, and only while that page is still wanted.
/// The store, not the page widget, releases values that leave the cache.
class Phase23LoadCoordinator<T> {
  Phase23LoadCoordinator({
    required this.decode,
    required this.release,
    this.onChanged,
    this.maxReady = 5,
  });

  final Future<T> Function(int page) decode;
  final void Function(T value) release;
  final void Function()? onChanged;
  final int maxReady;

  final Map<int, T> _ready = <int, T>{};
  final Map<int, Future<void>> _inflight = <int, Future<void>>{};
  final Map<int, int> _tickets = <int, int>{};
  final Map<int, int> _pins = <int, int>{};
  final Map<int, Object> _errors = <int, Object>{};
  int visible = 1;
  bool _closed = false;
  bool _notifyScheduled = false;

  int get decodedCount => _ready.length;

  /// Decoded pages plus a decode that has not finished yet.
  int get cachedCount => _ready.length + _inflight.length;

  T? readyFor(int page) => _ready[page];

  Object? errorFor(int page) => _errors[page];

  void pin(int page) {
    if (_closed) return;
    _pins[page] = (_pins[page] ?? 0) + 1;
    if (_ready.containsKey(page) || _inflight.containsKey(page)) return;
    final int ticket = (_tickets[page] ?? 0) + 1;
    _tickets[page] = ticket;
    _errors.remove(page);
    _inflight[page] = _load(page, ticket);
  }

  void unpin(int page) {
    if (_closed) return;
    final int next = (_pins[page] ?? 1) - 1;
    if (next <= 0) {
      _pins.remove(page);
    } else {
      _pins[page] = next;
    }
    _evict();
  }

  void setVisible(int page) {
    visible = page;
    _evict();
  }

  void close() {
    _closed = true;
    for (final int page in _tickets.keys.toList()) {
      _tickets[page] = (_tickets[page] ?? 0) + 1;
    }
    _inflight.clear();
    _pins.clear();
    final List<T> held = _ready.values.toList();
    _ready.clear();
    for (final T value in held) {
      release(value);
    }
  }

  Future<void> _load(int page, int ticket) async {
    try {
      final T value = await decode(page);
      if (_closed || _tickets[page] != ticket) {
        release(value);
        return;
      }
      final bool unwanted = (_pins[page] ?? 0) == 0;
      if (unwanted && _ready.length >= maxReady) {
        release(value);
        return;
      }
      final T? previous = _ready[page];
      _ready[page] = value;
      _errors.remove(page);
      if (previous != null) release(previous);
      _evict();
      _notify();
    } catch (error) {
      if (_closed || _tickets[page] != ticket) return;
      _errors[page] = error;
      _notify();
    } finally {
      if (_tickets[page] == ticket) {
        _inflight.remove(page);
      }
    }
  }

  void _evict() {
    var removed = false;
    while (_ready.length > maxReady) {
      int? victim;
      var farthest = -1;
      for (final int page in _ready.keys) {
        if ((_pins[page] ?? 0) > 0) continue;
        final int distance = (page - visible).abs();
        if (distance > farthest) {
          farthest = distance;
          victim = page;
        }
      }
      if (victim == null) return;
      final T? value = _ready.remove(victim);
      if (value != null) release(value);
      removed = true;
    }
    if (removed) _notify();
  }

  void _notify() {
    if (_closed || _notifyScheduled) return;
    _notifyScheduled = true;
    Future<void>.microtask(() {
      _notifyScheduled = false;
      if (!_closed) onChanged?.call();
    });
  }
}

/// A page widget may paint a decoded image only for its own page number.
bool phase23ImageBelongsToPage({
  required int imagePage,
  required int widgetPage,
  required String imageFingerprint,
  required String widgetFingerprint,
  required bool closed,
}) {
  return !closed &&
      imagePage == widgetPage &&
      imageFingerprint == widgetFingerprint &&
      imageFingerprint == Phase23Pages.fingerprint;
}

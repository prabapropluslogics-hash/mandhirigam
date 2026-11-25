import 'dart:typed_data';

/// pdfrx 1.0.84 caches a PDF in memory only when it is at most this size.
/// Larger files use the async custom reader. See `PdfDocumentFactoryImpl.openCustom`.
const int kPdfrxDefaultMemoryCacheBytes = 1024 * 1024;

/// The Phase 2 PDF is larger than [kPdfrxDefaultMemoryCacheBytes], so
/// [PdfDocument.openData] would read it during every render.
bool phase21PdfExceedsMemoryCache(int byteLength) =>
    byteLength > kPdfrxDefaultMemoryCacheBytes;

/// Serializes one debug document's render and decode work.
///
/// pdfrx already runs PDFium calls on a single worker isolate. This gate
/// additionally keeps the Dart half of a render — pixel copy and
/// `decodeImageFromPixels` — from overlapping the next page. It does not
/// replace that worker.
class Phase21RenderGate {
  Future<void> _tail = Future<void>.value();
  int _active = 0;
  int _peak = 0;
  int _nextRequestId = 0;

  /// Jobs whose body is running now. Queued jobs are not counted.
  int get active => _active;

  /// Highest [active] value seen by this gate.
  int get peak => _peak;

  int nextRequestId() => ++_nextRequestId;

  Future<T> schedule<T>(Future<T> Function() job) {
    final Future<T> result = _tail.then((_) async {
      _active++;
      if (_active > _peak) _peak = _active;
      try {
        return await job();
      } finally {
        _active--;
      }
    });
    _tail = result.then((_) {}, onError: (Object _, StackTrace __) {});
    return result;
  }
}

/// A decoded bitmap may be shown only for the page and generation that
/// requested it. A later scroll, a new render, or disposal makes it stale.
bool phase21ResultIsCurrent({
  required int requestedPage,
  required int requestedGeneration,
  required int currentPage,
  required int currentGeneration,
  required bool closed,
}) {
  return !closed &&
      requestedPage == currentPage &&
      requestedGeneration == currentGeneration;
}

/// Document fingerprint and request id are part of the publish check.
/// A page-20 result cannot be stored as page 28, and document A cannot
/// satisfy document B.
bool phase21MayPublish({
  required String requestedDocument,
  required String currentDocument,
  required int requestedPage,
  required int currentPage,
  required int requestedGeneration,
  required int currentGeneration,
  required int requestedRequestId,
  required int currentRequestId,
  required bool closed,
}) {
  return requestedDocument == currentDocument &&
      requestedRequestId == currentRequestId &&
      phase21ResultIsCurrent(
        requestedPage: requestedPage,
        requestedGeneration: requestedGeneration,
        currentPage: currentPage,
        currentGeneration: currentGeneration,
        closed: closed,
      );
}

/// Copy a PDFium bitmap into Dart memory that later renders cannot mutate.
///
/// pdfrx exposes `PdfImage.pixels` as a view of the native allocation.
/// [width] and [height] must describe an 8-bit BGRA buffer with stride
/// `width * 4`, which is what pdfrx 1.0.84 requests from `FPDFBitmap_CreateEx`.
Uint8List phase21CopyPixels({
  required Uint8List source,
  required int width,
  required int height,
}) {
  final int expected = width * height * 4;
  if (width <= 0 || height <= 0 || source.length != expected) {
    throw StateError(
      'pixel buffer ${source.length} != $width x $height x 4',
    );
  }
  return Uint8List.fromList(source);
}

/// Stable FNV-1a hash for debug logs and tests. Not a security hash.
int phase21BufferHash(Uint8List bytes) {
  int hash = 0x811c9dc5;
  for (int i = 0; i < bytes.length; i++) {
    hash ^= bytes[i];
    hash = (hash * 0x01000193) & 0x7fffffff;
  }
  return hash;
}

/// Short identity for a loaded PDF. Does not hash the whole file.
String phase21DocumentFingerprint(Uint8List bytes) {
  final int head = bytes.isEmpty ? 0 : bytes[0];
  final int mid = bytes.isEmpty ? 0 : bytes[bytes.length ~/ 2];
  final int tail = bytes.isEmpty ? 0 : bytes[bytes.length - 1];
  return '$head-$mid-$tail-${bytes.length.toRadixString(16)}';
}

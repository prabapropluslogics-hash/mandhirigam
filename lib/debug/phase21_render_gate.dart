/// Serializes PDF page renders for the Phase 2.1 debug harness.
///
/// pdfrx 1.0.84 runs PDFium on one background isolate, but
/// [PdfPage.render] returns a buffer that [PdfImage.createImage] reads
/// asynchronously. The production viewer wraps that pair in a lock.
/// This gate is the same idea for the debug list: one page finishes
/// decode before the next render starts.
class Phase21RenderGate {
  Future<void> _tail = Future<void>.value();

  Future<T> schedule<T>(Future<T> Function() job) {
    final Future<T> result = _tail.then((_) => job());
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

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:maanthirigam/debug/phase21_render_gate.dart';

void main() {
  test('memory-cache cutoff matches the installed pdfrx 1.0.84 default', () {
    expect(kPdfrxDefaultMemoryCacheBytes, 1024 * 1024);
    expect(phase21PdfExceedsMemoryCache(1024 * 1024), isFalse);
    expect(phase21PdfExceedsMemoryCache(11735347), isTrue);
  });

  test('gate runs one job at a time and waits for the async body', () async {
    final Phase21RenderGate gate = Phase21RenderGate();
    final Completer<void> release = Completer<void>();
    final Completer<void> started = Completer<void>();
    final List<String> order = <String>[];

    final Future<void> first = gate.schedule(() async {
      started.complete();
      order.add('first-start');
      await release.future;
      order.add('first-end');
    });
    await started.future;
    expect(gate.active, 1);

    final Completer<void> secondStarted = Completer<void>();
    final Future<void> second = gate.schedule(() async {
      secondStarted.complete();
      order.add('second');
    });
    await Future<void>.delayed(Duration.zero);
    expect(secondStarted.isCompleted, isFalse);
    expect(gate.active, 1);

    release.complete();
    await first;
    await second;
    expect(order, <String>['first-start', 'first-end', 'second']);
    expect(gate.active, 0);
    expect(gate.peak, 1);
  });

  test('disposal is queued behind the in-flight render', () async {
    final Phase21RenderGate gate = Phase21RenderGate();
    final Completer<void> release = Completer<void>();
    final List<String> order = <String>[];

    final Future<void> render = gate.schedule(() async {
      order.add('render-start');
      await release.future;
      order.add('render-end');
    });
    final Future<void> dispose = gate.schedule(() async {
      order.add('dispose');
    });
    release.complete();
    await render;
    await dispose;
    expect(order, <String>['render-start', 'render-end', 'dispose']);
  });

  test('a cancelled generation can be rendered again', () async {
    final Phase21RenderGate gate = Phase21RenderGate();
    final Map<int, int> shown = <int, int>{};

    Future<void> publish({
      required int page,
      required int generation,
      required int currentGeneration,
      required int requestId,
      required int currentRequestId,
      required bool closed,
    }) async {
      await gate.schedule(() async {
        if (!phase21MayPublish(
          requestedDocument: 'doc-a',
          currentDocument: 'doc-a',
          requestedPage: page,
          currentPage: page,
          requestedGeneration: generation,
          currentGeneration: currentGeneration,
          requestedRequestId: requestId,
          currentRequestId: currentRequestId,
          closed: closed,
        )) {
          return;
        }
        shown[page] = generation;
      });
    }

    await publish(
      page: 7,
      generation: 1,
      currentGeneration: 2,
      requestId: 1,
      currentRequestId: 2,
      closed: false,
    );
    expect(shown.containsKey(7), isFalse);

    await publish(
      page: 7,
      generation: 2,
      currentGeneration: 2,
      requestId: 2,
      currentRequestId: 2,
      closed: false,
    );
    expect(shown[7], 2);
  });

  test('stale generation, document, and page identities are rejected', () {
    expect(
      phase21MayPublish(
        requestedDocument: 'doc-a',
        currentDocument: 'doc-a',
        requestedPage: 4,
        currentPage: 4,
        requestedGeneration: 1,
        currentGeneration: 2,
        requestedRequestId: 1,
        currentRequestId: 1,
        closed: false,
      ),
      isFalse,
    );
    expect(
      phase21MayPublish(
        requestedDocument: 'doc-a',
        currentDocument: 'doc-b',
        requestedPage: 4,
        currentPage: 4,
        requestedGeneration: 3,
        currentGeneration: 3,
        requestedRequestId: 9,
        currentRequestId: 9,
        closed: false,
      ),
      isFalse,
    );
    expect(
      phase21MayPublish(
        requestedDocument: 'doc-a',
        currentDocument: 'doc-a',
        requestedPage: 20,
        currentPage: 28,
        requestedGeneration: 1,
        currentGeneration: 1,
        requestedRequestId: 4,
        currentRequestId: 4,
        closed: false,
      ),
      isFalse,
    );
    expect(
      phase21MayPublish(
        requestedDocument: 'doc-a',
        currentDocument: 'doc-a',
        requestedPage: 1,
        currentPage: 1,
        requestedGeneration: 2,
        currentGeneration: 2,
        requestedRequestId: 8,
        currentRequestId: 9,
        closed: false,
      ),
      isFalse,
    );
    expect(
      phase21MayPublish(
        requestedDocument: 'doc-a',
        currentDocument: 'doc-a',
        requestedPage: 1,
        currentPage: 1,
        requestedGeneration: 2,
        currentGeneration: 2,
        requestedRequestId: 8,
        currentRequestId: 8,
        closed: true,
      ),
      isFalse,
    );
  });

  test('random navigation cannot reuse another page image', () {
    final Map<int, int> images = <int, int>{};

    bool assign({
      required int requestedPage,
      required int currentPage,
      required int hash,
    }) {
      if (!phase21MayPublish(
        requestedDocument: 'doc-a',
        currentDocument: 'doc-a',
        requestedPage: requestedPage,
        currentPage: currentPage,
        requestedGeneration: 1,
        currentGeneration: 1,
        requestedRequestId: requestedPage,
        currentRequestId: currentPage,
        closed: false,
      )) {
        return false;
      }
      images[currentPage] = hash;
      return true;
    }

    expect(assign(requestedPage: 20, currentPage: 20, hash: 200), isTrue);
    expect(assign(requestedPage: 20, currentPage: 28, hash: 200), isFalse);
    expect(images[20], 200);
    expect(images.containsKey(28), isFalse);
    expect(assign(requestedPage: 1, currentPage: 1, hash: 10), isTrue);
    expect(images[1], 10);
    expect(images[20], 200);
  });

  test('a later render cannot mutate an earlier owned buffer', () {
    final Uint8List native = Uint8List.fromList(<int>[10, 20, 30, 40]);
    final Uint8List owned = phase21CopyPixels(
      source: native,
      width: 1,
      height: 1,
    );
    final int before = phase21BufferHash(owned);
    native[0] = 255;
    native[3] = 1;
    expect(owned, <int>[10, 20, 30, 40]);
    expect(phase21BufferHash(owned), before);
    expect(
      () => phase21CopyPixels(
        source: Uint8List(3),
        width: 1,
        height: 1,
      ),
      throwsStateError,
    );
  });

  test('document fingerprints differ by length and sample bytes', () {
    final String a =
        phase21DocumentFingerprint(Uint8List.fromList(<int>[1, 2, 3]));
    final String b =
        phase21DocumentFingerprint(Uint8List.fromList(<int>[1, 9, 3]));
    final String c = phase21DocumentFingerprint(
      Uint8List.fromList(<int>[1, 2, 3, 4]),
    );
    expect(a, isNot(b));
    expect(a, isNot(c));
  });
}

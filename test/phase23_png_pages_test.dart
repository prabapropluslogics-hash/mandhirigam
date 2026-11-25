import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maanthirigam/debug/phase12_transparency_screen.dart';
import 'package:maanthirigam/debug/phase23_png_catalog.dart';
import 'package:maanthirigam/debug/phase23_png_pages.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('catalog lists the 33 packed page assets in order', () {
    expect(Phase23Pages.files, hasLength(33));
    expect(Phase23Pages.pageCount, 33);
    expect(Phase23Pages.width, 1241);
    expect(Phase23Pages.height, 1754);
    var bytes = 0;
    for (var page = 1; page <= 33; page++) {
      final Phase23PageFile file = Phase23Pages.fileFor(page);
      expect(file.page, page);
      expect(file.sha256, hasLength(64));
      bytes += file.bytes;
      expect(
        Phase23Pages.assetFor(page),
        'assets/debug/phase2_png/page_${page.toString().padLeft(2, '0')}.png',
      );
    }
    expect(bytes, Phase23Pages.totalBytes);
    expect(Phase23Pages.totalBytes, 11911325);
  });

  test('copied assets match the catalog SHA-256 and byte size', () async {
    for (final Phase23PageFile file in Phase23Pages.files) {
      final File image = File(Phase23Pages.assetFor(file.page));
      expect(image.existsSync(), isTrue, reason: image.path);
      expect(image.lengthSync(), file.bytes);
      final ProcessResult hash = await Process.run('shasum', <String>[
        '-a',
        '256',
        image.path,
      ]);
      expect(hash.exitCode, 0);
      expect((hash.stdout as String).split(' ').first, file.sha256);
    }
  });

  test('one page decode is shared and a late result cannot change pages',
      () async {
    final Map<int, Completer<String>> gates = <int, Completer<String>>{};
    final List<String> released = <String>[];
    final Phase23LoadCoordinator<String> store = Phase23LoadCoordinator<String>(
      maxReady: 2,
      decode: (int page) {
        final Completer<String> gate = Completer<String>();
        gates[page] = gate;
        return gate.future;
      },
      release: released.add,
    );

    store.pin(20);
    store.pin(20);
    expect(gates, hasLength(1));

    gates[20]!.complete('page-20');
    await Future<void>.delayed(Duration.zero);

    expect(store.readyFor(20), 'page-20');
    expect(store.readyFor(28), isNull);
    expect(store.decodedCount, 1);
    expect(released, isEmpty);

    store.close();
    expect(store.readyFor(20), isNull);
    expect(released, <String>['page-20']);
  });

  test('a decode that finishes after close is released and not published',
      () async {
    final Completer<String> gate = Completer<String>();
    final List<String> released = <String>[];
    final Phase23LoadCoordinator<String> store = Phase23LoadCoordinator<String>(
      decode: (_) => gate.future,
      release: released.add,
    );

    store.pin(7);
    store.close();
    gate.complete('page-7');
    await Future<void>.delayed(Duration.zero);

    expect(store.readyFor(7), isNull);
    expect(store.decodedCount, 0);
    expect(released, <String>['page-7']);
  });

  test('eviction releases the farthest unpinned page and keeps pinned pages',
      () async {
    final List<String> released = <String>[];
    final Phase23LoadCoordinator<String> store = Phase23LoadCoordinator<String>(
      maxReady: 2,
      decode: (int page) async => 'page-$page',
      release: released.add,
    );

    store.pin(1);
    store.pin(2);
    store.pin(3);
    await Future<void>.delayed(Duration.zero);
    expect(store.decodedCount, 3);

    store.setVisible(1);
    store.unpin(3);
    expect(store.readyFor(1), 'page-1');
    expect(store.readyFor(2), 'page-2');
    expect(store.readyFor(3), isNull);
    expect(released, <String>['page-3']);
    expect(store.cachedCount, 2);
  });

  test('page identity rejects another page or another document', () {
    expect(
      phase23ImageBelongsToPage(
        imagePage: 20,
        widgetPage: 28,
        imageFingerprint: Phase23Pages.fingerprint,
        widgetFingerprint: Phase23Pages.fingerprint,
        closed: false,
      ),
      isFalse,
    );
    expect(
      phase23ImageBelongsToPage(
        imagePage: 7,
        widgetPage: 7,
        imageFingerprint: 'other',
        widgetFingerprint: Phase23Pages.fingerprint,
        closed: false,
      ),
      isFalse,
    );
    expect(
      phase23ImageBelongsToPage(
        imagePage: 7,
        widgetPage: 7,
        imageFingerprint: Phase23Pages.fingerprint,
        widgetFingerprint: Phase23Pages.fingerprint,
        closed: false,
      ),
      isTrue,
    );
  });

  testWidgets('debug screen states PNG mode and keeps the static control',
      (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Phase12TransparencyScreen()),
    );
    await tester.pump();

    expect(
      find.textContaining('PNG IMAGE MODE — PDFium disabled — 33 pages'),
      findsOneWidget,
    );
    expect(find.textContaining('decoded='), findsOneWidget);
    expect(find.textContaining('cached='), findsOneWidget);
    expect(find.textContaining('11911325 bytes'), findsOneWidget);
    expect(find.text('Static control — not from PDFium'), findsOneWidget);
    expect(find.text('Original page 1'), findsOneWidget);
  });
}

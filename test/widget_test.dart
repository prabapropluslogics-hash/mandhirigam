import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maanthirigam/app/maanthirigam_app.dart';
import 'package:maanthirigam/shared/data/mock_catalog.dart';

void main() {
  testWidgets('home discover screen renders greeting and featured book', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaanthirigamApp());
    await tester.pumpAndSettle();

    expect(find.text(MockCatalog.greeting), findsOneWidget);
    expect(find.text(MockCatalog.currentUserName), findsOneWidget);
    expect(find.text('Letters from an Amber Sea'), findsWidgets);
  });

  testWidgets('search tab and book details navigation', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(const MaanthirigamApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();

    expect(find.text('winter'), findsWidgets);
    expect(find.text('128 results'), findsOneWidget);

    await tester.tap(find.text("Winter's Almanac").last);
    await tester.pumpAndSettle();

    expect(find.text('Unlock premium'), findsOneWidget);
    expect(find.text('Free sample'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Unlock premium'), findsNothing);
    expect(find.text("Winter's Almanac"), findsWidgets);
  });
}

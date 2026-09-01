import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maanthirigam/app/maanthirigam_app.dart';
import 'package:maanthirigam/shared/data/mock_catalog.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const MaanthirigamApp());
    await tester.pumpAndSettle();
  }

  testWidgets('home discover screen renders greeting and featured book', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(find.text(MockCatalog.greeting), findsOneWidget);
    expect(find.text(MockCatalog.currentUserName), findsOneWidget);
    expect(find.text('Letters from an Amber Sea'), findsWidgets);
  });

  testWidgets('search tab and book details navigation', (tester) async {
    await pumpApp(tester);

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

  testWidgets('library and profile tabs render reference content', (
    tester,
  ) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Library'));
    await tester.pumpAndSettle();
    expect(find.text('My library'), findsOneWidget);
    expect(find.text('Continue reading'), findsWidgets);
    expect(find.text('7-day reading streak'), findsOneWidget);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Premium member'), findsOneWidget);
    expect(find.text('Books read'), findsOneWidget);
    expect(find.text('This week'), findsOneWidget);
    expect(find.text('Sign out'), findsOneWidget);
  });

  testWidgets('unlock premium opens plans and payment', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    await tester.tap(find.text("Winter's Almanac").last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Unlock premium'));
    await tester.pumpAndSettle();
    expect(find.text('Unlock every story'), findsOneWidget);
    expect(find.text('BEST VALUE'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Payment'), findsOneWidget);
    expect(find.text('Total due today'), findsOneWidget);
    expect(find.textContaining('Confirm & pay'), findsOneWidget);
  });

  testWidgets('start reading opens the reader', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.text('The Quiet Hours').first);
    await tester.pumpAndSettle();
    expect(find.text('Start reading'), findsOneWidget);

    await tester.tap(find.text('Start reading'));
    await tester.pumpAndSettle();
    expect(find.text('The Amber Room'), findsOneWidget);
    expect(find.text('CHAPTER 12'), findsOneWidget);
  });
}

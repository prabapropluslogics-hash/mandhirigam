import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:maanthirigam/app/maanthirigam_app.dart';
import 'package:maanthirigam/core/app_container.dart';

import 'support/scripted_http.dart';
import 'support/test_container.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  AppContainer buildApp() {
    final ScriptedHttpClient client = ScriptedHttpClient(<String, http.Response>{
      'GET /api/v1/app-config': jsonOk(sampleAppConfig),
      'GET /api/v1/announcements': jsonOk(sampleAnnouncements),
      'GET /api/v1/books': jsonOk(sampleBooks),
      'GET /api/v1/books/aaaaaaaaaaaaaaaaaaaaaaaa': jsonOk('''
        {"success":true,"data":{
          "id":"aaaaaaaaaaaaaaaaaaaaaaaa",
          "title":"Tirukkural Wisdom",
          "description":"A free introduction to the text.",
          "author":"Thiruvalluvar",
          "language":"ta",
          "accessType":"FREE",
          "price":0,
          "currency":"INR",
          "status":"PUBLISHED"
        }}
      '''),
      'GET /api/v1/books/aaaaaaaaaaaaaaaaaaaaaaaa/chapters': jsonOk('''
        {"success":true,"data":[{"id":"ch1","bookId":"aaaaaaaaaaaaaaaaaaaaaaaa","chapterNumber":1,"title":"Opening","contentFormat":"RICH_TEXT","status":"PUBLISHED"}]}
      '''),
      'GET /api/v1/books/bbbbbbbbbbbbbbbbbbbbbbbb': jsonOk('''
        {"success":true,"data":{
          "id":"bbbbbbbbbbbbbbbbbbbbbbbb",
          "title":"Inner Fire",
          "description":"A paid commentary.",
          "author":"Mantirigam",
          "language":"en",
          "accessType":"PAID",
          "price":29900,
          "currency":"INR",
          "status":"PUBLISHED"
        }}
      '''),
      'GET /api/v1/books/bbbbbbbbbbbbbbbbbbbbbbbb/chapters': jsonOk('''
        {"success":true,"data":[{"id":"chp","bookId":"bbbbbbbbbbbbbbbbbbbbbbbb","chapterNumber":1,"title":"Ember","contentFormat":"RICH_TEXT","status":"PUBLISHED"}]}
      '''),
    });
    return testContainer(httpClient: client);
  }

  testWidgets('launch, home, catalogue, book details, library and login', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(MaanthirigamApp(container: buildApp()));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();

    expect(find.text('Mantirigam'), findsWidgets);
    expect(find.text('Tirukkural Wisdom'), findsWidgets);
    expect(find.text('Welcome'), findsWidgets);
    expect(find.text('A new season of reading.'), findsOneWidget);

    await tester.tap(find.byTooltip('Search'));
    await tester.pumpAndSettle();
    expect(find.text('Inner Fire'), findsWidgets);
    expect(find.text('₹299'), findsWidgets);

    await tester.tap(find.text('Tirukkural Wisdom').first);
    await tester.pumpAndSettle();
    expect(find.text('Read now'), findsOneWidget);
    expect(find.text('Opening'), findsOneWidget);

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Library'));
    await tester.pumpAndSettle();
    expect(find.text('Sign in to see your library'), findsOneWidget);

    await tester.tap(find.byTooltip('Profile'));
    await tester.pumpAndSettle();
    expect(find.text('Browsing as guest'), findsOneWidget);
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}

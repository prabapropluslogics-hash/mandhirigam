import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:maanthirigam/features/book_details/presentation/screens/book_details_screen.dart';
import 'package:maanthirigam/routing/app_routes.dart';
import 'package:maanthirigam/services/book_link.dart';
import 'package:maanthirigam/services/deep_link_service.dart';
import 'package:maanthirigam/services/local_preferences.dart';
import 'package:maanthirigam/services/share_service.dart';

const String _api = 'https://api.example.org/api/v1';
const String _id = '665f1c2ab4d9e81234567890';

BookLinks _links([String base = 'https://books.example.com']) =>
    BookLinks.fromConfig(shareBaseUrl: base, apiBaseUrl: _api);

class _FakeSource implements DeepLinkSource {
  _FakeSource({this.initial, this.referrer});

  String? initial;
  InstallReferrerResult? referrer;
  int referrerCalls = 0;
  final StreamController<String> controller =
      StreamController<String>.broadcast();

  @override
  Future<String?> initialLink() async {
    final String? link = initial;
    initial = null;
    return link;
  }

  @override
  Stream<String> get links => controller.stream;

  @override
  Future<InstallReferrerResult> installReferrer() async {
    referrerCalls++;
    return referrer ??
        const InstallReferrerResult(InstallReferrerStatus.ok, '');
  }

  @override
  void dispose() => controller.close();
}

void main() {
  group('BookLinks', () {
    test('builds the canonical book URL', () {
      expect(
        _links().bookUri(_id).toString(),
        'https://books.example.com/book/$_id',
      );
      expect(
        _links('https://example.com/app/').bookUri(_id).toString(),
        'https://example.com/app/book/$_id',
      );
    });

    test('is not configured for unsafe or missing origins', () {
      for (final String base in <String>[
        '',
        'http://books.example.com',
        'https://localhost',
        'https://10.0.2.2:5050',
        'https://127.0.0.1',
        'https://api.example.org',
        'https://books.example.com?x=1',
      ]) {
        expect(_links(base).isConfigured, isFalse, reason: base);
        expect(_links(base).bookUri(_id), isNull, reason: base);
      }
    });

    test('accepts only /book/<id> on the configured host', () {
      final BookLinks links = _links();
      expect(links.parseLink('https://books.example.com/book/$_id'), _id);
      expect(links.parseLink('https://BOOKS.example.com/book/$_id/'), _id);
      expect(
        links.parseLink('https://books.example.com/book/$_id?utm=share'),
        _id,
      );
      for (final String bad in <String>[
        'http://books.example.com/book/$_id',
        'https://evil.example.net/book/$_id',
        'https://books.example.com/payment/$_id',
        'https://books.example.com/book/$_id/read',
        'https://books.example.com/book/',
        'https://books.example.com/book/..%2Fadmin',
        'https://books.example.com/book/<script>',
        'not a url',
      ]) {
        expect(links.parseLink(bad), isNull, reason: bad);
      }
    });

    test('reads the book id from a Play install referrer', () {
      final BookLinks links = _links();
      expect(links.parseInstallReferrer('book_id=$_id&utm_source=share'), _id);
      expect(
        links.parseInstallReferrer(
          'deep_link=${Uri.encodeComponent('https://books.example.com/book/$_id')}',
        ),
        _id,
      );
      expect(
        links.parseInstallReferrer(
          'utm_source=google-play&utm_medium=organic',
        ),
        isNull,
      );
      expect(links.parseInstallReferrer('book_id=../../admin'), isNull);
    });
  });

  test('share message uses the title and the public URL', () {
    final Uri url = _links().bookUri(_id)!;
    expect(
      ShareService.bookMessage('Inner Fire', url),
      'Read "Inner Fire" on Maanthirigam.\n\n'
      'https://books.example.com/book/$_id',
    );
  });

  group('DeepLinkService', () {
    late GlobalKey<NavigatorState> navigatorKey;
    late List<String> opened;

    setUp(() {
      FlutterSecureStorage.setMockInitialValues(<String, String>{});
      navigatorKey = GlobalKey<NavigatorState>();
      opened = <String>[];
    });

    DeepLinkService service(_FakeSource source) => DeepLinkService(
          preferences: LocalPreferences(storage: const FlutterSecureStorage()),
          source: source,
          links: _links(),
        );

    Future<void> pumpApp(WidgetTester tester, DeepLinkService links) {
      return tester.pumpWidget(
        MaterialApp(
          navigatorKey: navigatorKey,
          navigatorObservers: <NavigatorObserver>[links.observer],
          initialRoute: AppRoutes.splash,
          onGenerateRoute: (RouteSettings settings) {
            if (settings.name == AppRoutes.bookDetails) {
              final BookDetailsArgs args =
                  settings.arguments! as BookDetailsArgs;
              opened.add(args.bookId);
              return MaterialPageRoute<void>(
                settings: settings,
                builder: (_) => Text('book ${args.bookId}'),
              );
            }
            return MaterialPageRoute<void>(
              settings: settings,
              builder: (_) => Text('route ${settings.name}'),
            );
          },
        ),
      );
    }

    Future<void> finishSplash(WidgetTester tester) async {
      navigatorKey.currentState!.pushReplacementNamed(AppRoutes.home);
      await tester.pumpAndSettle();
    }

    testWidgets('a launch link waits for startup, then opens once',
        (WidgetTester tester) async {
      final _FakeSource source =
          _FakeSource(initial: 'https://books.example.com/book/$_id');
      final DeepLinkService links = service(source);
      await pumpApp(tester, links);
      await links.start(navigatorKey);
      await tester.pumpAndSettle();
      expect(opened, isEmpty);

      source.controller.add('https://books.example.com/book/$_id');
      await finishSplash(tester);
      expect(opened, <String>[_id]);
      expect(find.text('book $_id'), findsOneWidget);
      expect(source.referrerCalls, 0);
      links.dispose();
    });

    testWidgets('links while running open over the current screen',
        (WidgetTester tester) async {
      final _FakeSource source = _FakeSource();
      final DeepLinkService links = service(source);
      await pumpApp(tester, links);
      await links.start(navigatorKey);
      await finishSplash(tester);
      navigatorKey.currentState!.pushNamed(AppRoutes.reader);
      await tester.pumpAndSettle();

      source.controller.add('https://books.example.com/book/$_id');
      await tester.pumpAndSettle();
      expect(opened, <String>[_id]);

      source.controller.add('https://books.example.com/book/$_id');
      await tester.pumpAndSettle();
      expect(opened, <String>[_id]);

      source.controller.add('https://books.example.com/admin/users');
      source.controller.add('https://other.example.net/book/$_id');
      await tester.pumpAndSettle();
      expect(opened, <String>[_id]);
      links.dispose();
    });

    testWidgets('waits while the login screen is open',
        (WidgetTester tester) async {
      final _FakeSource source = _FakeSource();
      final DeepLinkService links = service(source);
      await pumpApp(tester, links);
      await links.start(navigatorKey);
      await finishSplash(tester);
      navigatorKey.currentState!.pushNamed(AppRoutes.login);
      await tester.pumpAndSettle();

      source.controller.add('https://books.example.com/book/$_id');
      await tester.pumpAndSettle();
      expect(opened, isEmpty);

      navigatorKey.currentState!.pop();
      await tester.pumpAndSettle();
      expect(opened, <String>[_id]);
      links.dispose();
    });

    testWidgets('install referrer routes once and never again',
        (WidgetTester tester) async {
      final _FakeSource first = _FakeSource(
        referrer: const InstallReferrerResult(
          InstallReferrerStatus.ok,
          'book_id=$_id&utm_source=share',
        ),
      );
      final DeepLinkService links = service(first);
      await pumpApp(tester, links);
      await links.start(navigatorKey);
      await finishSplash(tester);
      expect(opened, <String>[_id]);
      expect(first.referrerCalls, 1);
      links.dispose();

      opened.clear();
      navigatorKey = GlobalKey<NavigatorState>();
      final _FakeSource second = _FakeSource(referrer: first.referrer);
      final DeepLinkService relaunched = service(second);
      await pumpApp(tester, relaunched);
      await relaunched.start(navigatorKey);
      await finishSplash(tester);
      expect(opened, isEmpty);
      expect(second.referrerCalls, 0);
      relaunched.dispose();
    });
  });
}

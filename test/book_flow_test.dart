import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:maanthirigam/app/maanthirigam_app.dart';
import 'package:maanthirigam/core/app_container.dart';
import 'package:maanthirigam/core/storage/session_store.dart';
import 'package:maanthirigam/data/services/razorpay_checkout.dart';
import 'package:maanthirigam/design_system/components/navigation/app_tab_bar.dart';
import 'package:maanthirigam/features/book_details/presentation/screens/book_details_screen.dart';
import 'package:maanthirigam/features/reader/state/reader_preferences.dart';
import 'package:maanthirigam/routing/app_router.dart';
import 'package:maanthirigam/routing/app_routes.dart';

import 'support/scripted_http.dart';
import 'support/test_container.dart';

const String _freeId = 'aaaaaaaaaaaaaaaaaaaaaaaa';
const String _paidId = 'bbbbbbbbbbbbbbbbbbbbbbbb';
const List<String> _freeTitles = <String>[
  'Opening',
  'Second',
  'Third',
  'Fourth',
  'Fifth'
];

String _ok(String data) => '{"success":true,"data":$data}';

String _bookJson(String id, String title, {required bool paid}) => '''
{"id":"$id","title":"$title","description":"About $title.","author":"Author",
 "language":"en","accessType":"${paid ? 'PAID' : 'FREE'}","price":${paid ? 29900 : 0},
 "currency":"INR","status":"PUBLISHED"}''';

String _chapterJson(String bookId, String id, int number, String title,
    {bool content = false}) {
  final String body = content
      ? ',"content":{"version":1,"blocks":[{"id":"b$id","type":"paragraph","text":"Body of $title"}]}'
      : '';
  return '{"id":"$id","bookId":"$bookId","chapterNumber":$number,"title":"$title",'
      '"contentFormat":"RICH_TEXT","status":"PUBLISHED"$body}';
}

/// Scripted backend whose `/library` reflects verified purchases, like the
/// real entitlement store.
class _FakeBackend extends http.BaseClient {
  _FakeBackend({bool guestFreeReading = false}) {
    final Map<String, http.Response> routes = <String, http.Response>{
      'GET /api/v1/app-config': jsonOk(sampleAppConfig.replaceFirst(
        '"allowGuestFreeBookReading": true',
        '"allowGuestFreeBookReading": $guestFreeReading',
      )),
      'GET /api/v1/announcements': jsonOk(sampleAnnouncements),
      'GET /api/v1/books': jsonOk(sampleBooks),
      'POST /api/v1/auth/google': jsonOk(_ok(
        '{"accessToken":"backend-jwt","user":{"id":"u1","name":"Reader",'
        '"email":"reader@example.com","profileImageUrl":null}}',
      )),
      'GET /api/v1/books/$_freeId':
          jsonOk(_ok(_bookJson(_freeId, 'Tirukkural Wisdom', paid: false))),
      'GET /api/v1/books/$_paidId':
          jsonOk(_ok(_bookJson(_paidId, 'Inner Fire', paid: true))),
      'GET /api/v1/books/$_freeId/chapters': jsonOk(_ok('[${<String>[
        for (int i = 0; i < _freeTitles.length; i++)
          _chapterJson(_freeId, 'ch${i + 1}', i + 1, _freeTitles[i]),
      ].join(',')}]')),
      'GET /api/v1/books/$_paidId/chapters': jsonOk(_ok(
        '[${_chapterJson(_paidId, 'chp1', 1, 'Ember')},${_chapterJson(_paidId, 'chp2', 2, 'Flame')}]',
      )),
      'GET /api/v1/books/$_paidId/chapters/chp1':
          jsonOk(_ok(_chapterJson(_paidId, 'chp1', 1, 'Ember', content: true))),
      'POST /api/v1/payments/create-order': jsonOk(_ok(
        '{"orderId":"order_1","amount":29900,"currency":"INR","keyId":"rzp_test_key"}',
      )),
      'GET /api/v1/payments/order_1/status': jsonOk(_ok(
        '{"orderId":"order_1","status":"FAILED","purchaseStatus":"FAILED","entitled":false}',
      )),
    };
    for (int i = 0; i < _freeTitles.length; i++) {
      routes['GET /api/v1/books/$_freeId/chapters/ch${i + 1}'] = jsonOk(_ok(
          _chapterJson(_freeId, 'ch${i + 1}', i + 1, _freeTitles[i],
              content: true)));
    }
    _scripted = ScriptedHttpClient(routes);
  }

  late final ScriptedHttpClient _scripted;
  final Set<String> owned = <String>{};
  int verifyCalls = 0;

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    final String key = '${request.method} ${request.url.path}';
    if (key == 'GET /api/v1/library') {
      final String items = owned
          .map((String id) =>
              '{"bookId":"$id","title":"Inner Fire","language":"en",'
              '"accessType":"PAID","entitlementType":"LIFETIME",'
              '"grantedAt":"2026-01-01T00:00:00.000Z"}')
          .join(',');
      return _respond(
          request,
          '{"success":true,"data":[$items],'
          '"pagination":{"page":1,"limit":50,"total":${owned.length},"totalPages":1}}');
    }
    if (key == 'POST /api/v1/payments/verify') {
      verifyCalls += 1;
      owned.add(_paidId);
      return _respond(
          request,
          _ok(
            '{"orderId":"order_1","status":"CAPTURED","purchaseStatus":"SUCCESS","entitled":true}',
          ));
    }
    return _scripted.send(request);
  }

  http.StreamedResponse _respond(http.BaseRequest request, String body) {
    return http.StreamedResponse(
      Stream<List<int>>.value(utf8.encode(body)),
      200,
      headers: <String, String>{'content-type': 'application/json'},
      request: request,
    );
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _FakeBackend backend;
  late FakeGoogleAuth google;
  late FakeFirebaseAuth firebase;
  late FakeCheckout checkout;
  late AppContainer container;

  void setUpContainer() {
    backend = _FakeBackend();
    google = FakeGoogleAuth();
    firebase = FakeFirebaseAuth();
    checkout = FakeCheckout();
    container = testContainer(
      httpClient: backend,
      googleAuth: google,
      firebaseAuth: firebase,
      checkout: checkout,
    );
  }

  Future<void> launch(WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(MaanthirigamApp(container: container));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));
    await tester.pumpAndSettle();
  }

  Future<void> signInBeforeLaunch() async {
    await container.authController.restore();
    await container.authController.signInWithGoogle();
  }

  Future<void> openBook(WidgetTester tester, String bookId) async {
    AppRouter.navigatorKey.currentState!.pushNamed(
      AppRoutes.bookDetails,
      arguments: BookDetailsArgs(bookId: bookId),
    );
    await tester.pumpAndSettle();
  }

  Finder primaryAction() => find.byKey(const Key('book-primary-action'));

  void expectPrimaryLabel(String label) {
    expect(
      find.descendant(of: primaryAction(), matching: find.text(label)),
      findsOneWidget,
    );
  }

  void expectNoSignInCta() {
    expect(find.textContaining('Sign in to'), findsNothing);
    expect(find.textContaining('Sign In to'), findsNothing);
  }

  Future<void> tapPrimary(WidgetTester tester) async {
    await tester.tap(primaryAction());
    await tester.pumpAndSettle();
  }

  /// For states where the busy button keeps animating behind a sheet.
  Future<void> pumpFrames(WidgetTester tester) async {
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  Future<void> continueWithGoogle(WidgetTester tester) async {
    expect(find.text('Continue with Google'), findsOneWidget);
    await tester.tap(find.byKey(const Key('google-sign-in')));
    await tester.pumpAndSettle();
  }

  void expectReaderOn(String chapterId, int number, String title) {
    expect(find.byKey(ValueKey<String>('reader-content-$chapterId')),
        findsOneWidget);
    expect(find.text('Chapter $number'), findsOneWidget);
    expect(find.text(title), findsOneWidget);
  }

  group('free book', () {
    testWidgets(
        'guest taps Read now, signs in with Google and lands in the reader',
        (WidgetTester tester) async {
      setUpContainer();
      await launch(tester);
      await openBook(tester, _freeId);

      expectPrimaryLabel('Read now');
      expectNoSignInCta();

      await tapPrimary(tester);
      await continueWithGoogle(tester);

      expect(container.authController.isAuthenticated, isTrue);
      expectReaderOn('ch1', 1, 'Opening');

      await tester.tap(find.byTooltip('Back'));
      await tester.pumpAndSettle();
      expect(find.text('Tirukkural Wisdom'), findsWidgets);
      expectPrimaryLabel('Read now');
    });

    testWidgets('cancelling Google sign-in returns to the same book',
        (WidgetTester tester) async {
      setUpContainer();
      google.idToken = null;
      await launch(tester);
      await openBook(tester, _freeId);

      await tapPrimary(tester);
      await tester.tap(find.byKey(const Key('google-sign-in')));
      await tester.pumpAndSettle();

      expect(container.authController.isAuthenticated, isFalse);
      expect(find.text('Continue with Google'), findsNothing);
      expect(find.byKey(const ValueKey<String>('reader-content-ch1')),
          findsNothing);
      expect(find.text('Tirukkural Wisdom'), findsWidgets);
      expectPrimaryLabel('Read now');
    });

    testWidgets('after logout a free book asks for sign-in again',
        (WidgetTester tester) async {
      setUpContainer();
      await signInBeforeLaunch();
      await launch(tester);
      await container.authController.signOutLocal();
      await tester.pumpAndSettle();

      await openBook(tester, _freeId);
      expectPrimaryLabel('Read now');
      await tapPrimary(tester);

      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.byKey(const ValueKey<String>('reader-content-ch1')),
          findsNothing);
    });
  });

  group('premium book', () {
    testWidgets(
        'guest buys: sign-in, Razorpay, verification, then Read now on the same page',
        (WidgetTester tester) async {
      setUpContainer();
      await launch(tester);
      await openBook(tester, _paidId);

      expectPrimaryLabel('Buy now');
      expectNoSignInCta();

      await tapPrimary(tester);
      await continueWithGoogle(tester);

      expect(checkout.opened, 1);
      expect(backend.verifyCalls, 1);
      expect(find.text('Purchase complete. Inner Fire is unlocked.'),
          findsOneWidget);
      expect(find.text('Inner Fire'), findsWidgets);
      expect(find.byKey(const ValueKey<String>('reader-content-chp1')),
          findsNothing);
      expectPrimaryLabel('Read now');
      expect(container.libraryController.owns(_paidId), isTrue);

      await tapPrimary(tester);
      expectReaderOn('chp1', 1, 'Ember');
    });

    testWidgets('cancelling Razorpay keeps the book locked on the same page',
        (WidgetTester tester) async {
      setUpContainer();
      checkout.error = const CheckoutCancelled();
      await signInBeforeLaunch();
      await launch(tester);
      await openBook(tester, _paidId);

      expectPrimaryLabel('Buy now');
      await tapPrimary(tester);

      expect(checkout.opened, 1);
      expect(backend.verifyCalls, 0);
      expect(find.text('Payment cancelled.'), findsOneWidget);
      expect(find.text('Inner Fire'), findsWidgets);
      expectPrimaryLabel('Buy now');
      expect(container.libraryController.owns(_paidId), isFalse);
    });

    testWidgets(
        'a failed payment offers a retry and never unlocks the book early',
        (WidgetTester tester) async {
      setUpContainer();
      checkout.error =
          const CheckoutFailed('Check your connection and try again.');
      await signInBeforeLaunch();
      await launch(tester);
      await openBook(tester, _paidId);

      await tester.tap(primaryAction());
      await pumpFrames(tester);

      expect(find.text('Payment not completed'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
      expect(container.libraryController.owns(_paidId), isFalse);

      checkout.error = null;
      await tester.tap(find.text('Try again'));
      await tester.pumpAndSettle();

      expect(checkout.opened, 2);
      expect(find.text('Payment not completed'), findsNothing);
      expectPrimaryLabel('Read now');
      expect(container.libraryController.owns(_paidId), isTrue);
    });

    testWidgets('closing the failure sheet leaves Buy now in place',
        (WidgetTester tester) async {
      setUpContainer();
      checkout.error = const CheckoutFailed('Card declined');
      await signInBeforeLaunch();
      await launch(tester);
      await openBook(tester, _paidId);

      await tester.tap(primaryAction());
      await pumpFrames(tester);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();

      expect(find.text('Inner Fire'), findsWidgets);
      expectPrimaryLabel('Buy now');
      expect(container.libraryController.owns(_paidId), isFalse);
    });

    testWidgets('an owned book shows Read now after an app restart',
        (WidgetTester tester) async {
      setUpContainer();
      await signInBeforeLaunch();
      backend.owned.add(_paidId);

      container = AppContainer.create(
        httpClient: backend,
        sessionStore: SessionStore(storage: const FlutterSecureStorage()),
        googleAuth: FakeGoogleAuth(),
        firebaseAuth:
            FakeFirebaseAuth(current: FakeFirebaseAuth.sampleIdentity),
        checkout: checkout,
      );
      await launch(tester);
      await openBook(tester, _paidId);

      expect(container.authController.isAuthenticated, isTrue);
      expectPrimaryLabel('Read now');
      expectNoSignInCta();

      await tapPrimary(tester);
      expect(checkout.opened, 0);
      expectReaderOn('chp1', 1, 'Ember');
    });
  });

  testWidgets(
      'reader opens the selected chapter and navigates between chapters',
      (WidgetTester tester) async {
    setUpContainer();
    await signInBeforeLaunch();
    await launch(tester);
    await openBook(tester, _freeId);

    await tester.tap(
      find.descendant(
          of: find.byType(AppTabBar), matching: find.text('Chapters')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Second'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Second'));
    await tester.pumpAndSettle();
    expectReaderOn('ch2', 2, 'Second');

    await tester.tap(find.byTooltip('Next'));
    await tester.pumpAndSettle();
    expectReaderOn('ch3', 3, 'Third');

    await tester.tap(find.byTooltip('Previous'));
    await tester.pumpAndSettle();
    expectReaderOn('ch2', 2, 'Second');

    await tester.tap(find.byTooltip('Chapters'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey<String>('reader-chapter-ch5')));
    await tester.pumpAndSettle();
    expectReaderOn('ch5', 5, 'Fifth');

    await tester.tap(find.byTooltip('Next'));
    await tester.pumpAndSettle();
    expectReaderOn('ch5', 5, 'Fifth');

    await tester.tap(find.byTooltip('Back'));
    await tester.pumpAndSettle();
    expect(find.text('Tirukkural Wisdom'), findsWidgets);

    await tester.scrollUntilVisible(
      find.text('Fifth'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.text('Fifth'));
    await tester.pumpAndSettle();
    expectReaderOn('ch5', 5, 'Fifth');
    expect(find.text('Chapter 5/5'), findsOneWidget);
    expect(find.byTooltip('Share'), findsOneWidget);
    expect(find.byTooltip('Reading settings'), findsOneWidget);

    await tester.tap(find.byTooltip('Dark theme'));
    await tester.pumpAndSettle();
    expect(container.readerPreferences.theme, ReaderThemeMode.dark);
    await tester.tap(find.byTooltip('Olaichuvadi theme'));
    await tester.pumpAndSettle();
    expect(container.readerPreferences.theme, ReaderThemeMode.olaichuvadi);

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(
        find.byKey(const ValueKey<String>('reader-content-ch5')), findsNothing);
    expect(find.text('Read now'), findsNothing);
    expect(find.text('Press back again to exit'), findsNothing);
  });
}

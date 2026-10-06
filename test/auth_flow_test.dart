import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:maanthirigam/app/maanthirigam_app.dart';
import 'package:maanthirigam/core/app_container.dart';
import 'package:maanthirigam/core/errors/api_exception.dart';
import 'package:maanthirigam/core/storage/session_store.dart';
import 'package:maanthirigam/data/models/user_profile.dart';
import 'package:maanthirigam/data/services/firebase_auth_gateway.dart';
import 'package:maanthirigam/data/services/google_auth_gateway.dart';
import 'package:maanthirigam/state/auth_controller.dart';

import 'support/scripted_http.dart';
import 'support/test_container.dart';

const String _authOk = '''
{"success":true,"data":{
  "accessToken":"backend-jwt",
  "user":{"id":"u1","name":"Reader","email":"reader@example.com","profileImageUrl":null}
}}
''';

const String _googleTokenInvalid = '''
{"success":false,"error":{"code":"GOOGLE_TOKEN_INVALID","message":"bad token"}}
''';

Map<String, http.Response> _routes({http.Response? auth}) {
  return <String, http.Response>{
    'GET /api/v1/app-config': jsonOk(sampleAppConfig),
    'GET /api/v1/announcements': jsonOk(sampleAnnouncements),
    'GET /api/v1/books': jsonOk(sampleBooks),
    'GET /api/v1/library': jsonOk('{"success":true,"data":[]}'),
    'POST /api/v1/auth/google': auth ?? jsonOk(_authOk),
  };
}

/// Builds a container over the current mock secure storage (no reset),
/// so a second instance behaves like an app restart.
AppContainer _containerOverExistingStorage({
  required http.Client http,
  required FakeGoogleAuth google,
  required FakeFirebaseAuth firebase,
}) {
  return AppContainer.create(
    httpClient: http,
    sessionStore: SessionStore(storage: const FlutterSecureStorage()),
    googleAuth: google,
    firebaseAuth: firebase,
    checkout: FakeCheckout(),
  );
}

/// Answers `/library` with 401 unless the request carries [validToken],
/// mimicking a backend JWT that has expired.
class _ExpiringTokenHttp extends http.BaseClient {
  _ExpiringTokenHttp(this.inner, {required this.validToken});

  final ScriptedHttpClient inner;
  final String validToken;
  final List<String?> libraryTokens = <String?>[];

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (request.url.path == '/api/v1/library') {
      final String? header = request.headers['Authorization'];
      libraryTokens.add(header);
      if (header != 'Bearer $validToken') {
        return http.StreamedResponse(
          Stream<List<int>>.value(utf8.encode(
            '{"success":false,"error":{"code":"TOKEN_EXPIRED","message":"expired"}}',
          )),
          401,
          headers: <String, String>{'content-type': 'application/json'},
          request: request,
        );
      }
    }
    return inner.send(request);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late ScriptedHttpClient client;
  late FakeGoogleAuth google;
  late FakeFirebaseAuth firebase;
  late AppContainer container;

  AuthController auth() => container.authController;

  void setUpContainer({http.Response? authResponse}) {
    client = ScriptedHttpClient(_routes(auth: authResponse));
    google = FakeGoogleAuth();
    firebase = FakeFirebaseAuth();
    container = testContainer(
      httpClient: client,
      googleAuth: google,
      firebaseAuth: firebase,
    );
  }

  group('Google sign-in', () {
    test('signs in with Firebase, exchanges the Google token, and stores the session',
        () async {
      setUpContainer();
      await auth().restore();
      expect(auth().isAuthenticated, isFalse);

      expect(await auth().signInWithGoogle(), SignInOutcome.signedIn);
      expect(auth().errorMessage, isNull);
      expect(firebase.lastCredentials?.idToken, 'google-id-token');
      expect(firebase.lastCredentials?.accessToken, 'google-access-token');
      expect(firebase.current?.uid, 'firebase-uid-1');

      final http.Request exchange = client.requests.whereType<http.Request>().singleWhere(
            (http.Request r) => r.url.path == '/api/v1/auth/google',
          );
      expect(jsonDecode(exchange.body), <String, dynamic>{'idToken': 'google-id-token'});

      final UserProfile user = auth().user!;
      expect(user.id, 'u1');
      expect(user.name, 'Reader');
      expect(user.email, 'reader@example.com');
      expect(user.profileImageUrl, 'https://example.com/photo.png');
      expect(user.firebaseUid, 'firebase-uid-1');

      expect(await container.sessionStore.readAccessToken(), 'backend-jwt');
      expect((await container.sessionStore.readUser())?.firebaseUid, 'firebase-uid-1');
      // The Google account stays cached so the session can be renewed silently.
      expect(google.cleared, 0);
    });

    test('cancellation keeps the user signed out without calling Firebase or the API',
        () async {
      setUpContainer();
      google.idToken = null;

      expect(await auth().signInWithGoogle(), SignInOutcome.cancelled);
      expect(auth().isAuthenticated, isFalse);
      expect(auth().errorMessage, isNull);
      expect(firebase.lastCredentials, isNull);
      expect(client.requests.where((r) => r.url.path == '/api/v1/auth/google'), isEmpty);
    });

    test('Firebase credential failure surfaces a message and skips the backend', () async {
      setUpContainer();
      firebase.error = const ApiException(
        statusCode: 401,
        code: 'FIREBASE_CREDENTIAL_INVALID',
        message: 'expired',
      );

      expect(await auth().signInWithGoogle(), SignInOutcome.failed);
      expect(auth().isAuthenticated, isFalse);
      expect(auth().errorMessage, 'Your Google sign-in expired. Please try again.');
      expect(client.requests.where((r) => r.url.path == '/api/v1/auth/google'), isEmpty);
    });

    test('backend rejection rolls back the Firebase sign-in', () async {
      setUpContainer(authResponse: jsonOk(_googleTokenInvalid, status: 401));

      expect(await auth().signInWithGoogle(), SignInOutcome.failed);
      expect(auth().isAuthenticated, isFalse);
      expect(firebase.current, isNull);
      expect(google.cleared, 1);
      expect(await container.sessionStore.readAccessToken(), isNull);
      expect(
        auth().errorMessage,
        'Google sign-in could not be verified. Please try again.',
      );
    });

    test('network failure from Google Sign-In is reported', () async {
      setUpContainer();
      google.error = const NetworkException();

      expect(await auth().signInWithGoogle(), SignInOutcome.failed);
      expect(auth().errorMessage, 'Check your connection and try again.');
    });

    test('configuration errors are reported before opening the account picker', () async {
      setUpContainer();
      firebase.isAvailable = false;

      expect(await auth().signInWithGoogle(), SignInOutcome.failed);
      expect(auth().errorMessage, contains('Firebase is not configured'));
      expect(google.requests, 0);
    });

    test('unexpected errors do not escape the controller', () async {
      setUpContainer();
      google.error = StateError('boom');

      expect(await auth().signInWithGoogle(), SignInOutcome.failed);
      expect(
        auth().errorMessage,
        'Google sign-in could not be completed. Please try again.',
      );
    });

    test('concurrent sign-in requests only open one Google flow', () async {
      setUpContainer();

      final Future<SignInOutcome> first = auth().signInWithGoogle();
      final Future<SignInOutcome> second = auth().signInWithGoogle();

      expect(await second, SignInOutcome.busy);
      expect(await first, SignInOutcome.signedIn);
      expect(google.requests, 1);
    });
  });

  group('session', () {
    test('restores the session after an app restart', () async {
      setUpContainer();
      await auth().signInWithGoogle();

      final FakeFirebaseAuth restartedFirebase =
          FakeFirebaseAuth(current: FakeFirebaseAuth.sampleIdentity);
      final AppContainer restarted = _containerOverExistingStorage(
        http: client,
        google: FakeGoogleAuth(),
        firebase: restartedFirebase,
      );
      await restarted.authController.restore();

      expect(restarted.authController.isAuthenticated, isTrue);
      expect(restarted.authController.user?.firebaseUid, 'firebase-uid-1');
      expect(restarted.authController.user?.email, 'reader@example.com');
    });

    test('a stored API session without a Firebase user is cleared', () async {
      setUpContainer();
      await auth().signInWithGoogle();

      final AppContainer restarted = _containerOverExistingStorage(
        http: client,
        google: FakeGoogleAuth(),
        firebase: FakeFirebaseAuth(),
      );
      await restarted.authController.restore();

      expect(restarted.authController.isAuthenticated, isFalse);
      expect(await restarted.sessionStore.readAccessToken(), isNull);
    });

    test('a Firebase user without an API session is signed out', () async {
      setUpContainer();
      firebase.current = FakeFirebaseAuth.sampleIdentity;

      await auth().restore();

      expect(auth().isAuthenticated, isFalse);
      expect(firebase.current, isNull);
    });

    test('sign out clears Firebase, Google and the stored session', () async {
      setUpContainer();
      await auth().restore();
      await auth().signInWithGoogle();
      final int clearedBefore = google.cleared;

      await auth().signOutLocal();

      expect(auth().isAuthenticated, isFalse);
      expect(auth().sessionExpired, isFalse);
      expect(firebase.current, isNull);
      expect(google.cleared, greaterThan(clearedBefore));
      expect(await container.sessionStore.readAccessToken(), isNull);
      expect(await container.sessionStore.readUser(), isNull);
    });

    test('Firebase dropping the user ends the app session', () async {
      setUpContainer();
      await auth().restore();
      await auth().signInWithGoogle();

      firebase.externalSignOut();
      await pumpEventQueue();

      expect(auth().isAuthenticated, isFalse);
      expect(auth().sessionExpired, isTrue);
      expect(await container.sessionStore.readAccessToken(), isNull);
    });

    Future<AppContainer> restartWithExpiredToken(
      http.Client transport, {
      required FakeGoogleAuth google,
    }) async {
      setUpContainer();
      await auth().signInWithGoogle();
      final AppContainer restarted = _containerOverExistingStorage(
        http: transport,
        google: google,
        firebase: FakeFirebaseAuth(current: FakeFirebaseAuth.sampleIdentity),
      );
      await restarted.authController.restore();
      expect(restarted.authController.isAuthenticated, isTrue);
      return restarted;
    }

    test('an expired API token is renewed silently and the request retried', () async {
      final ScriptedHttpClient backend = ScriptedHttpClient(<String, http.Response>{
        ..._routes(),
        'POST /api/v1/auth/google': jsonOk(_authOk.replaceFirst('backend-jwt', 'fresh-jwt')),
        'GET /api/v1/library': jsonOk(
          '{"success":true,"data":[],"pagination":{"page":1,"limit":50,"total":0,"totalPages":1}}',
        ),
      });
      final _ExpiringTokenHttp transport = _ExpiringTokenHttp(backend, validToken: 'fresh-jwt');
      final FakeGoogleAuth silentGoogle = FakeGoogleAuth()..silentIdToken = 'silent-id-token';

      final AppContainer restarted =
          await restartWithExpiredToken(transport, google: silentGoogle);
      await restarted.libraryController.refresh();

      expect(transport.libraryTokens, <String>['Bearer backend-jwt', 'Bearer fresh-jwt']);
      expect(silentGoogle.silentRequests, 1);
      final http.Request exchange = backend.requests.whereType<http.Request>().lastWhere(
            (http.Request r) => r.url.path == '/api/v1/auth/google',
          );
      expect(jsonDecode(exchange.body), <String, dynamic>{'idToken': 'silent-id-token'});
      expect(restarted.authController.isAuthenticated, isTrue);
      expect(restarted.authController.sessionExpired, isFalse);
      expect(restarted.libraryController.loaded, isTrue);
      expect(restarted.libraryController.errorMessage, isNull);
      expect(await restarted.sessionStore.readAccessToken(), 'fresh-jwt');
    });

    test('an expired token without a silent Google session ends the session', () async {
      final _ExpiringTokenHttp transport =
          _ExpiringTokenHttp(ScriptedHttpClient(_routes()), validToken: 'never-issued');

      final AppContainer restarted =
          await restartWithExpiredToken(transport, google: FakeGoogleAuth());
      await restarted.libraryController.refresh();

      expect(transport.libraryTokens, hasLength(1));
      expect(restarted.authController.isAuthenticated, isFalse);
      expect(restarted.authController.sessionExpired, isTrue);
      expect(await restarted.sessionStore.readAccessToken(), isNull);
    });
  });

  group('login screen', () {
    Future<void> openLoginFromProfile(WidgetTester tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(MaanthirigamApp(container: container));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Profile'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continue with Google'));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('google-sign-in')), findsOneWidget);
    }

    void setUpWidgetContainer() {
      client = ScriptedHttpClient(_routes());
      google = FakeGoogleAuth();
      firebase = FakeFirebaseAuth(
        identity: const FirebaseIdentity(
          uid: 'firebase-uid-1',
          displayName: 'Firebase Reader',
          email: 'reader@example.com',
        ),
      );
      container = testContainer(
        httpClient: client,
        googleAuth: google,
        firebaseAuth: firebase,
      );
    }

    testWidgets('successful sign-in returns to the profile, sign-out returns to guest',
        (WidgetTester tester) async {
      setUpWidgetContainer();
      await openLoginFromProfile(tester);

      await tester.tap(find.byKey(const Key('google-sign-in')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('google-sign-in')), findsNothing);
      expect(find.text('Reader'), findsOneWidget);
      expect(find.text('reader@example.com'), findsOneWidget);

      await tester.tap(find.byKey(const Key('sign-out')));
      await tester.pumpAndSettle();

      expect(find.text('Browsing as guest'), findsOneWidget);
      expect(firebase.current, isNull);
    });

    testWidgets('cancelled sign-in returns to the previous screen',
        (WidgetTester tester) async {
      setUpWidgetContainer();
      google.idToken = null;
      await openLoginFromProfile(tester);

      await tester.tap(find.byKey(const Key('google-sign-in')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('google-sign-in')), findsNothing);
      expect(find.text('Browsing as guest'), findsOneWidget);
    });

    testWidgets('errors stay on the login screen and offer a retry',
        (WidgetTester tester) async {
      setUpWidgetContainer();
      google.error = const GoogleSignInConfigException('Google Sign-In is not configured.');
      await openLoginFromProfile(tester);

      await tester.tap(find.byKey(const Key('google-sign-in')));
      await tester.pumpAndSettle();

      expect(find.text('Google Sign-In is not configured.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);

      google.error = null;
      await tester.tap(find.byKey(const Key('google-sign-in')));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('google-sign-in')), findsNothing);
      expect(find.text('Reader'), findsOneWidget);
    });

    testWidgets('network failure shows the connection message and retry',
        (WidgetTester tester) async {
      setUpWidgetContainer();
      google.error = const NetworkException();
      await openLoginFromProfile(tester);

      await tester.tap(find.byKey(const Key('google-sign-in')));
      await tester.pumpAndSettle();

      expect(find.text('Check your connection and try again.'), findsOneWidget);
      expect(find.text('Try again'), findsOneWidget);
    });
  });
}

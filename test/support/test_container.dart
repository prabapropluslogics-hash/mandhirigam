import 'dart:async';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:maanthirigam/core/app_container.dart';
import 'package:maanthirigam/core/storage/session_store.dart';
import 'package:maanthirigam/data/models/payment.dart';
import 'package:maanthirigam/data/models/user_profile.dart';
import 'package:maanthirigam/data/services/firebase_auth_gateway.dart';
import 'package:maanthirigam/data/services/google_auth_gateway.dart';
import 'package:maanthirigam/data/services/razorpay_checkout.dart';
import 'package:package_info_plus/package_info_plus.dart';
class FakeGoogleAuth implements GoogleAuthGateway {
  FakeGoogleAuth({this.idToken = 'google-id-token'});

  /// `null` simulates the user cancelling the account picker.
  String? idToken;
  Object? error;
  int requests = 0;
  int cleared = 0;

  @override
  Future<GoogleCredentials?> requestCredentials() async {
    requests += 1;
    if (error != null) throw error!;
    final String? token = idToken;
    if (token == null) return null;
    return GoogleCredentials(idToken: token, accessToken: 'google-access-token');
  }

  /// Token returned by a silent sign-in; `null` means it is not possible.
  String? silentIdToken;
  int silentRequests = 0;

  @override
  Future<GoogleCredentials?> silentCredentials() async {
    silentRequests += 1;
    final String? token = silentIdToken;
    return token == null ? null : GoogleCredentials(idToken: token);
  }

  @override
  Future<void> clearGoogleSession() async {
    cleared += 1;
  }
}

class FakeFirebaseAuth implements FirebaseAuthGateway {
  FakeFirebaseAuth({
    this.current,
    this.isAvailable = true,
    this.identity = sampleIdentity,
  });

  FirebaseIdentity? current;
  final FirebaseIdentity identity;
  Object? error;
  GoogleCredentials? lastCredentials;
  final StreamController<FirebaseIdentity?> _changes =
      StreamController<FirebaseIdentity?>.broadcast();

  @override
  bool isAvailable;

  static const FirebaseIdentity sampleIdentity = FirebaseIdentity(
    uid: 'firebase-uid-1',
    displayName: 'Firebase Reader',
    email: 'reader@example.com',
    photoUrl: 'https://example.com/photo.png',
  );

  @override
  Future<FirebaseIdentity?> restoreUser() async => current;

  @override
  Stream<FirebaseIdentity?> userChanges() => _changes.stream;

  @override
  Future<FirebaseIdentity> signInWithGoogle(GoogleCredentials credentials) async {
    lastCredentials = credentials;
    if (error != null) throw error!;
    current = identity;
    _changes.add(current);
    return identity;
  }

  @override
  Future<void> signOut() async {
    if (current == null) return;
    current = null;
    _changes.add(null);
  }

  /// Simulates Firebase dropping the user (disabled / revoked).
  void externalSignOut() {
    current = null;
    _changes.add(null);
  }
}

class FakeCheckout implements CheckoutGateway {
  FakeCheckout({this.success});

  CheckoutSuccess? success;
  Object? error;
  int opened = 0;

  @override
  Future<CheckoutSuccess> open({
    required CreateOrderResult order,
    required String bookTitle,
    required String appName,
    UserProfile? user,
  }) async {
    opened += 1;
    if (error != null) throw error!;
    return success ??
        CheckoutSuccess(
          razorpayOrderId: order.orderId,
          razorpayPaymentId: 'pay_test',
          razorpaySignature: 'sig_test',
        );
  }

  @override
  void dispose() {}
}

AppContainer testContainer({
  required http.Client httpClient,
  FakeGoogleAuth? googleAuth,
  FakeFirebaseAuth? firebaseAuth,
  FakeCheckout? checkout,
}) {
  FlutterSecureStorage.setMockInitialValues(<String, String>{});
  PackageInfo.setMockInitialValues(
    appName: 'maanthirigam',
    packageName: 'com.maanthirigam.maanthirigam',
    version: '1.0.0',
    buildNumber: '1',
    buildSignature: '',
  );
  final SessionStore store = SessionStore(
    storage: const FlutterSecureStorage(),
  );
  return AppContainer.create(
    httpClient: httpClient,
    sessionStore: store,
    googleAuth: googleAuth ?? FakeGoogleAuth(),
    firebaseAuth: firebaseAuth ?? FakeFirebaseAuth(),
    checkout: checkout ?? FakeCheckout(),
  );
}

const String sampleAppConfig = '''
{
  "success": true,
  "data": {
    "version": 1,
    "branding": {
      "appName": "Mantirigam",
      "tagline": "Sacred knowledge",
      "logoUrl": null,
      "primaryColor": "#C9A36A",
      "secondaryColor": "#B08D57",
      "buttonColor": "#C9A36A"
    },
    "home": {
      "showHero": true,
      "heroTitle": "Mantirigam",
      "heroSubtitle": "Read with clarity",
      "heroImageUrl": null,
      "showFeaturedBooks": true,
      "featuredBooks": [],
      "showContinueReading": true,
      "showCategories": true,
      "showLatestBooks": true
    },
    "catalogue": {
      "showLanguageFilter": true,
      "showFreeBooks": true,
      "showPaidBooks": true,
      "defaultLanguage": "all"
    },
    "guestAccess": {
      "allowGuestFreeBookReading": true,
      "allowPaidBookPreview": false
    },
    "features": {
      "bookmarksEnabled": true,
      "readingProgressEnabled": true,
      "continueReadingEnabled": true,
      "announcementsEnabled": true,
      "featuredBooksEnabled": true
    },
    "appUpdate": {
      "android": {"latestVersion": null, "minimumVersion": null, "storeUrl": null},
      "ios": {"latestVersion": null, "minimumVersion": null, "storeUrl": null},
      "forceUpdateEnabled": false,
      "updateMessage": ""
    }
  }
}
''';

const String sampleBooks = '''
{
  "success": true,
  "data": [
    {
      "id": "aaaaaaaaaaaaaaaaaaaaaaaa",
      "title": "Tirukkural Wisdom",
      "description": "A free introduction to the text.",
      "author": "Thiruvalluvar",
      "language": "ta",
      "accessType": "FREE",
      "price": 0,
      "currency": "INR",
      "previewEnabled": false,
      "status": "PUBLISHED",
      "publishedAt": "2026-01-01T00:00:00.000Z"
    },
    {
      "id": "bbbbbbbbbbbbbbbbbbbbbbbb",
      "title": "Inner Fire",
      "description": "A paid commentary.",
      "author": "Mantirigam",
      "language": "en",
      "accessType": "PAID",
      "price": 29900,
      "currency": "INR",
      "previewEnabled": false,
      "status": "PUBLISHED",
      "publishedAt": "2026-01-02T00:00:00.000Z"
    }
  ],
  "pagination": {"page": 1, "limit": 20, "total": 2, "totalPages": 1}
}
''';

const String sampleAnnouncements = '''
{
  "success": true,
  "data": [
    {
      "id": "ann1",
      "title": "Welcome",
      "message": "A new season of reading.",
      "imageUrl": null,
      "actionLabel": "",
      "actionUrl": null,
      "displayOrder": 1,
      "publishedAt": "2026-01-01T00:00:00.000Z"
    }
  ]
}
''';

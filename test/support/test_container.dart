import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:maanthirigam/core/app_container.dart';
import 'package:maanthirigam/core/network/api_client.dart';
import 'package:maanthirigam/core/storage/session_store.dart';
import 'package:maanthirigam/data/models/payment.dart';
import 'package:maanthirigam/data/models/user_profile.dart';
import 'package:maanthirigam/data/services/google_auth_gateway.dart';
import 'package:maanthirigam/data/services/razorpay_checkout.dart';

import 'scripted_http.dart';

class FakeGoogleAuth implements GoogleAuthGateway {
  FakeGoogleAuth({this.idToken = 'google-id-token'});

  String? idToken;

  @override
  Future<String?> requestIdToken() async => idToken;

  @override
  Future<void> clearGoogleSession() async {}
}

class FakeCheckout implements CheckoutGateway {
  FakeCheckout({this.success});

  CheckoutSuccess? success;
  Object? error;

  @override
  Future<CheckoutSuccess> open({
    required CreateOrderResult order,
    required String bookTitle,
    required String appName,
    UserProfile? user,
  }) async {
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
  required ScriptedHttpClient httpClient,
  FakeGoogleAuth? googleAuth,
  FakeCheckout? checkout,
}) {
  FlutterSecureStorage.setMockInitialValues(<String, String>{});
  final SessionStore store = SessionStore(
    storage: const FlutterSecureStorage(),
  );
  return AppContainer.create(
    apiClient: ApiClient(
      httpClient: httpClient,
      readAccessToken: store.readAccessToken,
    ),
    sessionStore: store,
    googleAuth: googleAuth ?? FakeGoogleAuth(),
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

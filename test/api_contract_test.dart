import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:maanthirigam/core/errors/api_exception.dart';
import 'package:maanthirigam/core/network/api_client.dart';
import 'package:maanthirigam/core/network/api_envelope.dart';
import 'package:maanthirigam/core/utils/color_parse.dart';
import 'package:maanthirigam/core/utils/money_format.dart';
import 'package:maanthirigam/core/utils/safe_url.dart';
import 'package:maanthirigam/core/utils/version_compare.dart';
import 'package:maanthirigam/data/models/announcement.dart';
import 'package:maanthirigam/data/models/app_config.dart';
import 'package:maanthirigam/data/models/catalog_book.dart';
import 'package:maanthirigam/data/models/chapter.dart';
import 'package:maanthirigam/data/models/library_item.dart';
import 'package:maanthirigam/data/models/payment.dart';
import 'package:maanthirigam/data/models/user_profile.dart';

import 'support/scripted_http.dart';

void main() {
  test('parses success envelope and pagination', () {
    const String body = '''
    {"success":true,"data":[{"id":"1"}],"pagination":{"page":1,"limit":20,"total":1,"totalPages":1}}
    ''';
    final ApiEnvelope envelope = ApiEnvelope.parse(body, 200);
    expect(envelope.success, isTrue);
    expect(envelope.pagination!.hasMore, isFalse);
    envelope.throwIfError(200);
  });

  test('preserves backend error codes', () {
    const String body = '''
    {"success":false,"error":{"code":"PURCHASE_REQUIRED","message":"Buy this book"}}
    ''';
    final ApiEnvelope envelope = ApiEnvelope.parse(body, 403);
    expect(
      () => envelope.throwIfError(403),
      throwsA(
        isA<ApiException>()
            .having((ApiException e) => e.code, 'code', 'PURCHASE_REQUIRED')
            .having((ApiException e) => e.statusCode, 'status', 403)
            .having((ApiException e) => e.isPurchaseRequired, 'flag', isTrue),
      ),
    );
  });

  test('sends bearer token only for authorized requests', () async {
    final ScriptedHttpClient httpClient = ScriptedHttpClient(<String, http.Response>{
      'GET /api/v1/books': jsonOk('{"success":true,"data":[]}'),
      'GET /api/v1/library': jsonOk('{"success":true,"data":[]}'),
    });
    final ApiClient client = ApiClient(
      httpClient: httpClient,
      readAccessToken: () async => 'access-token',
    );
    await client.get('/books');
    await client.getAuthorized('/library');
    expect(
      httpClient.requests.first.headers.containsKey('Authorization'),
      isFalse,
    );
    expect(
      httpClient.requests.last.headers['Authorization'],
      'Bearer access-token',
    );
  });

  test('unauthorized handler fires for TOKEN_EXPIRED', () async {
    bool called = false;
    final ScriptedHttpClient httpClient = ScriptedHttpClient(<String, http.Response>{
      'GET /api/v1/library': http.Response(
        '{"success":false,"error":{"code":"TOKEN_EXPIRED","message":"Expired"}}',
        401,
        headers: <String, String>{'content-type': 'application/json'},
      ),
    });
    final ApiClient client = ApiClient(
      httpClient: httpClient,
      readAccessToken: () async => 'expired',
      onUnauthorized: (ApiException error) async {
        called = error.code == 'TOKEN_EXPIRED';
      },
    );
    await expectLater(client.getAuthorized('/library'), throwsA(isA<ApiException>()));
    expect(called, isTrue);
  });

  test('parses books, chapters, config, announcements, payment, library', () {
    final CatalogBook book = CatalogBook.fromJson(<String, dynamic>{
      'id': '1',
      'title': 'Inner Fire',
      'description': 'd',
      'author': 'A',
      'language': 'ta',
      'accessType': 'PAID',
      'price': 29900,
      'currency': 'INR',
    });
    expect(book.priceLabel, '₹299');
    expect(book.languageLabel, 'Tamil');

    final ChapterContent chapter = ChapterContent.fromJson(<String, dynamic>{
      'id': 'c1',
      'bookId': '1',
      'chapterNumber': 1,
      'title': 'Opening',
      'contentFormat': 'RICH_TEXT',
      'status': 'PUBLISHED',
      'content': <String, dynamic>{
        'version': 1,
        'blocks': <Map<String, dynamic>>[
          <String, dynamic>{'id': 'blk_1', 'type': 'paragraph', 'text': 'Hello'},
        ],
      },
    });
    expect(chapter.content.blocks.single.id, 'blk_1');

    final AppConfig config = AppConfig.fromJson(<String, dynamic>{
      'branding': <String, dynamic>{'appName': 'Mantirigam', 'primaryColor': '#6B21A8'},
      'guestAccess': <String, dynamic>{'allowGuestFreeBookReading': true},
      'features': <String, dynamic>{'announcementsEnabled': true},
    });
    expect(config.branding.appName, 'Mantirigam');
    expect(config.guestAccess.allowPaidBookPreview, isFalse);

    final Announcement announcement = Announcement.fromJson(<String, dynamic>{
      'id': 'a',
      'title': 'Hello',
      'message': 'World',
    });
    expect(announcement.hasAction, isFalse);

    final CreateOrderResult order = CreateOrderResult.fromJson(<String, dynamic>{
      'orderId': 'order_1',
      'amount': 29900,
      'currency': 'INR',
      'keyId': 'rzp_test',
    });
    expect(order.amount, 29900);

    final PaymentStatusResult status = PaymentStatusResult.fromJson(<String, dynamic>{
      'orderId': 'order_1',
      'status': 'CAPTURED',
      'purchaseStatus': 'SUCCESS',
      'entitled': true,
    });
    expect(status.isCapturedSuccess, isTrue);

    final LibraryItem item = LibraryItem.fromJson(<String, dynamic>{
      'bookId': '1',
      'title': 'Inner Fire',
      'language': 'en',
      'coverImage': null,
      'accessType': 'PAID',
      'entitlementType': 'LIFETIME',
      'grantedAt': '2026-01-01T00:00:00.000Z',
    });
    expect(item.entitlementType, 'LIFETIME');

    final GoogleAuthResult auth = GoogleAuthResult.fromJson(<String, dynamic>{
      'accessToken': 'jwt',
      'user': <String, dynamic>{
        'id': 'u1',
        'name': 'Reader',
        'email': 'a@b.com',
        'profileImageUrl': null,
      },
    });
    expect(auth.user.email, 'a@b.com');
  });

  test('money, color, version, and url helpers', () {
    expect(formatMoney(minorUnits: 29900), '₹299');
    expect(formatMoney(minorUnits: 29950), '₹299.50');
    expect(parseHexColor('#C9A36A')!.value, 0xFFC9A36A);
    expect(parseHexColor('bad'), isNull);
    expect(
      resolveAppUpdate(
        currentVersion: '1.0.0',
        latestVersion: '1.1.0',
        minimumVersion: '1.0.0',
        forceUpdateEnabled: true,
      ),
      AppUpdateKind.optional,
    );
    expect(
      resolveAppUpdate(
        currentVersion: '0.9.0',
        latestVersion: '1.1.0',
        minimumVersion: '1.0.0',
        forceUpdateEnabled: true,
      ),
      AppUpdateKind.required,
    );
    expect(parseSafeHttpUrl('javascript:alert(1)'), isNull);
    expect(parseSafeHttpUrl('https://play.google.com/store'), isNotNull);
  });
}

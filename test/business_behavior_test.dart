import 'package:flutter_test/flutter_test.dart';
import 'package:maanthirigam/core/errors/api_exception.dart';
import 'package:maanthirigam/data/models/app_config.dart';
import 'package:maanthirigam/data/models/catalog_book.dart';
import 'package:maanthirigam/data/models/payment.dart';
import 'package:maanthirigam/data/models/rich_text_document.dart';
import 'package:maanthirigam/data/models/user_profile.dart';
import 'package:maanthirigam/data/repositories/auth_repository.dart';
import 'package:maanthirigam/features/reader/presentation/widgets/rich_text_document_view.dart';
import 'package:maanthirigam/state/auth_controller.dart';
import 'package:maanthirigam/state/payment_controller.dart';
import 'package:flutter/material.dart';

void main() {
  test('guest free reading follows app-config, paid always restricted', () {
    const GuestAccessConfig guestsAllowed = GuestAccessConfig(
      allowGuestFreeBookReading: true,
      allowPaidBookPreview: false,
    );
    const GuestAccessConfig guestsDenied = GuestAccessConfig(
      allowGuestFreeBookReading: false,
      allowPaidBookPreview: false,
    );
    const CatalogBook free = CatalogBook(
      id: 'f',
      title: 'Free',
      description: '',
      author: '',
      language: 'ta',
      accessType: 'FREE',
      price: 0,
      currency: 'INR',
    );
    const CatalogBook paid = CatalogBook(
      id: 'p',
      title: 'Paid',
      description: '',
      author: '',
      language: 'en',
      accessType: 'PAID',
      price: 29900,
      currency: 'INR',
    );

    bool canGuestRead(CatalogBook book, GuestAccessConfig guest, {required bool authed}) {
      if (book.isPaid) return authed; // still needs entitlement from backend
      if (authed) return true;
      return guest.allowGuestFreeBookReading;
    }

    expect(canGuestRead(free, guestsAllowed, authed: false), isTrue);
    expect(canGuestRead(free, guestsDenied, authed: false), isFalse);
    expect(canGuestRead(paid, guestsAllowed, authed: false), isFalse);
  });

  test('token expiry clears session once', () async {
    final _MemoryAuthRepository repo = _MemoryAuthRepository();
    repo.user = const UserProfile(id: '1', name: 'A', email: 'a@b.com');
    final AuthController auth = AuthController(repo);
    await auth.restore();
    expect(auth.isAuthenticated, isTrue);
    await auth.handleUnauthorized(
      const ApiException(statusCode: 401, code: 'TOKEN_EXPIRED', message: 'x'),
    );
    expect(auth.isAuthenticated, isFalse);
    expect(auth.sessionExpired, isTrue);
    expect(repo.cleared, 1);
    await auth.handleUnauthorized(
      const ApiException(statusCode: 401, code: 'TOKEN_EXPIRED', message: 'x'),
    );
    expect(repo.cleared, 1);
  });

  test('payment success requires entitled verification payload', () {
    const PaymentStatusResult ok = PaymentStatusResult(
      orderId: 'o',
      status: 'CAPTURED',
      purchaseStatus: 'SUCCESS',
      entitled: true,
    );
    const PaymentStatusResult checkoutOnly = PaymentStatusResult(
      orderId: 'o',
      status: 'CREATED',
      purchaseStatus: 'CREATED',
      entitled: false,
    );
    expect(ok.isCapturedSuccess, isTrue);
    expect(checkoutOnly.isCapturedSuccess, isFalse);
    expect(PaymentPhase.success, isNot(PaymentPhase.checkout));
  });

  testWidgets('rich text v1 renders stable block ids and marks', (tester) async {
    const RichTextDocument document = RichTextDocument(
      version: 1,
      blocks: <RichTextBlock>[
        RichTextBlock(id: 'blk_p', type: 'paragraph', text: 'Hello world', marks: <RichTextMark>[
          RichTextMark(start: 0, end: 5, type: 'bold'),
          RichTextMark(start: 6, end: 11, type: 'italic'),
        ]),
        RichTextBlock(id: 'blk_h', type: 'heading', text: 'Title', level: 1),
        RichTextBlock(
          id: 'blk_b',
          type: 'bullet_list',
          items: <RichTextListItem>[RichTextListItem(text: 'One')],
        ),
        RichTextBlock(
          id: 'blk_o',
          type: 'ordered_list',
          items: <RichTextListItem>[RichTextListItem(text: 'First')],
        ),
        RichTextBlock(id: 'blk_q', type: 'quote', text: 'Quoted'),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(body: SingleChildScrollView(child: RichTextDocumentView(document: document))),
      ),
    );

    expect(find.byKey(const ValueKey<String>('blk_p')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('blk_h')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('blk_b')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('blk_o')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('blk_q')), findsOneWidget);
    expect(find.text('Hello world'), findsOneWidget);
    expect(find.text('Title'), findsOneWidget);
    expect(find.text('One'), findsOneWidget);
    expect(find.text('First'), findsOneWidget);
    expect(find.text('Quoted'), findsOneWidget);
  });
}

class _MemoryAuthRepository implements AuthRepository {
  UserProfile? user;
  int cleared = 0;

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<GoogleAuthResult?> restore() async {
    final UserProfile? current = user;
    if (current == null) return null;
    return GoogleAuthResult(accessToken: 'token', user: current);
  }

  @override
  Future<void> signOutLocal() async {
    cleared += 1;
    user = null;
  }
}

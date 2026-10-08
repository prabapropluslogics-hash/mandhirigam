import 'package:flutter_test/flutter_test.dart';
import 'package:maanthirigam/core/errors/api_exception.dart';
import 'package:maanthirigam/data/models/payment.dart';
import 'package:maanthirigam/data/models/user_profile.dart';
import 'package:maanthirigam/data/repositories/payments_repository.dart';
import 'package:maanthirigam/data/services/payment_key_policy.dart';
import 'package:maanthirigam/data/services/razorpay_checkout.dart';
import 'package:maanthirigam/state/payment_controller.dart';

const PaymentStatusResult _captured = PaymentStatusResult(
  orderId: 'order_1',
  status: 'CAPTURED',
  purchaseStatus: 'SUCCESS',
  entitled: true,
);

class _FakeRepository implements PaymentsRepository {
  CreateOrderResult order = const CreateOrderResult(
    orderId: 'order_1',
    amount: 9900,
    currency: 'INR',
    keyId: 'rzp_test_abc',
  );
  Object? createError;
  Object? checkoutError;
  final List<Object> verifyResults = <Object>[];
  final List<Object> statusResults = <Object>[];
  int orders = 0;
  int checkouts = 0;
  int verifies = 0;
  CreateOrderResult? openedWith;

  @override
  Future<CreateOrderResult> createOrder(String bookId) async {
    orders += 1;
    if (createError != null) throw createError!;
    return order;
  }

  @override
  Future<CheckoutSuccess> openCheckout({
    required CreateOrderResult order,
    required String bookTitle,
    required String appName,
    UserProfile? user,
  }) async {
    checkouts += 1;
    openedWith = order;
    if (checkoutError != null) throw checkoutError!;
    return CheckoutSuccess(
      razorpayOrderId: order.orderId,
      razorpayPaymentId: 'pay_1',
      razorpaySignature: 'sig_1',
    );
  }

  @override
  Future<PaymentStatusResult> verify(CheckoutSuccess payload) async {
    verifies += 1;
    return _next(verifyResults);
  }

  @override
  Future<PaymentStatusResult> status(String orderId) async =>
      _next(statusResults);

  static PaymentStatusResult _next(List<Object> results) {
    final Object result =
        results.length > 1 ? results.removeAt(0) : results.first;
    if (result is PaymentStatusResult) return result;
    throw result;
  }
}

PaymentStatusResult _status(String status, {bool entitled = false}) =>
    PaymentStatusResult(
      orderId: 'order_1',
      status: status,
      purchaseStatus: entitled ? 'SUCCESS' : 'PENDING',
      entitled: entitled,
    );

void main() {
  group('PaymentKeyPolicy', () {
    const CreateOrderResult order = CreateOrderResult(
      orderId: 'order_1',
      amount: 9900,
      currency: 'INR',
      keyId: 'rzp_test_backend',
    );

    test('uses the backend key', () {
      const PaymentKeyPolicy policy = PaymentKeyPolicy(development: true);
      expect(policy.resolve(order).keyId, 'rzp_test_backend');
      expect(policy.isTestCheckout('rzp_test_backend'), isTrue);
    });

    test('development builds never open a live checkout', () {
      const PaymentKeyPolicy policy = PaymentKeyPolicy(development: true);
      expect(
        () => policy.resolve(order.withKey('rzp_live_real')),
        throwsA(isA<PaymentConfigurationException>()),
      );
    });

    test('development builds refuse a key other than RAZORPAY_TEST_KEY_ID', () {
      const PaymentKeyPolicy policy = PaymentKeyPolicy(
        development: true,
        expectedTestKeyId: 'rzp_test_mine',
      );
      expect(
        () => policy.resolve(order),
        throwsA(isA<PaymentConfigurationException>()),
      );
      expect(policy.resolve(order.withKey('rzp_test_mine')).keyId,
          'rzp_test_mine');
    });

    test('an order without a key uses the configured test key in development',
        () {
      const PaymentKeyPolicy dev = PaymentKeyPolicy(
        development: true,
        expectedTestKeyId: 'rzp_test_mine',
      );
      expect(dev.resolve(order.withKey('')).keyId, 'rzp_test_mine');
      const PaymentKeyPolicy production = PaymentKeyPolicy(development: false);
      expect(
        () => production.resolve(order.withKey('')),
        throwsA(isA<PaymentConfigurationException>()),
      );
    });

    test('production builds accept live keys and never show TEST MODE', () {
      const PaymentKeyPolicy production = PaymentKeyPolicy(development: false);
      expect(production.resolve(order.withKey('rzp_live_real')).keyId,
          'rzp_live_real');
      expect(production.isTestCheckout('rzp_test_backend'), isFalse);
    });
  });

  group('PaymentController', () {
    late _FakeRepository repository;
    late PaymentController controller;

    setUp(() {
      repository = _FakeRepository();
      controller = PaymentController(
        repository,
        keys: const PaymentKeyPolicy(development: true),
      );
    });

    Future<void> buy() => controller.purchase(
          bookId: 'book',
          bookTitle: 'Book',
          appName: 'Maanthirigam',
        );

    test('succeeds only after the backend confirms the entitlement', () async {
      repository.verifyResults.add(_captured);
      await buy();
      expect(controller.phase, PaymentPhase.success);
      expect(repository.openedWith?.amount, 9900);
    });

    test('a captured payment without entitlement is not a success', () async {
      repository.verifyResults.add(const PaymentStatusResult(
        orderId: 'order_1',
        status: 'CAPTURED',
        purchaseStatus: 'PENDING',
        entitled: false,
      ));
      await buy();
      expect(controller.phase, PaymentPhase.pending);
      expect(controller.canRetryPurchase, isFalse);
      expect(controller.canCheckStatus, isTrue);
    });

    test('a network error after payment waits for verification', () async {
      repository.verifyResults
        ..add(const NetworkException())
        ..add(_captured);
      await buy();
      expect(controller.phase, PaymentPhase.pending);
      expect(controller.paymentSubmitted, isTrue);
      expect(controller.canRetryPurchase, isFalse);

      await controller.refreshStatus();
      expect(controller.phase, PaymentPhase.success);
      expect(repository.checkouts, 1);
      expect(repository.verifies, 2);
    });

    test('an invalid signature fails without offering a new checkout',
        () async {
      repository.verifyResults.add(const ApiException(
        statusCode: 400,
        code: 'INVALID_PAYMENT_SIGNATURE',
        message: 'signature mismatch for sig_1',
      ));
      await buy();
      expect(controller.phase, PaymentPhase.failed);
      expect(controller.canRetryPurchase, isFalse);
      expect(controller.canCheckStatus, isTrue);
      expect(controller.message, isNot(contains('sig_1')));
    });

    test('a gateway failure keeps the book locked and allows a retry',
        () async {
      repository
        ..checkoutError =
            const CheckoutFailed('Your payment could not be completed.')
        ..statusResults.add(_status('FAILED'));
      await buy();
      expect(controller.phase, PaymentPhase.failed);
      expect(controller.canRetryPurchase, isTrue);
      expect(repository.verifies, 0);
    });

    test('cancelling checkout is not a failure and creates no entitlement',
        () async {
      repository.checkoutError = const CheckoutCancelled();
      await buy();
      expect(controller.phase, PaymentPhase.cancelled);
      expect(controller.message, PaymentController.cancelledMessage);
      expect(repository.verifies, 0);
    });

    test('BOOK_ALREADY_OWNED skips checkout', () async {
      repository.createError = const ApiException(
        statusCode: 409,
        code: 'BOOK_ALREADY_OWNED',
        message: 'owned',
      );
      await buy();
      expect(controller.phase, PaymentPhase.success);
      expect(controller.alreadyOwned, isTrue);
      expect(repository.checkouts, 0);
    });

    test('a live key in a development build never opens checkout', () async {
      repository.order = repository.order.withKey('rzp_live_x');
      await buy();
      expect(controller.phase, PaymentPhase.failed);
      expect(controller.message, PaymentController.unavailableMessage);
      expect(repository.checkouts, 0);
    });

    test('a gateway failure while creating the order reports unavailability',
        () async {
      repository.createError = const ApiException(
        statusCode: 500,
        code: 'PAYMENT_VERIFICATION_FAILED',
        message: 'Razorpay authentication failed',
      );
      await buy();
      expect(controller.phase, PaymentPhase.failed);
      expect(controller.message, PaymentController.unavailableMessage);
      expect(controller.canRetryPurchase, isTrue);
      expect(repository.checkouts, 0);
    });

    test('server error text is never shown', () async {
      repository.createError = const ApiException(
        statusCode: 500,
        code: 'INTERNAL_ERROR',
        message: 'Razorpay secret missing at https://internal.example',
      );
      await buy();
      expect(controller.message, isNot(contains('internal')));
      expect(controller.message, isNot(contains('secret')));
    });

    test('a second purchase while busy is ignored', () async {
      repository.verifyResults.add(_captured);
      final Future<void> first = buy();
      await buy();
      await first;
      expect(repository.orders, 1);
    });
  });
}

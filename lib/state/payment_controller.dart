import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../data/models/payment.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/payments_repository.dart';
import '../../data/services/payment_key_policy.dart';
import '../../data/services/razorpay_checkout.dart';

enum PaymentPhase {
  idle,
  creatingOrder,
  checkout,
  verifying,
  success,
  pending,
  failed,
  cancelled,
}

/// Purchase state machine: backend order → Razorpay checkout → backend
/// verification. Only a backend result (`CAPTURED` + `SUCCESS` + entitled,
/// or `BOOK_ALREADY_OWNED`) ever reaches [PaymentPhase.success]; a Razorpay
/// success callback alone never does.
///
/// Once Razorpay reported a payment for the current order
/// ([paymentSubmitted]), the only ways forward are verification and status
/// checks — never a new checkout — so a user cannot be charged twice.
class PaymentController extends ChangeNotifier {
  PaymentController(this._repository, {PaymentKeyPolicy? keys})
      : _keys = keys ?? PaymentKeyPolicy.fromEnvironment();

  final PaymentsRepository _repository;
  final PaymentKeyPolicy _keys;

  static const String failedMessage = 'Your payment could not be completed.';
  static const String verifyingMessage =
      'Your payment is still being verified. This can take a moment.';
  static const String cancelledMessage =
      "You can try again whenever you're ready.";
  static const String ownedMessage = 'This book is already in your library.';
  static const String unavailableMessage =
      'Payments are not available right now. Please try again later.';

  PaymentPhase phase = PaymentPhase.idle;

  /// User-facing explanation of the current phase; never a raw server or
  /// gateway string.
  String? message;
  String? activeBookId;
  CreateOrderResult? lastOrder;
  PaymentStatusResult? lastStatus;

  /// The backend reported the book as already owned (no payment was made).
  bool alreadyOwned = false;

  /// A status check is running for the current order.
  bool checkingStatus = false;

  CheckoutSuccess? _submitted;

  bool get busy =>
      phase == PaymentPhase.creatingOrder ||
      phase == PaymentPhase.checkout ||
      phase == PaymentPhase.verifying ||
      checkingStatus;

  /// Razorpay reported a payment for [lastOrder].
  bool get paymentSubmitted => _submitted != null;

  /// Starting over is offered only when no payment was made for this order.
  bool get canRetryPurchase =>
      !paymentSubmitted &&
      (phase == PaymentPhase.failed || phase == PaymentPhase.cancelled);

  /// Checking the order status helps once an order exists and the outcome is
  /// not final.
  bool get canCheckStatus =>
      lastOrder != null &&
      (phase == PaymentPhase.pending ||
          (phase == PaymentPhase.failed && paymentSubmitted));

  bool get isTestCheckout =>
      lastOrder != null && _keys.isTestCheckout(lastOrder!.keyId);

  Future<PaymentStatusResult?> purchase({
    required String bookId,
    required String bookTitle,
    required String appName,
    UserProfile? user,
  }) async {
    if (busy) return null;
    _start(bookId);

    final CreateOrderResult order;
    try {
      order = _keys.resolve(await _repository.createOrder(bookId));
    } on PaymentConfigurationException catch (error) {
      if (kDebugMode) debugPrint('Payment unavailable: ${error.reason}');
      return _fail(unavailableMessage);
    } on ApiException catch (error) {
      if (error.isAlreadyOwned) return _owned();
      if (error.isPaymentVerificationFailed || error.statusCode >= 500) {
        if (kDebugMode) debugPrint('Create order failed: ${error.code}');
        return _fail(unavailableMessage);
      }
      return _fail(paymentErrorMessage(error));
    } catch (_) {
      return _fail(failedMessage);
    }
    lastOrder = order;
    _setPhase(PaymentPhase.checkout);

    final CheckoutSuccess paid;
    try {
      paid = await _repository.openCheckout(
        order: order,
        bookTitle: bookTitle,
        appName: appName,
        user: user,
      );
    } on CheckoutCancelled {
      message = cancelledMessage;
      _setPhase(PaymentPhase.cancelled);
      return null;
    } on CheckoutFailed catch (error) {
      _fail(error.message);
      return _recoverAfterCheckoutError();
    } catch (_) {
      _fail(failedMessage);
      return _recoverAfterCheckoutError();
    }

    _submitted = paid;
    _setPhase(PaymentPhase.verifying);
    return _verify(paid);
  }

  /// Re-checks the current order: repeats verification when a payment was
  /// submitted (idempotent on the backend), otherwise reads the status.
  Future<PaymentStatusResult?> refreshStatus() async {
    final String orderId = lastOrder?.orderId ?? '';
    if (orderId.isEmpty || checkingStatus) return null;
    checkingStatus = true;
    notifyListeners();
    try {
      final CheckoutSuccess? paid = _submitted;
      if (paid != null) {
        try {
          return _apply(await _repository.verify(paid));
        } on ApiException catch (error) {
          if (error.isAlreadyOwned) return _owned();
          if (_isAuthError(error)) rethrow;
        }
      }
      return _apply(await _repository.status(orderId));
    } on ApiException catch (error) {
      if (error.isAlreadyOwned) return _owned();
      message = _isAuthError(error)
          ? error.userMessage
          : 'We could not check the payment right now. Please try again.';
      notifyListeners();
      return null;
    } catch (_) {
      message = 'We could not check the payment right now. Please try again.';
      notifyListeners();
      return null;
    } finally {
      checkingStatus = false;
      notifyListeners();
    }
  }

  void reset() {
    phase = PaymentPhase.idle;
    message = null;
    activeBookId = null;
    lastOrder = null;
    lastStatus = null;
    alreadyOwned = false;
    checkingStatus = false;
    _submitted = null;
    notifyListeners();
  }

  void _start(String bookId) {
    activeBookId = bookId;
    message = null;
    lastOrder = null;
    lastStatus = null;
    alreadyOwned = false;
    _submitted = null;
    _setPhase(PaymentPhase.creatingOrder);
  }

  Future<PaymentStatusResult?> _verify(CheckoutSuccess paid) async {
    try {
      return _apply(await _repository.verify(paid));
    } on ApiException catch (error) {
      if (error.isAlreadyOwned) return _owned();
      if (_isFinalVerificationError(error)) {
        return _fail(paymentErrorMessage(error));
      }
      // Network, timeout, not captured yet, gateway hiccup: the payment may
      // well be fine, so wait for the backend instead of failing.
      message = verifyingMessage;
      _setPhase(PaymentPhase.pending);
      return null;
    } catch (_) {
      message = verifyingMessage;
      _setPhase(PaymentPhase.pending);
      return null;
    }
  }

  PaymentStatusResult _apply(PaymentStatusResult result) {
    lastStatus = result;
    if (result.isCapturedSuccess) {
      message = null;
      _setPhase(PaymentPhase.success);
    } else if (result.isFinalFailure) {
      message = paymentSubmitted
          ? 'We could not confirm this payment. The book is not unlocked.'
          : failedMessage;
      _setPhase(PaymentPhase.failed);
    } else {
      message = verifyingMessage;
      _setPhase(PaymentPhase.pending);
    }
    return result;
  }

  /// A checkout error can follow a payment that still succeeded (rare);
  /// only a confirmed backend success changes the outcome.
  Future<PaymentStatusResult?> _recoverAfterCheckoutError() async {
    final String orderId = lastOrder?.orderId ?? '';
    if (orderId.isEmpty) return null;
    try {
      final PaymentStatusResult status = await _repository.status(orderId);
      if (status.isCapturedSuccess) return _apply(status);
    } catch (_) {
      // Keep the failure already shown.
    }
    return null;
  }

  PaymentStatusResult? _owned() {
    alreadyOwned = true;
    message = ownedMessage;
    _setPhase(PaymentPhase.success);
    return null;
  }

  PaymentStatusResult? _fail(String text) {
    message = text;
    _setPhase(PaymentPhase.failed);
    return null;
  }

  void _setPhase(PaymentPhase next) {
    phase = next;
    notifyListeners();
  }

  static bool _isAuthError(ApiException error) =>
      error.statusCode == 401 || error.isAuthenticationRequired;

  static bool _isFinalVerificationError(ApiException error) {
    switch (error.code) {
      case 'INVALID_PAYMENT_SIGNATURE':
      case 'PAYMENT_AMOUNT_MISMATCH':
      case 'PAYMENT_CURRENCY_MISMATCH':
      case 'PAYMENT_OWNERSHIP_MISMATCH':
      case 'PAYMENT_NOT_FOUND':
        return true;
      default:
        return _isAuthError(error);
    }
  }
}

/// Safe, user-facing text for payment-related backend errors. Raw server
/// messages, URLs, signatures and keys are never shown.
String paymentErrorMessage(ApiException error) {
  switch (error.code) {
    case 'BOOK_ALREADY_OWNED':
      return PaymentController.ownedMessage;
    case 'PAYMENT_NOT_CAPTURED':
      return 'Your payment is still being verified.';
    case 'PAYMENT_FAILED':
      return 'Payment could not be completed.';
    case 'NETWORK_ERROR':
      return 'Please check your internet connection and try again.';
    case 'TIMEOUT':
      return 'The connection timed out. Please try again.';
    case 'BOOK_NOT_PURCHASABLE':
      return 'This book is not available for purchase right now.';
    case 'BOOK_NOT_FOUND':
      return 'This title is no longer available.';
    case 'PAYMENT_NOT_FOUND':
      return 'We could not find this payment. Please start again.';
    case 'PAYMENT_OWNERSHIP_MISMATCH':
      return 'This payment belongs to a different account.';
    case 'INVALID_PAYMENT_SIGNATURE':
    case 'PAYMENT_AMOUNT_MISMATCH':
    case 'PAYMENT_CURRENCY_MISMATCH':
    case 'PAYMENT_VERIFICATION_FAILED':
      return 'We could not confirm this payment. The book is not unlocked.';
    case 'RATE_LIMITED':
    case 'TOKEN_EXPIRED':
    case 'TOKEN_INVALID':
    case 'UNAUTHENTICATED':
    case 'AUTHENTICATION_REQUIRED':
    case 'USER_INACTIVE':
      return error.userMessage;
    default:
      return 'Payment could not be completed. Please try again.';
  }
}

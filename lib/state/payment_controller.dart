import 'package:flutter/foundation.dart';

import '../../core/errors/api_exception.dart';
import '../../data/models/payment.dart';
import '../../data/models/user_profile.dart';
import '../../data/repositories/payments_repository.dart';
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

class PaymentController extends ChangeNotifier {
  PaymentController(this._repository);

  final PaymentsRepository _repository;

  PaymentPhase phase = PaymentPhase.idle;
  String? message;
  String? activeBookId;
  CreateOrderResult? lastOrder;
  PaymentStatusResult? lastStatus;

  bool get busy =>
      phase == PaymentPhase.creatingOrder ||
      phase == PaymentPhase.checkout ||
      phase == PaymentPhase.verifying;

  Future<PaymentStatusResult?> purchase({
    required String bookId,
    required String bookTitle,
    required String appName,
    UserProfile? user,
  }) async {
    if (busy) return null;
    activeBookId = bookId;
    phase = PaymentPhase.creatingOrder;
    message = null;
    notifyListeners();
    try {
      lastOrder = await _repository.createOrder(bookId);
      phase = PaymentPhase.checkout;
      notifyListeners();
      final CheckoutSuccess checkout = await _repository.openCheckout(
        order: lastOrder!,
        bookTitle: bookTitle,
        appName: appName,
        user: user,
      );
      phase = PaymentPhase.verifying;
      notifyListeners();
      lastStatus = await _repository.verify(checkout);
      if (lastStatus!.isCapturedSuccess) {
        phase = PaymentPhase.success;
        notifyListeners();
        return lastStatus;
      }
      if (lastStatus!.status.toUpperCase() == 'CREATED' ||
          lastStatus!.status.toUpperCase() == 'AUTHORIZED') {
        phase = PaymentPhase.pending;
        message = 'Payment is still processing. Please wait a moment.';
        notifyListeners();
        return lastStatus;
      }
      phase = PaymentPhase.failed;
      message = 'We could not confirm this payment. The book is not unlocked.';
      notifyListeners();
      return lastStatus;
    } on CheckoutCancelled {
      phase = PaymentPhase.cancelled;
      message = 'Payment was cancelled.';
      notifyListeners();
      return null;
    } on CheckoutFailed catch (error) {
      phase = PaymentPhase.failed;
      message = error.message;
      notifyListeners();
      return _tryRecoverStatus();
    } on ApiException catch (error) {
      if (error.isAlreadyOwned) {
        phase = PaymentPhase.success;
        message = error.userMessage;
        notifyListeners();
        return PaymentStatusResult(
          orderId: lastOrder?.orderId ?? '',
          status: 'CAPTURED',
          purchaseStatus: 'SUCCESS',
          entitled: true,
        );
      }
      if (error.isPaymentNotCaptured) {
        phase = PaymentPhase.pending;
        message = error.userMessage;
        notifyListeners();
        return _tryRecoverStatus();
      }
      phase = PaymentPhase.failed;
      message = error.userMessage;
      notifyListeners();
      if (error.isPaymentVerificationFailed) {
        return null;
      }
      return _tryRecoverStatus();
    } catch (_) {
      phase = PaymentPhase.failed;
      message = 'Payment could not be completed. Please try again.';
      notifyListeners();
      return _tryRecoverStatus();
    }
  }

  Future<PaymentStatusResult?> refreshStatus() async {
    final String? orderId = lastOrder?.orderId;
    if (orderId == null || orderId.isEmpty) return null;
    try {
      lastStatus = await _repository.status(orderId);
      if (lastStatus!.isCapturedSuccess) {
        phase = PaymentPhase.success;
      } else if (lastStatus!.status.toUpperCase() == 'FAILED') {
        phase = PaymentPhase.failed;
      } else {
        phase = PaymentPhase.pending;
      }
      notifyListeners();
      return lastStatus;
    } on ApiException catch (error) {
      message = error.userMessage;
      notifyListeners();
      return null;
    }
  }

  Future<PaymentStatusResult?> _tryRecoverStatus() async {
    if (lastOrder == null) return null;
    return refreshStatus();
  }

  void reset() {
    phase = PaymentPhase.idle;
    message = null;
    activeBookId = null;
    notifyListeners();
  }
}

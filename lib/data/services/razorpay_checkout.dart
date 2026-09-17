import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../models/payment.dart';
import '../models/user_profile.dart';

class CheckoutCancelled implements Exception {
  const CheckoutCancelled();
}

class CheckoutFailed implements Exception {
  const CheckoutFailed(this.message);
  final String message;
}

abstract class CheckoutGateway {
  Future<CheckoutSuccess> open({
    required CreateOrderResult order,
    required String bookTitle,
    required String appName,
    UserProfile? user,
  });

  void dispose();
}

class RazorpayCheckoutGateway implements CheckoutGateway {
  RazorpayCheckoutGateway({Razorpay? razorpay}) : _razorpay = razorpay ?? Razorpay();

  final Razorpay _razorpay;

  @override
  Future<CheckoutSuccess> open({
    required CreateOrderResult order,
    required String bookTitle,
    required String appName,
    UserProfile? user,
  }) {
    final Completer<CheckoutSuccess> completer = Completer<CheckoutSuccess>();

    void clear() {
      _razorpay.clear();
    }

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, (PaymentSuccessResponse response) {
      if (completer.isCompleted) return;
      completer.complete(
        CheckoutSuccess(
          razorpayOrderId: response.orderId ?? order.orderId,
          razorpayPaymentId: response.paymentId ?? '',
          razorpaySignature: response.signature ?? '',
        ),
      );
      clear();
    });
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, (PaymentFailureResponse response) {
      if (completer.isCompleted) return;
      final String message = response.message ?? 'Payment was not completed.';
      if (message.toLowerCase().contains('cancel')) {
        completer.completeError(const CheckoutCancelled());
      } else {
        completer.completeError(CheckoutFailed(message));
      }
      clear();
    });
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (_) {});

    _razorpay.open(<String, Object?>{
      'key': order.keyId,
      'amount': order.amount,
      'currency': order.currency,
      'order_id': order.orderId,
      'name': appName,
      'description': bookTitle,
      'prefill': <String, String>{
        if (user != null) 'email': user.email,
        if (user != null) 'name': user.name,
      },
      'theme': <String, String>{'color': '#C9A36A'},
    });

    return completer.future;
  }

  @override
  void dispose() {
    _razorpay.clear();
  }
}

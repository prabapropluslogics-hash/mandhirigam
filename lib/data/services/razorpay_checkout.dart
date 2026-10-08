import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';

import '../models/payment.dart';
import '../models/user_profile.dart';

class CheckoutCancelled implements Exception {
  const CheckoutCancelled();
}

/// Checkout ended without a payment. [message] is safe to show to users.
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

/// Razorpay Standard Checkout through the official `razorpay_flutter`
/// plugin. Every plugin event completes the returned future exactly once, so
/// a purchase can never stay waiting. Only the public key reaches the device.
class RazorpayCheckoutGateway implements CheckoutGateway {
  RazorpayCheckoutGateway({Razorpay? razorpay})
      : _razorpay = razorpay ?? Razorpay();

  final Razorpay _razorpay;

  static const String _brandColor = '#C9A36A';
  static const String failedMessage = 'Your payment could not be completed.';
  static const String networkMessage =
      'Please check your internet connection and try again.';
  static const String walletMessage =
      'This payment method is not supported here. Please choose another method.';

  @override
  Future<CheckoutSuccess> open({
    required CreateOrderResult order,
    required String bookTitle,
    required String appName,
    UserProfile? user,
  }) {
    final Completer<CheckoutSuccess> completer = Completer<CheckoutSuccess>();

    void finish(void Function() complete) {
      if (completer.isCompleted) return;
      complete();
      _razorpay.clear();
    }

    _razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS,
        (PaymentSuccessResponse response) {
      finish(
        () => completer.complete(
          CheckoutSuccess(
            razorpayOrderId: response.orderId ?? order.orderId,
            razorpayPaymentId: response.paymentId ?? '',
            razorpaySignature: response.signature ?? '',
          ),
        ),
      );
    });
    _razorpay.on(Razorpay.EVENT_PAYMENT_ERROR,
        (PaymentFailureResponse response) {
      final Object error;
      if (response.code == Razorpay.PAYMENT_CANCELLED ||
          (response.message ?? '').toLowerCase().contains('cancel')) {
        error = const CheckoutCancelled();
      } else if (response.code == Razorpay.NETWORK_ERROR) {
        error = const CheckoutFailed(networkMessage);
      } else {
        error = const CheckoutFailed(failedMessage);
      }
      finish(() => completer.completeError(error));
    });
    _razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, (ExternalWalletResponse _) {
      finish(
          () => completer.completeError(const CheckoutFailed(walletMessage)));
    });

    final String email = user?.email.trim() ?? '';
    final String name = user?.name.trim() ?? '';
    try {
      _razorpay.open(<String, Object?>{
        'key': order.keyId,
        'order_id': order.orderId,
        'amount': order.amount,
        'currency': order.currency,
        'name': appName,
        'description': bookTitle,
        if (email.isNotEmpty || name.isNotEmpty)
          'prefill': <String, String>{
            if (email.isNotEmpty) 'email': email,
            if (name.isNotEmpty) 'name': name,
          },
        'theme': <String, String>{'color': _brandColor},
      });
    } catch (_) {
      finish(
          () => completer.completeError(const CheckoutFailed(failedMessage)));
    }

    return completer.future;
  }

  @override
  void dispose() {
    _razorpay.clear();
  }
}

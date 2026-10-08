import '../../core/config/app_env.dart';
import '../models/payment.dart';

enum PaymentKeyMode { test, live, unknown }

/// The order's key cannot be used for checkout in this build.
class PaymentConfigurationException implements Exception {
  const PaymentConfigurationException(this.reason);

  /// For developers only; never shown to users.
  final String reason;

  @override
  String toString() => 'PaymentConfigurationException($reason)';
}

/// Decides which public Razorpay Key ID opens checkout for a backend order.
///
/// The backend creates the order with its own key pair and returns the
/// matching public `keyId`; that key is always preferred. Development builds
/// add two guards: they never open a live checkout, and when
/// [expectedTestKeyId] is set the backend key must equal it.
class PaymentKeyPolicy {
  const PaymentKeyPolicy({
    required this.development,
    this.expectedTestKeyId = '',
  });

  factory PaymentKeyPolicy.fromEnvironment() => PaymentKeyPolicy(
        development: AppEnv.isDevelopment,
        expectedTestKeyId: AppEnv.razorpayTestKeyId.trim(),
      );

  final bool development;
  final String expectedTestKeyId;

  static PaymentKeyMode modeOf(String keyId) {
    if (keyId.startsWith('rzp_test_')) return PaymentKeyMode.test;
    if (keyId.startsWith('rzp_live_')) return PaymentKeyMode.live;
    return PaymentKeyMode.unknown;
  }

  /// Returns [order] with the key to use, or throws
  /// [PaymentConfigurationException].
  CreateOrderResult resolve(CreateOrderResult order) {
    final String key = order.keyId.trim();
    if (order.orderId.trim().isEmpty || order.amount <= 0) {
      throw const PaymentConfigurationException('Order is incomplete.');
    }
    if (key.isEmpty) {
      if (development && modeOf(expectedTestKeyId) == PaymentKeyMode.test) {
        return order.withKey(expectedTestKeyId);
      }
      throw const PaymentConfigurationException('Backend returned no keyId.');
    }
    if (development) {
      if (modeOf(key) == PaymentKeyMode.live) {
        throw const PaymentConfigurationException(
          'Live key refused in a development build.',
        );
      }
      if (expectedTestKeyId.isNotEmpty && key != expectedTestKeyId) {
        throw const PaymentConfigurationException(
          'Backend keyId differs from RAZORPAY_TEST_KEY_ID.',
        );
      }
    }
    return key == order.keyId ? order : order.withKey(key);
  }

  /// Development builds paying with a test key show a TEST MODE marker.
  bool isTestCheckout(String keyId) =>
      development && modeOf(keyId) == PaymentKeyMode.test;
}

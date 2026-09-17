import '../../core/utils/json_map.dart';

class CreateOrderResult {
  const CreateOrderResult({
    required this.orderId,
    required this.amount,
    required this.currency,
    required this.keyId,
  });

  final String orderId;
  final int amount;
  final String currency;
  final String keyId;

  factory CreateOrderResult.fromJson(Map<String, dynamic> json) {
    return CreateOrderResult(
      orderId: asString(json['orderId']),
      amount: asInt(json['amount']),
      currency: asString(json['currency'], 'INR'),
      keyId: asString(json['keyId']),
    );
  }
}

class PaymentStatusResult {
  const PaymentStatusResult({
    required this.orderId,
    required this.status,
    required this.purchaseStatus,
    required this.entitled,
  });

  final String orderId;
  final String status;
  final String purchaseStatus;
  final bool entitled;

  bool get isCapturedSuccess =>
      status.toUpperCase() == 'CAPTURED' &&
      purchaseStatus.toUpperCase() == 'SUCCESS' &&
      entitled;

  factory PaymentStatusResult.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResult(
      orderId: asString(json['orderId']),
      status: asString(json['status']),
      purchaseStatus: asString(json['purchaseStatus']),
      entitled: asBool(json['entitled']),
    );
  }
}

class CheckoutSuccess {
  const CheckoutSuccess({
    required this.razorpayOrderId,
    required this.razorpayPaymentId,
    required this.razorpaySignature,
  });

  final String razorpayOrderId;
  final String razorpayPaymentId;
  final String razorpaySignature;
}

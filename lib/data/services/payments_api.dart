import '../../core/network/api_client.dart';
import '../../core/utils/json_map.dart';
import '../models/payment.dart';

class PaymentsApi {
  PaymentsApi(this._client);

  final ApiClient _client;

  Future<CreateOrderResult> createOrder(String bookId) async {
    final envelope = await _client.postAuthorized(
      '/payments/create-order',
      body: <String, dynamic>{'bookId': bookId},
    );
    return CreateOrderResult.fromJson(asJsonMap(envelope.data));
  }

  Future<PaymentStatusResult> verify(CheckoutSuccess payload) async {
    final envelope = await _client.postAuthorized(
      '/payments/verify',
      body: <String, dynamic>{
        'razorpayOrderId': payload.razorpayOrderId,
        'razorpayPaymentId': payload.razorpayPaymentId,
        'razorpaySignature': payload.razorpaySignature,
      },
    );
    return PaymentStatusResult.fromJson(asJsonMap(envelope.data));
  }

  Future<PaymentStatusResult> status(String orderId) async {
    final envelope = await _client.getAuthorized('/payments/$orderId/status');
    return PaymentStatusResult.fromJson(asJsonMap(envelope.data));
  }
}

import '../models/payment.dart';
import '../models/user_profile.dart';
import '../services/payments_api.dart';
import '../services/razorpay_checkout.dart';

class PaymentsRepository {
  PaymentsRepository({
    required PaymentsApi api,
    required CheckoutGateway checkout,
  })  : _api = api,
        _checkout = checkout;

  final PaymentsApi _api;
  final CheckoutGateway _checkout;

  Future<CreateOrderResult> createOrder(String bookId) => _api.createOrder(bookId);

  Future<CheckoutSuccess> openCheckout({
    required CreateOrderResult order,
    required String bookTitle,
    required String appName,
    UserProfile? user,
  }) {
    return _checkout.open(
      order: order,
      bookTitle: bookTitle,
      appName: appName,
      user: user,
    );
  }

  Future<PaymentStatusResult> verify(CheckoutSuccess payload) => _api.verify(payload);

  Future<PaymentStatusResult> status(String orderId) => _api.status(orderId);
}

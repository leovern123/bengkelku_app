import '../models/payment_model.dart';
import 'api_service.dart';

class PaymentService {
  static Future<PaymentModel> create({
    required String orderId,
    required String paymentMethod,
    required double paidAmount,
  }) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.post(
      '/payments',
      data: {
        'order_id': orderId,
        'payment_method': paymentMethod,
        'paid_amount': paidAmount,
      },
      options: options,
    );
    return PaymentModel.fromJson(res.data['data']);
  }
}

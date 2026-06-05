import '../models/order_model.dart';
import '../models/order_detail_model.dart';
import 'api_service.dart';

class OrderService {
  static Future<List<OrderModel>> getAll() async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.get('/orders', options: options);
    if (res.data['success'] == true) {
      return (res.data['data'] as List)
          .map((e) => OrderModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<OrderModel> getById(String id) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.get('/orders/$id', options: options);
    return OrderModel.fromJson(res.data['data']);
  }

  static Future<OrderModel> create({
    required String customerId,
    required String vehicleId,
    required String userId,
    String? mechanicId,
  }) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.post(
      '/orders',
      data: {
        'customer_id': customerId,
        'vehicle_id': vehicleId,
        'user_id': userId,
        if (mechanicId != null) 'mechanic_id': mechanicId,
      },
      options: options,
    );
    return OrderModel.fromJson(res.data['data']);
  }

  static Future<OrderModel> process(String id) async {
    final options = await ApiService.authOptions();
    final res =
        await ApiService.dio.post('/orders/$id/process', options: options);
    return OrderModel.fromJson(res.data['data']);
  }

  static Future<OrderModel> complete(String id) async {
    final options = await ApiService.authOptions();
    final res =
        await ApiService.dio.post('/orders/$id/complete', options: options);
    return OrderModel.fromJson(res.data['data']);
  }

  static Future<OrderModel> cancel(String id) async {
    final options = await ApiService.authOptions();
    final res =
        await ApiService.dio.post('/orders/$id/cancel', options: options);
    return OrderModel.fromJson(res.data['data']);
  }

  static Future<void> delete(String id) async {
    final options = await ApiService.authOptions();
    await ApiService.dio.delete('/orders/$id', options: options);
  }

  // Order Details
  static Future<OrderDetailModel> addDetail({
    required String orderId,
    required String itemId,
    required int quantity,
  }) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.post(
      '/order-details',
      data: {
        'order_id': orderId,
        'item_id': itemId,
        'quantity': quantity,
      },
      options: options,
    );
    return OrderDetailModel.fromJson(res.data['data']);
  }

  static Future<OrderDetailModel> updateDetail(
      String detailId, int quantity) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.put(
      '/order-details/$detailId',
      data: {'quantity': quantity},
      options: options,
    );
    return OrderDetailModel.fromJson(res.data['data']);
  }

  static Future<void> deleteDetail(String detailId) async {
    final options = await ApiService.authOptions();
    await ApiService.dio.delete('/order-details/$detailId', options: options);
  }
}

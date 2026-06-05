import '../models/customer_model.dart';
import 'api_service.dart';

class CustomerService {
  static Future<List<CustomerModel>> getAll() async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.get('/customers', options: options);
    if (res.data['success'] == true) {
      return (res.data['data'] as List)
          .map((e) => CustomerModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<CustomerModel> create(String name) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.post(
      '/customers',
      data: {'customer_name': name},
      options: options,
    );
    return CustomerModel.fromJson(res.data['data']);
  }

  static Future<CustomerModel> update(String id, String name) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.put(
      '/customers/$id',
      data: {'customer_name': name},
      options: options,
    );
    return CustomerModel.fromJson(res.data['data']);
  }

  static Future<void> delete(String id) async {
    final options = await ApiService.authOptions();
    await ApiService.dio.delete('/customers/$id', options: options);
  }
}

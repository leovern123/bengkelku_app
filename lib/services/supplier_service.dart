import '../models/supplier_model.dart';
import 'api_service.dart';

class SupplierService {
  static Future<List<SupplierModel>> getAll() async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.get('/suppliers', options: options);
    if (res.data['success'] == true) {
      return (res.data['data'] as List)
          .map((e) => SupplierModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<SupplierModel> create(Map<String, dynamic> data) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.post('/suppliers', data: data, options: options);
    return SupplierModel.fromJson(res.data['data']);
  }

  static Future<SupplierModel> update(String id, Map<String, dynamic> data) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.put('/suppliers/$id', data: data, options: options);
    return SupplierModel.fromJson(res.data['data']);
  }

  static Future<void> delete(String id) async {
    final options = await ApiService.authOptions();
    await ApiService.dio.delete('/suppliers/$id', options: options);
  }
}

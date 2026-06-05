import '../models/vehicle_model.dart';
import 'api_service.dart';

class VehicleService {
  static Future<List<VehicleModel>> getAll() async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.get('/vehicles', options: options);
    if (res.data['success'] == true) {
      return (res.data['data'] as List)
          .map((e) => VehicleModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<List<VehicleModel>> getByCustomer(String customerId) async {
    final all = await getAll();
    return all.where((v) => v.customerId == customerId).toList();
  }

  static Future<VehicleModel> create(Map<String, dynamic> data) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.post('/vehicles', data: data, options: options);
    return VehicleModel.fromJson(res.data['data']);
  }

  static Future<VehicleModel> update(String id, Map<String, dynamic> data) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.put('/vehicles/$id', data: data, options: options);
    return VehicleModel.fromJson(res.data['data']);
  }

  static Future<void> delete(String id) async {
    final options = await ApiService.authOptions();
    await ApiService.dio.delete('/vehicles/$id', options: options);
  }
}

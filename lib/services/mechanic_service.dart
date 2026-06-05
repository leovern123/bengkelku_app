import '../models/mechanic_model.dart';
import 'api_service.dart';

class MechanicService {
  static Future<List<MechanicModel>> getAll() async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.get('/mechanics', options: options);
    if (res.data['success'] == true) {
      return (res.data['data'] as List)
          .map((e) => MechanicModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<MechanicModel> create(Map<String, dynamic> data) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.post('/mechanics', data: data, options: options);
    return MechanicModel.fromJson(res.data['data']);
  }

  static Future<MechanicModel> update(String id, Map<String, dynamic> data) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.put('/mechanics/$id', data: data, options: options);
    return MechanicModel.fromJson(res.data['data']);
  }

  static Future<void> delete(String id) async {
    final options = await ApiService.authOptions();
    await ApiService.dio.delete('/mechanics/$id', options: options);
  }
}

import 'dart:convert';
import 'package:image_picker/image_picker.dart';
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

  static Future<MechanicModel> create(Map<String, dynamic> data, {XFile? photo}) async {
    final options = await ApiService.authOptions();
    final payload = Map<String, dynamic>.from(data);
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      payload['photo_base64'] = base64Encode(bytes);
      payload['photo_name'] = photo.name;
    }
    final res = await ApiService.dio.post('/mechanics', data: payload, options: options);
    return MechanicModel.fromJson(res.data['data']);
  }

  static Future<MechanicModel> update(String id, Map<String, dynamic> data, {XFile? photo}) async {
    final options = await ApiService.authOptions();
    final payload = Map<String, dynamic>.from(data);
    if (photo != null) {
      final bytes = await photo.readAsBytes();
      final b64 = base64Encode(bytes);
      // ignore: avoid_print
      print('[MechanicService] photo bytes: ${bytes.length}, base64 length: ${b64.length}');
      payload['photo_base64'] = b64;
      payload['photo_name'] = photo.name;
    }
    final res = await ApiService.dio.put('/mechanics/$id', data: payload, options: options);
    return MechanicModel.fromJson(res.data['data']);
  }

  static Future<void> delete(String id) async {
    final options = await ApiService.authOptions();
    await ApiService.dio.delete('/mechanics/$id', options: options);
  }
}

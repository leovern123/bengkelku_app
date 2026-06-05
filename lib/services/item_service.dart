import '../models/item_model.dart';
import 'api_service.dart';

class ItemService {
  static Future<List<ItemModel>> getAll() async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.get('/items', options: options);
    if (res.data['success'] == true) {
      return (res.data['data'] as List)
          .map((e) => ItemModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<ItemModel> create(Map<String, dynamic> data) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.post(
      '/items',
      data: data,
      options: options,
    );
    return ItemModel.fromJson(res.data['data']);
  }

  static Future<ItemModel> update(String id, Map<String, dynamic> data) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.put(
      '/items/$id',
      data: data,
      options: options,
    );
    return ItemModel.fromJson(res.data['data']);
  }

  static Future<void> delete(String id) async {
    final options = await ApiService.authOptions();
    await ApiService.dio.delete('/items/$id', options: options);
  }

  static Future<List<Map<String, dynamic>>> getCategories() async {
    try {
      final options = await ApiService.authOptions();
      final res = await ApiService.dio.get('/item-categories', options: options);
      if (res.data['success'] == true) {
        return List<Map<String, dynamic>>.from(res.data['data']);
      }
    } catch (_) {}
    return [];
  }
}

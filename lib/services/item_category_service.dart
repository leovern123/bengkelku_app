import '../models/category_model.dart';
import 'api_service.dart';

class ItemCategoryService {
  static Future<List<CategoryModel>> getAll() async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.get('/item-categories', options: options);
    if (res.data['success'] == true) {
      return (res.data['data'] as List)
          .map((e) => CategoryModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<CategoryModel> create(String name, int itemTypeId) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.post(
      '/item-categories',
      data: {'category_name': name, 'item_type_id': itemTypeId},
      options: options,
    );
    return CategoryModel.fromJson(res.data['data']);
  }

  static Future<CategoryModel> update(int id, String name) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.put(
      '/item-categories/$id',
      data: {'category_name': name},
      options: options,
    );
    return CategoryModel.fromJson(res.data['data']);
  }

  static Future<void> delete(int id) async {
    final options = await ApiService.authOptions();
    await ApiService.dio.delete('/item-categories/$id', options: options);
  }
}

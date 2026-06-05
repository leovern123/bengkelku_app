import '../models/item_type_model.dart';
import 'api_service.dart';

class ItemTypeService {
  static Future<List<ItemTypeModel>> getAll() async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.get('/item-types', options: options);
    if (res.data['success'] == true) {
      return (res.data['data'] as List)
          .map((e) => ItemTypeModel.fromJson(e))
          .toList();
    }
    return [];
  }
}

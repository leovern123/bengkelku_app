class CategoryModel {
  final int itemCategoryId;
  final int itemTypeId;
  final String categoryName;

  CategoryModel({
    required this.itemCategoryId,
    required this.itemTypeId,
    required this.categoryName,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json) => CategoryModel(
        itemCategoryId: int.parse(json['item_category_id'].toString()),
        itemTypeId: int.parse((json['item_type_id'] ?? 1).toString()),
        categoryName: json['category_name']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'item_category_id': itemCategoryId,
        'item_type_id': itemTypeId,
        'category_name': categoryName,
      };
}

class ItemModel {
  final String itemId;
  final int? itemCategoryId;
  final int? itemTypeId;
  final String? supplierId;
  final String itemName;
  final double purchasePrice;
  final double sellingPrice;
  final int? stock;
  final String? image;
  final String? createdAt;
  final String? updatedAt;

  ItemModel({
    required this.itemId,
    this.itemCategoryId,
    this.itemTypeId,
    this.supplierId,
    required this.itemName,
    required this.purchasePrice,
    required this.sellingPrice,
    this.stock,
    this.image,
    this.createdAt,
    this.updatedAt,
  });

  factory ItemModel.fromJson(Map<String, dynamic> json) => ItemModel(
        itemId: json['item_id']?.toString() ?? '',
        itemCategoryId: json['item_category_id'] != null ? int.tryParse(json['item_category_id'].toString()) : null,
        itemTypeId: json['item_type_id'] != null ? int.tryParse(json['item_type_id'].toString()) : null,
        supplierId: json['supplier_id']?.toString(),
        itemName: json['item_name']?.toString() ?? '',
        purchasePrice: double.tryParse(json['purchase_price']?.toString() ?? '0') ?? 0,
        sellingPrice: double.tryParse(json['selling_price']?.toString() ?? '0') ?? 0,
        stock: json['stock'] != null ? int.tryParse(json['stock'].toString()) : null,
        image: json['image']?.toString(),
        createdAt: json['created_at']?.toString(),
        updatedAt: json['updated_at']?.toString(),
      );

  bool get isService => stock == null;
  bool get isLowStock => stock != null && stock! <= 5;
}

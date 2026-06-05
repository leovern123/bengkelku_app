class ItemTypeModel {
  final int itemTypeId;
  final String typeName;

  ItemTypeModel({
    required this.itemTypeId,
    required this.typeName,
  });

  factory ItemTypeModel.fromJson(Map<String, dynamic> json) => ItemTypeModel(
        itemTypeId: int.parse(json['item_type_id'].toString()),
        typeName: json['type_name']?.toString() ?? '',
      );

  Map<String, dynamic> toJson() => {
        'item_type_id': itemTypeId,
        'type_name': typeName,
      };
}

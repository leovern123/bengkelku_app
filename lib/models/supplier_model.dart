class SupplierModel {
  final String supplierId;
  final String supplierName;
  final String? phoneNumber;
  final String? address;
  final String? notes;
  final String? updatedAt;

  SupplierModel({
    required this.supplierId,
    required this.supplierName,
    this.phoneNumber,
    this.address,
    this.notes,
    this.updatedAt,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) => SupplierModel(
        supplierId: json['supplier_id']?.toString() ?? '',
        supplierName: json['supplier_name']?.toString() ?? '',
        phoneNumber: json['phone_number']?.toString(),
        address: json['address']?.toString(),
        notes: json['notes']?.toString(),
        updatedAt: json['updated_at']?.toString(),
      );
}

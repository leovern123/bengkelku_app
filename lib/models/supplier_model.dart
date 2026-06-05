class SupplierModel {
  final String supplierId;
  final String supplierName;
  final String? phoneNumber;
  final String? address;

  SupplierModel({
    required this.supplierId,
    required this.supplierName,
    this.phoneNumber,
    this.address,
  });

  factory SupplierModel.fromJson(Map<String, dynamic> json) => SupplierModel(
        supplierId: json['supplier_id']?.toString() ?? '',
        supplierName: json['supplier_name']?.toString() ?? '',
        phoneNumber: json['phone_number']?.toString(),
        address: json['address']?.toString(),
      );
}

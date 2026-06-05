class CustomerModel {
  final String customerId;
  final String customerName;
  final String? createdAt;
  final String? updatedAt;

  CustomerModel({
    required this.customerId,
    required this.customerName,
    this.createdAt,
    this.updatedAt,
  });

  factory CustomerModel.fromJson(Map<String, dynamic> json) => CustomerModel(
        customerId: json['customer_id'],
        customerName: json['customer_name'],
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
      );

  Map<String, dynamic> toJson() => {
        'customer_id': customerId,
        'customer_name': customerName,
      };
}

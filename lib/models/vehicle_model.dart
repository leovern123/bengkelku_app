import 'customer_model.dart';

class VehicleModel {
  final String vehicleId;
  final String customerId;
  final String licensePlate;
  final String? brand;
  final String? model;
  final String? createdAt;
  final String? updatedAt;
  final CustomerModel? customer;

  VehicleModel({
    required this.vehicleId,
    required this.customerId,
    required this.licensePlate,
    this.brand,
    this.model,
    this.createdAt,
    this.updatedAt,
    this.customer,
  });

  factory VehicleModel.fromJson(Map<String, dynamic> json) => VehicleModel(
        vehicleId: json['vehicle_id'],
        customerId: json['customer_id'],
        licensePlate: json['license_plate'],
        brand: json['brand'],
        model: json['model'],
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
        customer: json['customer'] != null
            ? CustomerModel.fromJson(json['customer'])
            : null,
      );

  String get displayName =>
      '$licensePlate${brand != null ? ' - $brand' : ''}${model != null ? ' $model' : ''}';
}

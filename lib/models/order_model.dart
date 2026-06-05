import 'customer_model.dart';
import 'vehicle_model.dart';
import 'order_detail_model.dart';
import 'payment_model.dart';

class OrderModel {
  final String orderId;
  final String orderCode;
  final String customerId;
  final String vehicleId;
  final String userId;
  final String? mechanicId;
  final String orderStatus;
  final double totalAmount;
  final String? createdAt;
  final String? updatedAt;
  final CustomerModel? customer;
  final VehicleModel? vehicle;
  final List<OrderDetailModel> details;
  final PaymentModel? payment;

  OrderModel({
    required this.orderId,
    required this.orderCode,
    required this.customerId,
    required this.vehicleId,
    required this.userId,
    this.mechanicId,
    required this.orderStatus,
    required this.totalAmount,
    this.createdAt,
    this.updatedAt,
    this.customer,
    this.vehicle,
    this.details = const [],
    this.payment,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        orderId: json['order_id'],
        orderCode: json['order_code'],
        customerId: json['customer_id'],
        vehicleId: json['vehicle_id'],
        userId: json['user_id'],
        mechanicId: json['mechanic_id'],
        orderStatus: json['order_status'],
        totalAmount: double.parse(json['total_amount'].toString()),
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
        customer: json['customer'] != null
            ? CustomerModel.fromJson(json['customer'])
            : null,
        vehicle: json['vehicle'] != null
            ? VehicleModel.fromJson(json['vehicle'])
            : null,
        details: json['details'] != null
            ? (json['details'] as List)
                .map((d) => OrderDetailModel.fromJson(d))
                .toList()
            : [],
        payment: json['payment'] != null
            ? PaymentModel.fromJson(json['payment'])
            : null,
      );

  bool get isPending => orderStatus == 'pending';
  bool get isProcess => orderStatus == 'process';
  bool get isCompleted => orderStatus == 'completed';
  bool get isCancelled => orderStatus == 'cancelled';
  bool get canAddItems => isPending || isProcess;
  bool get canPay => (isPending || isProcess) && payment == null;
}

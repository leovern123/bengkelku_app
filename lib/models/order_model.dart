import 'customer_model.dart';
import 'vehicle_model.dart';
import 'mechanic_model.dart';
import 'order_detail_model.dart';
import 'payment_model.dart';

class OrderModel {
  final String orderId;
  final String orderCode;
  final String transactionType; // 'service' | 'product_sale'
  final String? customerId;
  final String? vehicleId;
  final String userId;
  final String? mechanicId;
  final String orderStatus;
  final String? cancelReason;
  final double totalAmount;
  final String? createdAt;
  final String? updatedAt;
  final CustomerModel? customer;
  final VehicleModel? vehicle;
  final MechanicModel? mechanic;
  final List<OrderDetailModel> details;
  final PaymentModel? payment;

  OrderModel({
    required this.orderId,
    required this.orderCode,
    this.transactionType = 'service',
    this.customerId,
    this.vehicleId,
    required this.userId,
    this.mechanicId,
    required this.orderStatus,
    this.cancelReason,
    required this.totalAmount,
    this.createdAt,
    this.updatedAt,
    this.customer,
    this.vehicle,
    this.mechanic,
    this.details = const [],
    this.payment,
  });

  factory OrderModel.fromJson(Map<String, dynamic> json) => OrderModel(
        orderId: json['order_id'],
        orderCode: json['order_code'],
        transactionType: json['transaction_type']?.toString() ?? 'service',
        customerId: json['customer_id']?.toString(),
        vehicleId: json['vehicle_id']?.toString(),
        userId: json['user_id'],
        mechanicId: json['mechanic_id'],
        orderStatus: json['order_status'],
        cancelReason: json['cancel_reason']?.toString(),
        totalAmount: double.parse(json['total_amount'].toString()),
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
        customer: json['customer'] != null
            ? CustomerModel.fromJson(json['customer'])
            : null,
        vehicle: json['vehicle'] != null
            ? VehicleModel.fromJson(json['vehicle'])
            : null,
        mechanic: json['mechanic'] != null
            ? MechanicModel.fromJson(json['mechanic'])
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

  bool get isService => transactionType == 'service';
  bool get isProductSale => transactionType == 'product_sale';

  bool get isPending => orderStatus == 'pending';
  bool get isProcess => orderStatus == 'process';
  bool get isCompleted => orderStatus == 'completed';
  bool get isCancelled => orderStatus == 'cancelled';
  bool get canAddItems => isService && (isPending || isProcess);
  bool get canProcess => isService && isPending;
  bool get canPay => isProcess && payment == null;
  bool get canCancel => isPending;
}

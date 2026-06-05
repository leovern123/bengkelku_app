class PaymentModel {
  final String paymentId;
  final String orderId;
  final String paymentMethod;
  final String paymentStatus;
  final double paidAmount;
  final double changeAmount;
  final String? paymentDate;
  final String? createdAt;
  final String? updatedAt;

  PaymentModel({
    required this.paymentId,
    required this.orderId,
    required this.paymentMethod,
    required this.paymentStatus,
    required this.paidAmount,
    required this.changeAmount,
    this.paymentDate,
    this.createdAt,
    this.updatedAt,
  });

  factory PaymentModel.fromJson(Map<String, dynamic> json) => PaymentModel(
        paymentId: json['payment_id'],
        orderId: json['order_id'],
        paymentMethod: json['payment_method'],
        paymentStatus: json['payment_status'],
        paidAmount: double.parse(json['paid_amount'].toString()),
        changeAmount: double.parse(json['change_amount'].toString()),
        paymentDate: json['payment_date'],
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
      );
}

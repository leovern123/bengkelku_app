import 'item_model.dart';

class OrderDetailModel {
  final String orderDetailId;
  final String orderId;
  final String itemId;
  final int quantity;
  final double purchasePriceAtTransaction;
  final double sellingPriceAtTransaction;
  final double subtotal;
  final String? createdAt;
  final String? updatedAt;
  final ItemModel? item;

  OrderDetailModel({
    required this.orderDetailId,
    required this.orderId,
    required this.itemId,
    required this.quantity,
    required this.purchasePriceAtTransaction,
    required this.sellingPriceAtTransaction,
    required this.subtotal,
    this.createdAt,
    this.updatedAt,
    this.item,
  });

  factory OrderDetailModel.fromJson(Map<String, dynamic> json) =>
      OrderDetailModel(
        orderDetailId: json['order_detail_id'],
        orderId: json['order_id'],
        itemId: json['item_id'],
        quantity: json['quantity'],
        purchasePriceAtTransaction:
            double.parse(json['purchase_price_at_transaction'].toString()),
        sellingPriceAtTransaction:
            double.parse(json['selling_price_at_transaction'].toString()),
        subtotal: double.parse(json['subtotal'].toString()),
        createdAt: json['created_at'],
        updatedAt: json['updated_at'],
        item: json['item'] != null ? ItemModel.fromJson(json['item']) : null,
      );
}

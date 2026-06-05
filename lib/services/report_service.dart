import 'api_service.dart';

class ReportSummary {
  final double totalIncome;
  final double totalModal;
  final double totalExpenses;
  final double labaKotor;
  final double labaBersih;
  final Map<String, int> orders;

  ReportSummary({
    required this.totalIncome,
    required this.totalModal,
    required this.totalExpenses,
    required this.labaKotor,
    required this.labaBersih,
    required this.orders,
  });

  factory ReportSummary.fromJson(Map<String, dynamic> json) => ReportSummary(
        totalIncome: (json['total_income'] as num).toDouble(),
        totalModal: (json['total_modal'] as num).toDouble(),
        totalExpenses: (json['total_expenses'] as num).toDouble(),
        labaKotor: (json['laba_kotor'] as num).toDouble(),
        labaBersih: (json['laba_bersih'] as num).toDouble(),
        orders: Map<String, int>.from(json['orders'] ?? {}),
      );
}

class ChartPoint {
  final String label;
  final double income;
  final double modal;
  final double expenses;

  ChartPoint({
    required this.label,
    required this.income,
    required this.modal,
    required this.expenses,
  });

  double get labaBersih => income - modal - expenses;

  factory ChartPoint.fromJson(Map<String, dynamic> j) => ChartPoint(
        label: j['label'].toString(),
        income: (j['income'] as num).toDouble(),
        modal: (j['modal'] as num).toDouble(),
        expenses: (j['expenses'] as num).toDouble(),
      );
}

class TransactionReport {
  final String orderId;
  final String orderCode;
  final String customerName;
  final String vehiclePlate;
  final double totalAmount;
  final String orderStatus;
  final int itemCount;
  final bool isPaid;
  final String? createdAt;
  final String? createdByName;

  TransactionReport({
    required this.orderId,
    required this.orderCode,
    required this.customerName,
    required this.vehiclePlate,
    required this.totalAmount,
    required this.orderStatus,
    required this.itemCount,
    required this.isPaid,
    this.createdAt,
    this.createdByName,
  });

  factory TransactionReport.fromJson(Map<String, dynamic> j) {
    final customer = j['customer'];
    final vehicle = j['vehicle'];
    final payment = j['payment'];
    final user = j['user'];
    return TransactionReport(
      orderId: j['order_id']?.toString() ?? '',
      orderCode: j['order_code']?.toString() ?? '-',
      customerName: customer?['customer_name']?.toString() ?? '-',
      vehiclePlate: vehicle?['license_plate']?.toString() ?? '-',
      totalAmount: double.tryParse(j['total_amount']?.toString() ?? '0') ?? 0,
      orderStatus: j['order_status']?.toString() ?? '-',
      itemCount: int.tryParse(j['item_count']?.toString() ?? '0') ?? 0,
      isPaid: payment != null && payment['payment_status'] == 'paid',
      createdAt: j['created_at']?.toString(),
      createdByName: user?['name']?.toString(),
    );
  }
}

class PaymentReport {
  final String paymentId;
  final String orderCode;
  final String customerName;
  final double totalAmount;
  final double paidAmount;
  final double changeAmount;
  final String paymentMethod;
  final String paymentDate;

  PaymentReport({
    required this.paymentId,
    required this.orderCode,
    required this.customerName,
    required this.totalAmount,
    required this.paidAmount,
    required this.changeAmount,
    required this.paymentMethod,
    required this.paymentDate,
  });

  factory PaymentReport.fromJson(Map<String, dynamic> j) {
    final order = j['order'];
    final customer = order?['customer'];
    return PaymentReport(
      paymentId: j['payment_id']?.toString() ?? '',
      orderCode: order?['order_code']?.toString() ?? '-',
      customerName: customer?['customer_name']?.toString() ?? '-',
      totalAmount: double.tryParse(order?['total_amount']?.toString() ?? '0') ?? 0,
      paidAmount: double.tryParse(j['paid_amount']?.toString() ?? '0') ?? 0,
      changeAmount: double.tryParse(j['change_amount']?.toString() ?? '0') ?? 0,
      paymentMethod: j['payment_method']?.toString() ?? '-',
      paymentDate: j['payment_date']?.toString() ?? '-',
    );
  }
}

class StockReport {
  final String itemId;
  final String itemName;
  final String categoryName;
  final String typeName;
  final int stock;
  final double purchasePrice;
  final double sellingPrice;

  StockReport({
    required this.itemId,
    required this.itemName,
    required this.categoryName,
    required this.typeName,
    required this.stock,
    required this.purchasePrice,
    required this.sellingPrice,
  });

  bool get isLow => stock <= 5;
  bool get isWarning => stock > 5 && stock <= 10;

  factory StockReport.fromJson(Map<String, dynamic> j) {
    final cat = j['category'];
    final type = cat?['item_type'];
    return StockReport(
      itemId: j['item_id']?.toString() ?? '',
      itemName: j['item_name']?.toString() ?? '-',
      categoryName: cat?['category_name']?.toString() ?? '-',
      typeName: type?['type_name']?.toString() ?? '-',
      stock: int.tryParse(j['stock']?.toString() ?? '0') ?? 0,
      purchasePrice: double.tryParse(j['purchase_price']?.toString() ?? '0') ?? 0,
      sellingPrice: double.tryParse(j['selling_price']?.toString() ?? '0') ?? 0,
    );
  }
}

class ReportService {
  static Future<ReportSummary> getSummary() async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.get('/reports/summary', options: options);
    return ReportSummary.fromJson(res.data['data']);
  }

  static Future<ReportSummary> getProfit({String? startDate, String? endDate}) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.get(
      '/reports/profit',
      queryParameters: {
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
      options: options,
    );
    final d = res.data['data'];
    return ReportSummary(
      totalIncome: (d['total_income'] as num).toDouble(),
      totalModal: (d['total_modal'] as num).toDouble(),
      totalExpenses: (d['total_expenses'] as num).toDouble(),
      labaKotor: (d['laba_kotor'] as num).toDouble(),
      labaBersih: (d['laba_bersih'] as num).toDouble(),
      orders: const {},
    );
  }

  static Future<List<TransactionReport>> getTransactions({
    String? startDate,
    String? endDate,
  }) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.get(
      '/reports/transactions',
      queryParameters: {
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
      options: options,
    );
    return (res.data['data'] as List)
        .map((e) => TransactionReport.fromJson(e))
        .toList();
  }

  static Future<List<PaymentReport>> getPayments({
    String? startDate,
    String? endDate,
  }) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.get(
      '/reports/income',
      queryParameters: {
        if (startDate != null) 'start_date': startDate,
        if (endDate != null) 'end_date': endDate,
      },
      options: options,
    );
    return (res.data['data']['payments'] as List)
        .map((e) => PaymentReport.fromJson(e))
        .toList();
  }

  static Future<List<StockReport>> getStock() async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.get('/reports/stock', options: options);
    return (res.data['data'] as List)
        .map((e) => StockReport.fromJson(e))
        .toList();
  }

  static Future<List<ChartPoint>> getChart({
    required String period,
    int? year,
    int? month,
  }) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.get(
      '/reports/chart',
      queryParameters: {
        'period': period,
        if (year != null) 'year': year,
        if (month != null) 'month': month,
      },
      options: options,
    );
    return (res.data['data'] as List)
        .map((e) => ChartPoint.fromJson(e))
        .toList();
  }
}

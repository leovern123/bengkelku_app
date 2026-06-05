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

class ReportService {
  static Future<ReportSummary> getSummary() async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.get('/reports/summary', options: options);
    return ReportSummary.fromJson(res.data['data']);
  }

  static Future<ReportSummary> getProfit({
    String? startDate,
    String? endDate,
  }) async {
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

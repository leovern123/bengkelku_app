import '../models/expense_model.dart';
import 'api_service.dart';

class ExpenseService {
  static Future<List<ExpenseModel>> getAll() async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.get('/expenses', options: options);
    if (res.data['success'] == true) {
      return (res.data['data'] as List)
          .map((e) => ExpenseModel.fromJson(e))
          .toList();
    }
    return [];
  }

  static Future<ExpenseModel> create({
    required String expenseName,
    String? expenseCategory,
    required double amount,
    required String expenseDate,
    String? note,
  }) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.post(
      '/expenses',
      data: {
        'expense_name': expenseName,
        if (expenseCategory != null && expenseCategory.isNotEmpty)
          'expense_category': expenseCategory,
        'amount': amount,
        'expense_date': expenseDate,
        if (note != null && note.isNotEmpty) 'note': note,
      },
      options: options,
    );
    return ExpenseModel.fromJson(res.data['data']);
  }

  static Future<ExpenseModel> update(
    String id, {
    required String expenseName,
    String? expenseCategory,
    required double amount,
    required String expenseDate,
    String? note,
  }) async {
    final options = await ApiService.authOptions();
    final res = await ApiService.dio.put(
      '/expenses/$id',
      data: {
        'expense_name': expenseName,
        'expense_category': expenseCategory ?? '',
        'amount': amount,
        'expense_date': expenseDate,
        'note': note ?? '',
      },
      options: options,
    );
    return ExpenseModel.fromJson(res.data['data']);
  }

  static Future<void> delete(String id) async {
    final options = await ApiService.authOptions();
    await ApiService.dio.delete('/expenses/$id', options: options);
  }
}

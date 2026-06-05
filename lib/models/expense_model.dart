class ExpenseModel {
  final String expenseId;
  final String userId;
  final String expenseName;
  final String? expenseCategory;
  final double amount;
  final String expenseDate;
  final String? note;
  final String? createdAt;

  ExpenseModel({
    required this.expenseId,
    required this.userId,
    required this.expenseName,
    this.expenseCategory,
    required this.amount,
    required this.expenseDate,
    this.note,
    this.createdAt,
  });

  factory ExpenseModel.fromJson(Map<String, dynamic> json) => ExpenseModel(
        expenseId: json['expense_id']?.toString() ?? '',
        userId: json['user_id']?.toString() ?? '',
        expenseName: json['expense_name']?.toString() ?? '',
        expenseCategory: json['expense_category']?.toString(),
        amount: double.tryParse(json['amount']?.toString() ?? '0') ?? 0,
        expenseDate: json['expense_date']?.toString() ?? '',
        note: json['note']?.toString(),
        createdAt: json['created_at']?.toString(),
      );
}

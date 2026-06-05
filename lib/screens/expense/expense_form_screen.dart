import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common.dart';

class ExpenseFormScreen extends StatefulWidget {
  final ExpenseModel? expense;
  const ExpenseFormScreen({super.key, this.expense});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final _form = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  final _noteCtrl = TextEditingController();

  String? _selectedCategory;
  DateTime _selectedDate = DateTime.now();
  bool _saving = false;
  String? _error;

  static const _categories = [
    'Gaji / Upah',
    'Listrik & Air',
    'Sewa Tempat',
    'Peralatan & Alat',
    'Bahan Bakar',
    'Pembelian Stok',
    'Perawatan Tempat',
    'Lain-lain',
  ];

  bool get _isEdit => widget.expense != null;

  @override
  void initState() {
    super.initState();
    final e = widget.expense;
    if (e != null) {
      _nameCtrl.text = e.expenseName;
      _amountCtrl.text = e.amount.toStringAsFixed(0);
      _noteCtrl.text = e.note ?? '';
      _selectedCategory = e.expenseCategory;
      if (e.expenseDate.isNotEmpty) {
        _selectedDate = DateTime.tryParse(e.expenseDate) ?? DateTime.now();
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    _noteCtrl.dispose();
    super.dispose();
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  String _displayDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(primary: AppColors.primary),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  String? _parseError(Object e) {
    if (e is DioException) {
      final data = e.response?.data;
      if (data is Map) {
        if (data['errors'] is Map) {
          final errs = data['errors'] as Map;
          return errs.values.first is List
              ? (errs.values.first as List).first.toString()
              : errs.values.first.toString();
        }
        if (data['message'] != null) return data['message'].toString();
      }
    }
    return e.toString();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _saving = true; _error = null; });
    try {
      final amount = double.tryParse(_amountCtrl.text.replaceAll(',', '').replaceAll('.', '')) ?? 0;
      if (_isEdit) {
        await ExpenseService.update(
          widget.expense!.expenseId,
          expenseName: _nameCtrl.text.trim(),
          expenseCategory: _selectedCategory,
          amount: amount,
          expenseDate: _fmtDate(_selectedDate),
          note: _noteCtrl.text.trim(),
        );
      } else {
        await ExpenseService.create(
          expenseName: _nameCtrl.text.trim(),
          expenseCategory: _selectedCategory,
          amount: amount,
          expenseDate: _fmtDate(_selectedDate),
          note: _noteCtrl.text.trim(),
        );
      }
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() { _error = _parseError(e); _saving = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Pengeluaran' : 'Tambah Pengeluaran')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_error != null)
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.red.withAlpha(20),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.red.withAlpha(80)),
                ),
                child: Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
              ),

            // Nama Pengeluaran
            const Text('Nama Pengeluaran *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                hintText: 'Contoh: Bayar listrik bulan Juni',
                prefixIcon: Icon(Icons.receipt_outlined),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama pengeluaran wajib diisi' : null,
            ),
            const SizedBox(height: 16),

            // Kategori
            const Text('Kategori',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _selectedCategory,
              hint: const Text('Pilih kategori (opsional)'),
              decoration: const InputDecoration(prefixIcon: Icon(Icons.category_outlined)),
              items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList()
                ..add(const DropdownMenuItem(value: null, child: Text('— Tanpa Kategori'))),
              onChanged: (v) => setState(() => _selectedCategory = v),
            ),
            const SizedBox(height: 16),

            // Jumlah
            const Text('Jumlah (Rp) *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _amountCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                hintText: '0',
                prefixIcon: Icon(Icons.payments_outlined),
                prefixText: 'Rp ',
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Jumlah wajib diisi';
                final n = double.tryParse(v.replaceAll(',', '').replaceAll('.', ''));
                if (n == null || n <= 0) return 'Jumlah harus lebih dari 0';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Tanggal
            const Text('Tanggal *',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _pickDate,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                decoration: BoxDecoration(
                  border: Border.all(color: AppColors.border),
                  borderRadius: BorderRadius.circular(14),
                  color: AppColors.background,
                ),
                child: Row(children: [
                  const Icon(Icons.calendar_today_outlined, size: 20, color: AppColors.textMuted),
                  const SizedBox(width: 10),
                  Text(_displayDate(_selectedDate),
                      style: const TextStyle(fontSize: 14, color: AppColors.textPrimary)),
                  const Spacer(),
                  const Icon(Icons.keyboard_arrow_down, size: 18, color: AppColors.textMuted),
                ]),
              ),
            ),
            const SizedBox(height: 16),

            // Catatan
            const Text('Catatan',
                style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
            const SizedBox(height: 6),
            TextFormField(
              controller: _noteCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                hintText: 'Keterangan tambahan (opsional)',
                prefixIcon: Padding(
                  padding: EdgeInsets.only(bottom: 48),
                  child: Icon(Icons.notes_outlined),
                ),
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 28),

            PrimaryButton(
              label: _isEdit ? 'Simpan Perubahan' : 'Tambah Pengeluaran',
              icon: _isEdit ? Icons.save_outlined : Icons.add,
              isLoading: _saving,
              onPressed: _save,
              color: AppColors.red,
            ),
          ]),
        ),
      ),
    );
  }
}

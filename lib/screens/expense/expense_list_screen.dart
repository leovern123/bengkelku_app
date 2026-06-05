import 'package:flutter/material.dart';
import '../../models/expense_model.dart';
import '../../services/expense_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common.dart';
import 'expense_form_screen.dart';

class ExpenseListScreen extends StatefulWidget {
  const ExpenseListScreen({super.key});

  @override
  State<ExpenseListScreen> createState() => _ExpenseListScreenState();
}

class _ExpenseListScreenState extends State<ExpenseListScreen> {
  List<ExpenseModel> _all = [];
  bool _loading = true;
  String _search = '';

  List<ExpenseModel> get _filtered {
    if (_search.isEmpty) return _all;
    final q = _search.toLowerCase();
    return _all.where((e) =>
        e.expenseName.toLowerCase().contains(q) ||
        (e.expenseCategory ?? '').toLowerCase().contains(q) ||
        e.expenseDate.contains(q)).toList();
  }

  double get _totalFiltered =>
      _filtered.fold(0, (s, e) => s + e.amount);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await ExpenseService.getAll();
      if (mounted) setState(() { _all = data; _loading = false; });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete(ExpenseModel e) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pengeluaran'),
        content: Text('Hapus "${e.expenseName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    try {
      await ExpenseService.delete(e.expenseId);
      _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gagal menghapus pengeluaran')),
      );
    }
  }

  Future<void> _openForm([ExpenseModel? existing]) async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => ExpenseFormScreen(expense: existing)),
    );
    if (result == true) _load();
  }

  String _fmtDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pengeluaran')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add),
        label: const Text('Tambah'),
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: AppSearchBar(hint: 'Cari nama atau kategori...', onChanged: (v) => setState(() => _search = v)),
            ),
            // Total summary
            if (!_loading && _filtered.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
                child: AppCard(
                  color: AppColors.red.withAlpha(15),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  child: Row(children: [
                    const Icon(Icons.money_off, color: AppColors.red, size: 18),
                    const SizedBox(width: 8),
                    Text('Total${_search.isNotEmpty ? ' (filter)' : ''}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    const Spacer(),
                    Text(rupiah(_totalFiltered),
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.red)),
                  ]),
                ),
              ),
            const SizedBox(height: 8),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : _filtered.isEmpty
                      ? EmptyState(
                          icon: Icons.money_off_outlined,
                          message: _search.isEmpty ? 'Belum ada pengeluaran' : 'Tidak ditemukan',
                          buttonLabel: _search.isEmpty ? 'Tambah Pengeluaran' : null,
                          onButton: _search.isEmpty ? () => _openForm() : null,
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
                          itemCount: _filtered.length,
                          separatorBuilder: (_, __) => const SizedBox(height: 8),
                          itemBuilder: (_, i) => _card(_filtered[i]),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(ExpenseModel e) {
    return AppCard(
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            color: AppColors.red.withAlpha(20),
            borderRadius: BorderRadius.circular(12),
          ),
          alignment: Alignment.center,
          child: const Icon(Icons.money_off, color: AppColors.red, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(e.expenseName,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 2),
            Row(children: [
              if (e.expenseCategory != null && e.expenseCategory!.isNotEmpty) ...[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withAlpha(20),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(e.expenseCategory!,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.primary)),
                ),
                const SizedBox(width: 6),
              ],
              Text(_fmtDate(e.expenseDate),
                  style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ]),
            if (e.note != null && e.note!.isNotEmpty) ...[
              const SizedBox(height: 2),
              Text(e.note!, style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ]),
        ),
        const SizedBox(width: 8),
        Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
          Text(rupiah(e.amount),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.red)),
          const SizedBox(height: 4),
          PopupMenuButton<String>(
            onSelected: (v) {
              if (v == 'edit') { _openForm(e); } else if (v == 'delete') { _delete(e); }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Row(children: [
                Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit'),
              ])),
              const PopupMenuItem(value: 'delete', child: Row(children: [
                Icon(Icons.delete_outline, size: 18, color: AppColors.red), SizedBox(width: 8),
                Text('Hapus', style: TextStyle(color: AppColors.red)),
              ])),
            ],
            child: const Icon(Icons.more_vert, size: 20, color: AppColors.textMuted),
          ),
        ]),
      ]),
    );
  }
}

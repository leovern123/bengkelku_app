import 'package:flutter/material.dart';
import '../../models/supplier_model.dart';
import '../../services/supplier_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common.dart';
import 'supplier_form_screen.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({super.key});

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  List<SupplierModel> _all = [];
  String _search = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _all = await SupplierService.getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<SupplierModel> get _filtered => _all.where((s) {
        final q = _search.toLowerCase();
        if (q.isEmpty) return true;
        return s.supplierName.toLowerCase().contains(q) ||
            (s.phoneNumber ?? '').contains(q) ||
            (s.notes ?? '').toLowerCase().contains(q);
      }).toList();

  String _formatDate(String? dateStr) {
    if (dateStr == null) return '';
    try {
      final dt = DateTime.parse(dateStr).toLocal();
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return '';
    }
  }

  Future<void> _delete(SupplierModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Supplier'),
        content: Text('Hapus supplier "${s.supplierName}"?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await SupplierService.delete(s.supplierId);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Supplier dihapus'),
            backgroundColor: AppColors.green));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Gagal menghapus supplier'),
            backgroundColor: AppColors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supplier')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add, color: Colors.white),
        label:
            const Text('Tambah Supplier', style: TextStyle(color: Colors.white)),
        onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const SupplierFormScreen()))
            .then((_) => _load()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: AppSearchBar(
                hint: 'Cari nama, telepon, keterangan...',
                onChanged: (v) => setState(() => _search = v)),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const EmptyState(
                            message: 'Tidak ada supplier',
                            icon: Icons.business_outlined)
                        : ListView.separated(
                            padding:
                                const EdgeInsets.fromLTRB(18, 0, 18, 100),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final s = _filtered[i];
                              final dateStr = _formatDate(s.updatedAt);
                              return AppCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color:
                                            AppColors.primary.withAlpha(20),
                                        borderRadius:
                                            BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.business,
                                          color: AppColors.primary, size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(s.supplierName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 15)),
                                          if (s.phoneNumber != null &&
                                              s.phoneNumber!.isNotEmpty)
                                            Row(children: [
                                              const Icon(Icons.phone_outlined,
                                                  size: 11,
                                                  color: AppColors.textMuted),
                                              const SizedBox(width: 3),
                                              Text(s.phoneNumber!,
                                                  style: const TextStyle(
                                                      fontSize: 12,
                                                      color:
                                                          AppColors.textMuted)),
                                            ]),
                                          if (s.address != null &&
                                              s.address!.isNotEmpty)
                                            Row(children: [
                                              const Icon(
                                                  Icons.location_on_outlined,
                                                  size: 11,
                                                  color: AppColors.textMuted),
                                              const SizedBox(width: 3),
                                              Flexible(
                                                child: Text(s.address!,
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors
                                                            .textMuted),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                              ),
                                            ]),
                                          if (s.notes != null &&
                                              s.notes!.isNotEmpty)
                                            Row(children: [
                                              const Icon(Icons.notes_outlined,
                                                  size: 11,
                                                  color: AppColors.textMuted),
                                              const SizedBox(width: 3),
                                              Flexible(
                                                child: Text(s.notes!,
                                                    style: const TextStyle(
                                                        fontSize: 12,
                                                        color: AppColors
                                                            .textMuted),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis),
                                              ),
                                            ]),
                                          if (dateStr.isNotEmpty)
                                            Row(children: [
                                              const Icon(Icons.update_outlined,
                                                  size: 11,
                                                  color: AppColors.textMuted),
                                              const SizedBox(width: 3),
                                              Text('Update: $dateStr',
                                                  style: const TextStyle(
                                                      fontSize: 11,
                                                      color:
                                                          AppColors.textMuted)),
                                            ]),
                                        ],
                                      ),
                                    ),
                                    PopupMenuButton<String>(
                                      onSelected: (val) async {
                                        if (val == 'update') {
                                          await Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                                builder: (_) =>
                                                    SupplierFormScreen(
                                                        supplier: s)),
                                          );
                                          _load();
                                        } else if (val == 'delete') {
                                          _delete(s);
                                        }
                                      },
                                      itemBuilder: (_) => [
                                        const PopupMenuItem(
                                            value: 'update',
                                            child: Text('Update')),
                                        const PopupMenuItem(
                                            value: 'delete',
                                            child: Text('Hapus',
                                                style: TextStyle(
                                                    color: AppColors.red))),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

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

  List<SupplierModel> get _filtered => _all
      .where((s) => s.supplierName.toLowerCase().contains(_search.toLowerCase()) ||
          (s.phoneNumber ?? '').contains(_search))
      .toList();

  Future<void> _delete(SupplierModel s) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Supplier'),
        content: Text('Hapus supplier "${s.supplierName}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
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
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Supplier dihapus'), backgroundColor: AppColors.green));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus supplier'), backgroundColor: AppColors.red));
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
        label: const Text('Tambah Supplier', style: TextStyle(color: Colors.white)),
        onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const SupplierFormScreen()))
            .then((_) => _load()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: AppSearchBar(
                hint: 'Cari nama, telepon...',
                onChanged: (v) => setState(() => _search = v)),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const EmptyState(
                            message: 'Tidak ada supplier', icon: Icons.business_outlined)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final s = _filtered[i];
                              return AppCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primary.withAlpha(20),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: const Icon(Icons.business,
                                          color: AppColors.primary, size: 24),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(s.supplierName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w900, fontSize: 15)),
                                          if (s.phoneNumber != null)
                                            Text(s.phoneNumber!,
                                                style: const TextStyle(
                                                    fontSize: 13, color: AppColors.textMuted)),
                                          if (s.address != null)
                                            Text(s.address!,
                                                style: const TextStyle(
                                                    fontSize: 12, color: AppColors.textMuted),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: AppColors.textMuted, size: 20),
                                      onPressed: () => Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (_) =>
                                                      SupplierFormScreen(supplier: s)))
                                          .then((_) => _load()),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: AppColors.red, size: 20),
                                      onPressed: () => _delete(s),
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

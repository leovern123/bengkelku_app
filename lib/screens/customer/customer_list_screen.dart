import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../services/customer_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common.dart';
import 'customer_detail_screen.dart';

class CustomerListScreen extends StatefulWidget {
  const CustomerListScreen({super.key});

  @override
  State<CustomerListScreen> createState() => _CustomerListScreenState();
}

class _CustomerListScreenState extends State<CustomerListScreen> {
  List<CustomerModel> _all = [];
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
      _all = await CustomerService.getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<CustomerModel> get _filtered => _all
      .where((c) => c.customerName.toLowerCase().contains(_search.toLowerCase()) ||
          c.customerId.toLowerCase().contains(_search.toLowerCase()))
      .toList();

  void _openForm({CustomerModel? customer}) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CustomerFormSheet(
        customer: customer,
        onSaved: _load,
      ),
    );
  }

  Future<void> _delete(CustomerModel c) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Pelanggan'),
        content: Text('Hapus "${c.customerName}"?'),
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
      await CustomerService.delete(c.customerId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pelanggan berhasil dihapus'), backgroundColor: AppColors.green));
      }
      _load();
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menghapus'), backgroundColor: AppColors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Pelanggan')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: AppSearchBar(hint: 'Cari nama atau ID pelanggan...', onChanged: (v) => setState(() => _search = v)),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const EmptyState(message: 'Tidak ada pelanggan', icon: Icons.people_outline)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final c = _filtered[i];
                              return AppCard(
                                padding: const EdgeInsets.all(16),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => CustomerDetailScreen(customer: c)),
                                ).then((_) => _load()),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 24,
                                      backgroundColor: AppColors.primary.withAlpha(20),
                                      child: Text(c.customerName[0].toUpperCase(),
                                          style: const TextStyle(
                                              color: AppColors.primary,
                                              fontWeight: FontWeight.w900,
                                              fontSize: 18)),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(c.customerName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 15,
                                                  color: AppColors.textPrimary)),
                                          const SizedBox(height: 2),
                                          Text(c.customerId,
                                              style: const TextStyle(
                                                  fontSize: 12, color: AppColors.textMuted)),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: AppColors.textMuted, size: 20),
                                      onPressed: () => _openForm(customer: c),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: AppColors.red, size: 20),
                                      onPressed: () => _delete(c),
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

// Form sebagai bottom sheet
class CustomerFormSheet extends StatefulWidget {
  final CustomerModel? customer;
  final VoidCallback onSaved;
  const CustomerFormSheet({super.key, this.customer, required this.onSaved});

  @override
  State<CustomerFormSheet> createState() => _CustomerFormSheetState();
}

class _CustomerFormSheetState extends State<CustomerFormSheet> {
  final _nameCtrl = TextEditingController();
  bool _loading = false;

  bool get isEdit => widget.customer != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) _nameCtrl.text = widget.customer!.customerName;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_nameCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    try {
      if (isEdit) {
        await CustomerService.update(widget.customer!.customerId, _nameCtrl.text.trim());
      } else {
        await CustomerService.create(_nameCtrl.text.trim());
      }
      if (!mounted) return;
      Navigator.pop(context);
      widget.onSaved();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Pelanggan berhasil ${isEdit ? 'diperbarui' : 'ditambahkan'}'),
        backgroundColor: AppColors.green,
      ));
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan'), backgroundColor: AppColors.red));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40, height: 4,
                decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
              ),
            ),
            const SizedBox(height: 16),
            Text(isEdit ? 'Ubah Pelanggan' : 'Tambah Pelanggan',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
            const SizedBox(height: 16),
            if (isEdit) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 16, color: AppColors.textMuted),
                    const SizedBox(width: 8),
                    Text('ID: ${widget.customer!.customerId}',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  ],
                ),
              ),
              const SizedBox(height: 12),
            ],
            TextFormField(
              controller: _nameCtrl,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Nama Pelanggan',
                prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: 16),
            PrimaryButton(
              label: isEdit ? 'Simpan Perubahan' : 'Tambah Pelanggan',
              icon: isEdit ? Icons.save : Icons.person_add,
              isLoading: _loading,
              onPressed: _submit,
            ),
          ],
        ),
      ),
    );
  }
}

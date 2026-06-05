import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/item_model.dart';
import '../../models/user_model.dart';
import '../../services/item_service.dart';
import '../../services/supplier_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common.dart';
import 'item_form_screen.dart';

class ItemListScreen extends StatefulWidget {
  const ItemListScreen({super.key});

  @override
  State<ItemListScreen> createState() => _ItemListScreenState();
}

class _ItemListScreenState extends State<ItemListScreen> {
  List<ItemModel> _all = [];
  Map<String, String> _supplierMap = {};
  bool _loading = true;
  String _search = '';
  String _tab = 'all';
  bool _isAdmin = false;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _load();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_data');
    if (data != null && mounted) {
      final user = UserModel.fromJson(jsonDecode(data));
      setState(() => _isAdmin = user.isAdmin);
    }
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final itemsFuture = ItemService.getAll();
      final suppliersFuture = SupplierService.getAll();
      final items = await itemsFuture;
      final suppliers = await suppliersFuture;
      if (mounted) {
        setState(() {
          _all = items;
          _supplierMap = {for (final s in suppliers) s.supplierId: s.supplierName};
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<ItemModel> get _filtered {
    var list = _all;
    if (_tab == 'sparepart') list = list.where((i) => !i.isService).toList();
    if (_tab == 'jasa') list = list.where((i) => i.isService).toList();
    if (_search.isNotEmpty) {
      list = list.where((i) => i.itemName.toLowerCase().contains(_search.toLowerCase())).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Produk & Jasa')),
      floatingActionButton: _isAdmin ? FloatingActionButton.extended(
        onPressed: () async {
          final defaultType = _tab == 'jasa' ? 2 : 1;
          final res = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ItemFormScreen(defaultTypeId: defaultType),
            ),
          );
          if (res == true) _load();
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          _tab == 'jasa' ? 'Tambah Jasa' : 'Tambah Produk',
          style: const TextStyle(color: Colors.white),
        ),
      ) : null,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: AppSearchBar(hint: 'Cari item...', onChanged: (v) => setState(() => _search = v)),
          ),
          const SizedBox(height: 10),
          // Tab filter
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              children: [
                Expanded(child: _tabBtn('all', 'Semua', _all.length)),
                const SizedBox(width: 8),
                Expanded(child: _tabBtn('sparepart', 'Sparepart', _all.where((i) => !i.isService).length)),
                const SizedBox(width: 8),
                Expanded(child: _tabBtn('jasa', 'Jasa', _all.where((i) => i.isService).length)),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const EmptyState(message: 'Tidak ada item', icon: Icons.inventory_2_outlined)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final item = _filtered[i];
                              return AppCard(
                                padding: const EdgeInsets.all(14),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: (item.isService ? AppColors.orange : AppColors.green).withAlpha(20),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(
                                        item.isService ? Icons.build : Icons.inventory_2,
                                        color: item.isService ? AppColors.orange : AppColors.green,
                                        size: 22,
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(item.itemName,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary)),
                                          const SizedBox(height: 2),
                                          Text(rupiah(item.sellingPrice),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
                                          const SizedBox(height: 2),
                                          Row(
                                            children: [
                                              const Icon(Icons.price_change_outlined, size: 11, color: AppColors.textMuted),
                                              const SizedBox(width: 3),
                                              Text(
                                                'Modal: ${rupiah(item.purchasePrice)}',
                                                style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                              ),
                                            ],
                                          ),
                                          if (!item.isService && item.supplierId != null) ...[
                                            const SizedBox(height: 2),
                                            Row(
                                              children: [
                                                const Icon(Icons.business_outlined, size: 11, color: AppColors.textMuted),
                                                const SizedBox(width: 3),
                                                Flexible(
                                                  child: Text(
                                                    _supplierMap[item.supplierId] ?? item.supplierId!,
                                                    style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    if (item.isService)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                        decoration: BoxDecoration(
                                          color: AppColors.orange.withAlpha(20),
                                          borderRadius: BorderRadius.circular(99),
                                          border: Border.all(color: AppColors.orange.withAlpha(80)),
                                        ),
                                        child: const Text('Jasa',
                                            style: TextStyle(
                                                fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.orange)),
                                      )
                                    else
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.end,
                                        children: [
                                          Text(
                                            '${item.stock}',
                                            style: TextStyle(
                                                fontWeight: FontWeight.w900,
                                                fontSize: 18,
                                                color: item.isLowStock ? AppColors.red : AppColors.textPrimary),
                                          ),
                                          Text('stok',
                                              style: TextStyle(
                                                  fontSize: 11,
                                                  color: item.isLowStock ? AppColors.red : AppColors.textMuted)),
                                        ],
                                      ),
                                    if (_isAdmin)
                                      PopupMenuButton<String>(
                                        onSelected: (val) async {
                                          if (val == 'edit') {
                                            final res = await Navigator.push(context, MaterialPageRoute(builder: (_) => ItemFormScreen(item: item)));
                                            if (res == true) _load();
                                          } else if (val == 'delete') {
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (_) => AlertDialog(
                                                title: const Text('Hapus Item'),
                                                content: Text('Yakin ingin menghapus ${item.itemName}?'),
                                                actions: [
                                                  TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
                                                  TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Hapus', style: TextStyle(color: Colors.red))),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              try {
                                                await ItemService.delete(item.itemId);
                                                _load();
                                              } catch (_) {
                                                if (!context.mounted) return;
                                                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus data'), backgroundColor: Colors.red));
                                              }
                                            }
                                          }
                                        },
                                        itemBuilder: (_) => [
                                          const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                          const PopupMenuItem(value: 'delete', child: Text('Hapus', style: TextStyle(color: Colors.red))),
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

  Widget _tabBtn(String key, String label, int count) {
    final active = _tab == key;
    return GestureDetector(
      onTap: () => setState(() => _tab = key),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
        ),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 15,
                    color: active ? Colors.white : AppColors.textPrimary)),
            Text(label,
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: active ? Colors.white : AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

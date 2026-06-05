import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../models/item_model.dart';
import '../../models/category_model.dart';
import '../../models/supplier_model.dart';
import '../../services/item_service.dart';
import '../../services/item_category_service.dart';
import '../../services/supplier_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common.dart';

class ItemFormScreen extends StatefulWidget {
  final ItemModel? item;
  final int defaultTypeId;
  const ItemFormScreen({super.key, this.item, this.defaultTypeId = 1});

  @override
  State<ItemFormScreen> createState() => _ItemFormScreenState();
}

class _ItemFormScreenState extends State<ItemFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _purchasePriceCtrl = TextEditingController();
  final _sellingPriceCtrl = TextEditingController();
  final _stockCtrl = TextEditingController();

  late int _selectedTypeId;
  int? _selectedCategoryId;
  String? _selectedSupplierId;

  List<CategoryModel> _allCategories = [];
  List<SupplierModel> _suppliers = [];
  bool _loadingInit = true;
  bool _loading = false;

  bool get isEdit => widget.item != null;
  bool get isJasa => _selectedTypeId == 2;

  List<CategoryModel> get _filteredCategories =>
      _allCategories.where((c) => c.itemTypeId == _selectedTypeId).toList();

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final item = widget.item!;
      _nameCtrl.text = item.itemName;
      _purchasePriceCtrl.text = item.purchasePrice.toInt().toString();
      _sellingPriceCtrl.text = item.sellingPrice.toInt().toString();
      _stockCtrl.text = item.stock?.toString() ?? '';
      _selectedTypeId = item.itemTypeId ?? widget.defaultTypeId;
      _selectedCategoryId = item.itemCategoryId;
      _selectedSupplierId = item.supplierId;
    } else {
      _selectedTypeId = widget.defaultTypeId;
    }
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final catFuture = ItemCategoryService.getAll();
      final supFuture = SupplierService.getAll();
      final cats = await catFuture;
      final sups = await supFuture;
      if (mounted) {
        setState(() {
          _allCategories = cats;
          _suppliers = sups;
          if (_selectedCategoryId != null &&
              !_filteredCategories.any((c) => c.itemCategoryId == _selectedCategoryId)) {
            _selectedCategoryId = null;
          }
          _loadingInit = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingInit = false);
    }
  }

  void _onTypeChanged(int typeId) {
    setState(() {
      _selectedTypeId = typeId;
      _selectedCategoryId = null;
    });
  }

  String _parseError(dynamic e) {
    if (e is DioException && e.response != null) {
      final data = e.response!.data;
      if (data is Map) {
        final errors = data['errors'];
        if (errors is Map) {
          return errors.values.expand((v) => v is List ? v : [v]).join('\n');
        }
        return data['message']?.toString() ?? 'Error ${e.response!.statusCode}';
      }
    }
    return 'Gagal menyimpan data';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Pilih kategori'), backgroundColor: AppColors.red));
      return;
    }
    setState(() => _loading = true);

    try {
      final data = {
        'item_name': _nameCtrl.text.trim(),
        'item_category_id': _selectedCategoryId,
        if (_selectedSupplierId != null) 'supplier_id': _selectedSupplierId,
        'purchase_price': int.tryParse(_purchasePriceCtrl.text) ?? 0,
        'selling_price': int.tryParse(_sellingPriceCtrl.text) ?? 0,
        if (!isJasa) 'stock': int.tryParse(_stockCtrl.text) ?? 0,
      };

      if (isEdit) {
        await ItemService.update(widget.item!.itemId, data);
      } else {
        await ItemService.create(data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Item berhasil ${isEdit ? 'diperbarui' : 'ditambahkan'}'),
        backgroundColor: AppColors.green,
      ));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_parseError(e)), backgroundColor: AppColors.red));
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _purchasePriceCtrl.dispose();
    _sellingPriceCtrl.dispose();
    _stockCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Produk' : 'Tambah Produk')),
      body: _loadingInit
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text('Informasi Produk',
                              style: TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 16),

                          // Tipe (Sparepart / Jasa)
                          DropdownButtonFormField<int>(
                            initialValue: _selectedTypeId,
                            decoration: const InputDecoration(
                              labelText: 'Tipe',
                              prefixIcon: Icon(Icons.merge_type_outlined,
                                  color: AppColors.textMuted),
                            ),
                            items: const [
                              DropdownMenuItem(value: 1, child: Text('Sparepart')),
                              DropdownMenuItem(value: 2, child: Text('Jasa')),
                            ],
                            onChanged: isEdit ? null : (v) => _onTypeChanged(v!),
                          ),
                          const SizedBox(height: 12),

                          // Kategori — filtered by tipe
                          DropdownButtonFormField<int>(
                            initialValue: _selectedCategoryId,
                            decoration: const InputDecoration(
                              labelText: 'Kategori',
                              prefixIcon: Icon(Icons.category_outlined,
                                  color: AppColors.textMuted),
                            ),
                            items: _filteredCategories
                                .map((c) => DropdownMenuItem(
                                    value: c.itemCategoryId,
                                    child: Text(c.categoryName)))
                                .toList(),
                            onChanged: (v) => setState(() => _selectedCategoryId = v),
                            validator: (_) =>
                                _selectedCategoryId == null ? 'Pilih kategori' : null,
                          ),
                          const SizedBox(height: 12),

                          // Nama
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              labelText: isJasa ? 'Nama Jasa' : 'Nama Produk',
                              prefixIcon: Icon(
                                isJasa ? Icons.build_outlined : Icons.inventory_2_outlined,
                                color: AppColors.textMuted,
                              ),
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? '${isJasa ? 'Nama jasa' : 'Nama produk'} wajib diisi'
                                : null,
                          ),
                          const SizedBox(height: 12),

                          // Supplier — hanya untuk Sparepart
                          if (!isJasa) ...[
                            if (_suppliers.isEmpty)
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppColors.orange.withAlpha(20),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.orange.withAlpha(60)),
                                ),
                                child: const Row(
                                  children: [
                                    Icon(Icons.info_outline, color: AppColors.orange, size: 18),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        'Belum ada supplier. Tambahkan supplier terlebih dahulu.',
                                        style: TextStyle(fontSize: 12, color: AppColors.orange),
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            else
                              DropdownButtonFormField<String>(
                                initialValue: _selectedSupplierId,
                                decoration: const InputDecoration(
                                  labelText: 'Supplier (opsional)',
                                  prefixIcon: Icon(Icons.business_outlined,
                                      color: AppColors.textMuted),
                                ),
                                items: [
                                  const DropdownMenuItem(
                                      value: null, child: Text('— Tidak ada —')),
                                  ..._suppliers.map((s) => DropdownMenuItem(
                                      value: s.supplierId,
                                      child: Text(s.supplierName))),
                                ],
                                onChanged: (v) =>
                                    setState(() => _selectedSupplierId = v),
                              ),
                            const SizedBox(height: 12),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(isJasa ? 'Tarif' : 'Harga & Stok',
                              style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  fontSize: 15,
                                  color: AppColors.textPrimary)),
                          const SizedBox(height: 16),

                          // Harga Beli — hanya untuk Sparepart
                          if (!isJasa) ...[
                            TextFormField(
                              controller: _purchasePriceCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Harga Beli',
                                prefixIcon: Icon(Icons.shopping_cart_outlined,
                                    color: AppColors.textMuted),
                                prefixText: 'Rp ',
                              ),
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Harga Jual / Tarif Jasa
                          TextFormField(
                            controller: _sellingPriceCtrl,
                            keyboardType: TextInputType.number,
                            decoration: InputDecoration(
                              labelText: isJasa ? 'Tarif Jasa' : 'Harga Jual',
                              prefixIcon: Icon(
                                isJasa ? Icons.receipt_long_outlined : Icons.sell_outlined,
                                color: AppColors.textMuted,
                              ),
                              prefixText: 'Rp ',
                            ),
                            validator: (v) => v == null || v.trim().isEmpty
                                ? '${isJasa ? 'Tarif jasa' : 'Harga jual'} wajib diisi'
                                : null,
                          ),

                          // Stok — hanya untuk Sparepart
                          if (!isJasa) ...[
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _stockCtrl,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Stok',
                                prefixIcon: Icon(Icons.numbers_outlined,
                                    color: AppColors.textMuted),
                              ),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Stok wajib diisi'
                                  : null,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    PrimaryButton(
                      label: isEdit ? 'Simpan Perubahan' : 'Tambah Produk',
                      icon: isEdit ? Icons.save : Icons.add,
                      isLoading: _loading,
                      onPressed: _submit,
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}

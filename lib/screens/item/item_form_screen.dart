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
  bool _categoryTouched = false;

  List<CategoryModel> _allCategories = [];
  List<SupplierModel> _suppliers = [];
  bool _loadingInit = true;
  bool _loading = false;

  bool get isEdit => widget.item != null;
  bool get isJasa => _selectedTypeId == 2;

  List<CategoryModel> get _filteredCategories =>
      _allCategories.where((c) => c.itemTypeId == _selectedTypeId).toList();

  String get _selectedCategoryName {
    if (_selectedCategoryId == null) return '';
    try {
      return _allCategories
          .firstWhere((c) => c.itemCategoryId == _selectedCategoryId)
          .categoryName;
    } catch (_) {
      return '';
    }
  }

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      final item = widget.item!;
      _nameCtrl.text = item.itemName;
      _purchasePriceCtrl.text = item.purchasePrice.toInt().toString();
      _sellingPriceCtrl.text = item.sellingPrice.toInt().toString();
      _stockCtrl.text = item.stock?.toString() ?? '';
      _selectedTypeId = item.itemTypeId ?? (item.isService ? 2 : 1);
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
          if (!isEdit && _selectedSupplierId == null) {
            final umum = sups.where((s) =>
                s.supplierName.toLowerCase().contains('umum')).toList();
            if (umum.isNotEmpty) _selectedSupplierId = umum.first.supplierId;
          }
          _loadingInit = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingInit = false);
    }
  }

  Future<void> _openCategoryPicker() async {
    final cats = _filteredCategories;
    String search = '';

    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setStateSheet) {
            final filtered = search.isEmpty
                ? cats
                : cats
                    .where((c) =>
                        c.categoryName.toLowerCase().contains(search.toLowerCase()))
                    .toList();
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(ctx).viewInsets.bottom,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 12),
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.border,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Text(
                      'Pilih Kategori',
                      style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 16,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: TextField(
                      autofocus: true,
                      onChanged: (v) => setStateSheet(() => search = v),
                      decoration: InputDecoration(
                        hintText: 'Cari kategori...',
                        hintStyle:
                            const TextStyle(color: AppColors.textMuted, fontSize: 14),
                        prefixIcon: const Icon(Icons.search_rounded,
                            color: AppColors.textMuted, size: 20),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (filtered.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 24),
                      child: Text(
                        'Tidak ada kategori ditemukan',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                      ),
                    )
                  else
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 280),
                      child: ListView.builder(
                        shrinkWrap: true,
                        itemCount: filtered.length,
                        itemBuilder: (_, i) {
                          final cat = filtered[i];
                          final selected = _selectedCategoryId == cat.itemCategoryId;
                          return ListTile(
                            title: Text(cat.categoryName,
                                style: TextStyle(
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: selected
                                      ? AppColors.primary
                                      : AppColors.textPrimary,
                                )),
                            trailing: selected
                                ? const Icon(Icons.check_circle,
                                    color: AppColors.primary, size: 20)
                                : null,
                            onTap: () => Navigator.pop(ctx, cat.itemCategoryId),
                          );
                        },
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );

    if (result != null) {
      setState(() {
        _selectedCategoryId = result;
        _categoryTouched = true;
      });
    } else {
      setState(() => _categoryTouched = true);
    }
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
    setState(() => _categoryTouched = true);
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategoryId == null) return;

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

  Widget _typeChip(int typeId, String label, IconData icon) {
    final selected = _selectedTypeId == typeId;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 11),
      decoration: BoxDecoration(
        color: selected ? AppColors.primary : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: selected ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 16,
            color: selected ? Colors.white : AppColors.textMuted,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: selected ? Colors.white : AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final categoryError = _categoryTouched && _selectedCategoryId == null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit
            ? 'Update ${isJasa ? 'Jasa' : 'Produk'}'
            : 'Tambah ${isJasa ? 'Jasa' : 'Produk'}'),
      ),
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

                          // Tipe — dynamic toggle chips
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Tipe',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: isEdit
                                      ? AppColors.textMuted
                                      : AppColors.textMuted,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                children: [
                                  Expanded(
                                    child: _typeChip(1, 'Sparepart',
                                        Icons.inventory_2_outlined),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: _typeChip(2, 'Jasa', Icons.build_outlined),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Kategori — searchable picker
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              GestureDetector(
                                onTap: _openCategoryPicker,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 14),
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      color: categoryError
                                          ? AppColors.red
                                          : AppColors.border,
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.category_outlined,
                                        color: categoryError
                                            ? AppColors.red
                                            : AppColors.textMuted,
                                        size: 20,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          _selectedCategoryId != null
                                              ? _selectedCategoryName
                                              : 'Pilih Kategori',
                                          style: TextStyle(
                                            color: _selectedCategoryId != null
                                                ? AppColors.textPrimary
                                                : AppColors.textMuted,
                                            fontSize: 14,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        Icons.arrow_drop_down,
                                        color: categoryError
                                            ? AppColors.red
                                            : AppColors.textMuted,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              if (categoryError)
                                Padding(
                                  padding:
                                      const EdgeInsets.only(top: 6, left: 12),
                                  child: Text(
                                    'Pilih kategori',
                                    style: const TextStyle(
                                        fontSize: 12, color: AppColors.red),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Nama
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: InputDecoration(
                              labelText: isJasa ? 'Nama Jasa' : 'Nama Produk',
                              prefixIcon: Icon(
                                isJasa
                                    ? Icons.build_outlined
                                    : Icons.inventory_2_outlined,
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
                            DropdownButtonFormField<String>(
                              initialValue: _selectedSupplierId,
                              decoration: const InputDecoration(
                                labelText: 'Supplier',
                                prefixIcon: Icon(Icons.business_outlined,
                                    color: AppColors.textMuted),
                              ),
                              items: _suppliers
                                  .map((s) => DropdownMenuItem(
                                      value: s.supplierId,
                                      child: Text(s.supplierName)))
                                  .toList(),
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
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Harga beli wajib diisi'
                                  : null,
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
                                isJasa
                                    ? Icons.receipt_long_outlined
                                    : Icons.sell_outlined,
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
                      label: isEdit
                          ? 'Update ${isJasa ? 'Jasa' : 'Produk'}'
                          : 'Tambah ${isJasa ? 'Jasa' : 'Produk'}',
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

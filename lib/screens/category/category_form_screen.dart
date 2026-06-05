import 'package:flutter/material.dart';
import '../../models/category_model.dart';
import '../../services/item_category_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common.dart';

class CategoryFormScreen extends StatefulWidget {
  final CategoryModel? category;
  const CategoryFormScreen({super.key, this.category});

  @override
  State<CategoryFormScreen> createState() => _CategoryFormScreenState();
}

class _CategoryFormScreenState extends State<CategoryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  int _selectedTypeId = 1;
  bool _loading = false;

  bool get isEdit => widget.category != null;

  static const _types = [
    {'id': 1, 'label': 'Sparepart'},
    {'id': 2, 'label': 'Jasa'},
  ];

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _nameCtrl.text = widget.category!.categoryName;
      _selectedTypeId = widget.category!.itemTypeId;
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (isEdit) {
        await ItemCategoryService.update(
            widget.category!.itemCategoryId, _nameCtrl.text.trim());
      } else {
        await ItemCategoryService.create(_nameCtrl.text.trim(), _selectedTypeId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kategori berhasil ${isEdit ? 'diperbarui' : 'ditambahkan'}'),
        backgroundColor: AppColors.green,
      ));
      Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        String msg = 'Gagal menyimpan data';
        if (e.toString().contains('422') || e.toString().contains('DioException')) {
          msg = 'Data tidak valid, periksa kembali isian';
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.red),
        );
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Kategori' : 'Tambah Kategori')),
      body: SingleChildScrollView(
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
                    const Text('Informasi Kategori',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    DropdownButtonFormField<int>(
                      initialValue: _selectedTypeId,
                      decoration: const InputDecoration(
                        labelText: 'Tipe',
                        prefixIcon: Icon(Icons.category_outlined,
                            color: AppColors.textMuted),
                      ),
                      items: _types
                          .map((t) => DropdownMenuItem<int>(
                                value: t['id'] as int,
                                child: Text(t['label'] as String),
                              ))
                          .toList(),
                      onChanged: isEdit
                          ? null
                          : (v) => setState(() => _selectedTypeId = v!),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Kategori',
                        prefixIcon: Icon(Icons.label_outline,
                            color: AppColors.textMuted),
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Nama kategori wajib diisi'
                          : null,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: isEdit ? 'Simpan Perubahan' : 'Tambah Kategori',
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

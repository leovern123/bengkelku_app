import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../models/supplier_model.dart';
import '../../services/supplier_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common.dart';

class SupplierFormScreen extends StatefulWidget {
  final SupplierModel? supplier;
  const SupplierFormScreen({super.key, this.supplier});

  @override
  State<SupplierFormScreen> createState() => _SupplierFormScreenState();
}

class _SupplierFormScreenState extends State<SupplierFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _addressCtrl = TextEditingController();
  bool _loading = false;

  bool get isEdit => widget.supplier != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _nameCtrl.text = widget.supplier!.supplierName;
      _phoneCtrl.text = widget.supplier!.phoneNumber ?? '';
      _addressCtrl.text = widget.supplier!.address ?? '';
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _phoneCtrl.dispose();
    _addressCtrl.dispose();
    super.dispose();
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
    setState(() => _loading = true);

    try {
      final data = {
        'supplier_name': _nameCtrl.text.trim(),
        if (_phoneCtrl.text.trim().isNotEmpty) 'phone_number': _phoneCtrl.text.trim(),
        if (_addressCtrl.text.trim().isNotEmpty) 'address': _addressCtrl.text.trim(),
      };

      if (isEdit) {
        await SupplierService.update(widget.supplier!.supplierId, data);
      } else {
        await SupplierService.create(data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Supplier berhasil ${isEdit ? 'diperbarui' : 'ditambahkan'}'),
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Edit Supplier' : 'Tambah Supplier')),
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
                    const Text('Informasi Supplier',
                        style: TextStyle(
                            fontWeight: FontWeight.w900,
                            fontSize: 15,
                            color: AppColors.textPrimary)),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _nameCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nama Supplier',
                        prefixIcon: Icon(Icons.business_outlined, color: AppColors.textMuted),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty ? 'Nama supplier wajib diisi' : null,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        labelText: 'No. Telepon (opsional)',
                        prefixIcon: Icon(Icons.phone_outlined, color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _addressCtrl,
                      maxLines: 3,
                      decoration: const InputDecoration(
                        labelText: 'Alamat (opsional)',
                        prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.textMuted),
                        alignLabelWithHint: true,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              PrimaryButton(
                label: isEdit ? 'Simpan Perubahan' : 'Tambah Supplier',
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

import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../services/customer_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/custom_text_field.dart';

class CustomerFormScreen extends StatefulWidget {
  final CustomerModel? customer;
  const CustomerFormScreen({super.key, this.customer});

  @override
  State<CustomerFormScreen> createState() => _CustomerFormScreenState();
}

class _CustomerFormScreenState extends State<CustomerFormScreen> {
  final _formKey = GlobalKey<FormState>();
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
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      if (isEdit) {
        await CustomerService.update(widget.customer!.customerId, _nameCtrl.text.trim());
      } else {
        await CustomerService.create(_nameCtrl.text.trim());
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Customer berhasil ${isEdit ? 'diperbarui' : 'ditambahkan'}'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Gagal menyimpan data'), backgroundColor: Colors.red),
        );
      }
    }

    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Customer' : 'Tambah Customer'),
        backgroundColor: const Color(0xFF1565C0),
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (isEdit) ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, size: 18, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text('ID: ${widget.customer!.customerId}',
                          style: TextStyle(color: Colors.grey[600])),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              CustomTextField(
                controller: _nameCtrl,
                label: 'Nama Customer',
                prefixIcon: const Icon(Icons.person_outlined),
                validator: (v) => v == null || v.trim().isEmpty ? 'Nama wajib diisi' : null,
              ),
              const SizedBox(height: 24),
              CustomButton(
                label: isEdit ? 'Simpan Perubahan' : 'Tambah Customer',
                isLoading: _loading,
                onPressed: _submit,
                icon: isEdit ? Icons.save : Icons.add,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

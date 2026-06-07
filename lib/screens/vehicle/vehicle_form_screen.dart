import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import '../../models/customer_model.dart';
import '../../models/vehicle_model.dart';
import '../../services/customer_service.dart';
import '../../services/vehicle_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common.dart';

class VehicleFormScreen extends StatefulWidget {
  final VehicleModel? vehicle;
  final CustomerModel? preselectedCustomer;
  const VehicleFormScreen({super.key, this.vehicle, this.preselectedCustomer});

  @override
  State<VehicleFormScreen> createState() => _VehicleFormScreenState();
}

class _VehicleFormScreenState extends State<VehicleFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _plateCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();

  List<CustomerModel> _customers = [];
  CustomerModel? _selectedCustomer;
  bool _loading = false;
  bool _loadingCustomers = true;

  bool get isEdit => widget.vehicle != null;

  @override
  void initState() {
    super.initState();
    if (isEdit) {
      _plateCtrl.text = widget.vehicle!.licensePlate;
      _brandCtrl.text = widget.vehicle!.brand ?? '';
      _modelCtrl.text = widget.vehicle!.model ?? '';
    }
    _loadCustomers();
  }

  @override
  void dispose() {
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    try {
      _customers = await CustomerService.getAll();
      if (widget.preselectedCustomer != null) {
        _selectedCustomer = _customers.firstWhere(
          (c) => c.customerId == widget.preselectedCustomer!.customerId,
          orElse: () => widget.preselectedCustomer!,
        );
      } else if (isEdit) {
        _selectedCustomer = _customers.firstWhere(
          (c) => c.customerId == widget.vehicle!.customerId,
          orElse: () => _customers.first,
        );
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingCustomers = false);
  }

  String _parseError(dynamic e) {
    if (e is DioException) {
      if (e.response != null) {
        final data = e.response!.data;
        if (data is Map) {
          final errors = data['errors'];
          if (errors is Map) {
            return errors.values
                .expand((v) => v is List ? v : [v])
                .join(', ');
          }
          return data['message']?.toString() ?? 'Error ${e.response!.statusCode}';
        }
        return 'Error ${e.response!.statusCode}';
      }
      return 'Server tidak dapat dijangkau (${e.message})';
    }
    return '${e.runtimeType}: $e';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedCustomer == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pilih pelanggan'), backgroundColor: AppColors.red));
      return;
    }
    setState(() => _loading = true);

    try {
      final data = {
        'customer_id': _selectedCustomer!.customerId,
        'license_plate': _plateCtrl.text.trim().toUpperCase(),
        if (_brandCtrl.text.trim().isNotEmpty) 'brand': _brandCtrl.text.trim(),
        if (_modelCtrl.text.trim().isNotEmpty) 'model': _modelCtrl.text.trim(),
      };

      if (isEdit) {
        await VehicleService.update(widget.vehicle!.vehicleId, data);
      } else {
        await VehicleService.create(data);
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Kendaraan berhasil ${isEdit ? 'diperbarui' : 'ditambahkan'}'),
        backgroundColor: AppColors.green,
      ));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        final msg = _parseError(e);
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(msg), backgroundColor: AppColors.red));
      }
    }
    if (mounted) setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(isEdit ? 'Ubah Kendaraan' : 'Tambah Kendaraan')),
      body: _loadingCustomers
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
                          const Text('Informasi Kendaraan',
                              style: TextStyle(fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimary)),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<CustomerModel>(
                            initialValue: _selectedCustomer,
                            decoration: const InputDecoration(
                              labelText: 'Pelanggan',
                              prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
                            ),
                            items: _customers
                                .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text('${c.customerId} - ${c.customerName}')))
                                .toList(),
                            onChanged: widget.preselectedCustomer != null
                                ? null
                                : (v) => setState(() => _selectedCustomer = v),
                            validator: (_) =>
                                _selectedCustomer == null ? 'Pilih pelanggan' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _plateCtrl,
                            textCapitalization: TextCapitalization.characters,
                            decoration: const InputDecoration(
                              labelText: 'Plat Nomor',
                              prefixIcon: Icon(Icons.credit_card, color: AppColors.textMuted),
                            ),
                            validator: (v) =>
                                v == null || v.trim().isEmpty ? 'Plat nomor wajib' : null,
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _brandCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Merek (opsional)',
                              prefixIcon: Icon(Icons.branding_watermark_outlined, color: AppColors.textMuted),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _modelCtrl,
                            decoration: const InputDecoration(
                              labelText: 'Model (opsional)',
                              prefixIcon: Icon(Icons.two_wheeler, color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    PrimaryButton(
                      label: isEdit ? 'Simpan Perubahan' : 'Tambah Kendaraan',
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

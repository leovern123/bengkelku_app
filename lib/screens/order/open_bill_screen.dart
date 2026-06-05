import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/customer_model.dart';
import '../../models/vehicle_model.dart';
import '../../models/mechanic_model.dart';
import '../../services/customer_service.dart';
import '../../services/vehicle_service.dart';
import '../../services/mechanic_service.dart';
import '../../services/order_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common.dart';
import 'order_detail_screen.dart';

class OpenBillScreen extends StatefulWidget {
  const OpenBillScreen({super.key});

  @override
  State<OpenBillScreen> createState() => _OpenBillScreenState();
}

class _OpenBillScreenState extends State<OpenBillScreen> {
  // Mode
  bool _newCustomer = false;
  bool _newVehicle = false;

  // Existing
  List<CustomerModel> _customers = [];
  List<VehicleModel> _vehicles = [];
  List<MechanicModel> _mechanics = [];
  CustomerModel? _selectedCustomer;
  VehicleModel? _selectedVehicle;
  MechanicModel? _selectedMechanic;

  // New customer
  final _newNameCtrl = TextEditingController();

  // New vehicle
  final _plateCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();

  // State
  bool _loadingData = true;
  bool _loadingVehicles = false;
  bool _submitting = false;

  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  @override
  void dispose() {
    _newNameCtrl.dispose();
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadCustomers() async {
    try {
      final custFuture = CustomerService.getAll();
      final mechFuture = MechanicService.getAll();
      _customers = await custFuture;
      _mechanics = await mechFuture;
    } catch (_) {}
    if (mounted) setState(() => _loadingData = false);
  }

  Future<void> _onCustomerSelected(CustomerModel? c) async {
    setState(() {
      _selectedCustomer = c;
      _selectedVehicle = null;
      _vehicles = [];
      _newVehicle = false;
      _loadingVehicles = true;
    });
    if (c == null) {
      if (mounted) setState(() => _loadingVehicles = false);
      return;
    }
    try {
      final v = await VehicleService.getByCustomer(c.customerId);
      if (mounted) {
        setState(() {
          _vehicles = v;
          _loadingVehicles = false;
          if (v.isEmpty) _newVehicle = true;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingVehicles = false);
    }
  }

  bool get _canSubmit {
    final customerOk = _newCustomer
        ? _newNameCtrl.text.trim().isNotEmpty
        : _selectedCustomer != null;
    final vehicleOk = _newVehicle
        ? _plateCtrl.text.trim().isNotEmpty
        : _selectedVehicle != null;
    return customerOk && vehicleOk && _selectedMechanic != null;
  }

  Future<void> _bukaOrder() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = jsonDecode(prefs.getString('user_data') ?? '{}');
      final userId = userData['user_id'] ?? '';

      // 1. Buat pelanggan baru jika perlu
      CustomerModel customer;
      if (_newCustomer) {
        customer = await CustomerService.create(_newNameCtrl.text.trim());
      } else {
        customer = _selectedCustomer!;
      }

      // 2. Buat kendaraan baru jika perlu
      VehicleModel vehicle;
      if (_newVehicle) {
        vehicle = await VehicleService.create({
          'customer_id': customer.customerId,
          'license_plate': _plateCtrl.text.trim(),
          if (_brandCtrl.text.trim().isNotEmpty) 'brand': _brandCtrl.text.trim(),
          if (_modelCtrl.text.trim().isNotEmpty) 'model': _modelCtrl.text.trim(),
        });
      } else {
        vehicle = _selectedVehicle!;
      }

      // 3. Buka order
      final order = await OrderService.create(
        customerId: customer.customerId,
        vehicleId: vehicle.vehicleId,
        userId: userId,
        mechanicId: _selectedMechanic?.mechanicId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Open bill berhasil dibuka'),
          backgroundColor: AppColors.green));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
      );
    } catch (e) {
      if (!mounted) return;
      String msg = 'Gagal membuka order';
      if (e is DioException && e.response != null) {
        final data = e.response!.data;
        if (data is Map) {
          final errors = data['errors'];
          if (errors is Map) {
            msg = errors.values.expand((v) => v is List ? v : [v]).join(', ');
          } else {
            msg = data['message']?.toString() ?? msg;
          }
        }
      }
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(msg), backgroundColor: AppColors.red));
      setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buka Open Bill')),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Step 1: Pelanggan ──────────────────────────────
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _stepLabel('1', 'Pelanggan'),
                          const SizedBox(height: 12),
                          _modeToggle(
                            leftLabel: 'Pilih Pelanggan',
                            rightLabel: 'Pelanggan Baru',
                            isRight: _newCustomer,
                            onChanged: (v) => setState(() {
                              _newCustomer = v;
                              _selectedCustomer = null;
                              _selectedVehicle = null;
                              _vehicles = [];
                              _newVehicle = v; // kalau baru, kendaraan juga baru
                            }),
                          ),
                          const SizedBox(height: 12),
                          if (_newCustomer)
                            TextFormField(
                              controller: _newNameCtrl,
                              decoration: const InputDecoration(
                                labelText: 'Nama Pelanggan',
                                prefixIcon: Icon(Icons.person_outline,
                                    color: AppColors.textMuted),
                              ),
                              onChanged: (_) => setState(() {}),
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Nama pelanggan wajib diisi'
                                  : null,
                            )
                          else
                            DropdownButtonFormField<CustomerModel>(
                              initialValue: _selectedCustomer,
                              decoration: const InputDecoration(
                                hintText: 'Pilih pelanggan',
                                prefixIcon: Icon(Icons.person_outline,
                                    color: AppColors.textMuted),
                              ),
                              items: _customers
                                  .map((c) => DropdownMenuItem(
                                        value: c,
                                        child: Text(c.customerName),
                                      ))
                                  .toList(),
                              onChanged: _onCustomerSelected,
                              validator: (_) => !_newCustomer &&
                                      _selectedCustomer == null
                                  ? 'Pilih pelanggan'
                                  : null,
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Step 2: Kendaraan ──────────────────────────────
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _stepLabel('2', 'Kendaraan'),
                          const SizedBox(height: 12),

                          // Toggle hanya tampil jika pelanggan lama dipilih dan ada kendaraan
                          if (!_newCustomer &&
                              _selectedCustomer != null &&
                              _vehicles.isNotEmpty) ...[
                            _modeToggle(
                              leftLabel: 'Pilih Kendaraan',
                              rightLabel: 'Kendaraan Baru',
                              isRight: _newVehicle,
                              onChanged: (v) => setState(() {
                                _newVehicle = v;
                                _selectedVehicle = null;
                                _plateCtrl.clear();
                                _brandCtrl.clear();
                                _modelCtrl.clear();
                              }),
                            ),
                            const SizedBox(height: 12),
                          ],

                          if (_loadingVehicles)
                            const Center(
                              child: Padding(
                                padding: EdgeInsets.all(8),
                                child: CircularProgressIndicator(
                                    color: AppColors.primary),
                              ),
                            )
                          else if (_newVehicle || _newCustomer)
                            _vehicleNewFields()
                          else
                            DropdownButtonFormField<VehicleModel>(
                              initialValue: _selectedVehicle,
                              decoration: InputDecoration(
                                hintText: _selectedCustomer == null
                                    ? 'Pilih pelanggan dulu'
                                    : 'Pilih kendaraan',
                                prefixIcon: const Icon(
                                    Icons.directions_car_outlined,
                                    color: AppColors.textMuted),
                              ),
                              items: _vehicles
                                  .map((v) => DropdownMenuItem(
                                      value: v, child: Text(v.displayName)))
                                  .toList(),
                              onChanged: _selectedCustomer == null
                                  ? null
                                  : (v) => setState(() => _selectedVehicle = v),
                              validator: (_) => !_newVehicle &&
                                      _selectedVehicle == null &&
                                      _selectedCustomer != null
                                  ? 'Pilih kendaraan'
                                  : null,
                            ),

                          if (!_newCustomer &&
                              _selectedCustomer != null &&
                              !_loadingVehicles &&
                              _vehicles.isEmpty &&
                              !_newVehicle)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text(
                                'Pelanggan belum memiliki kendaraan.',
                                style: TextStyle(
                                    color: AppColors.orange, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 14),

                    // ── Step 3: Mekanik ────────────────────────────────
                    AppCard(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _stepLabel('3', 'Mekanik'),
                          const SizedBox(height: 12),
                          DropdownButtonFormField<MechanicModel>(
                            initialValue: _selectedMechanic,
                            decoration: const InputDecoration(
                              hintText: 'Pilih mekanik',
                              prefixIcon: Icon(Icons.engineering_outlined,
                                  color: AppColors.textMuted),
                            ),
                            items: _mechanics.map((m) => DropdownMenuItem(
                                  value: m,
                                  child: Text(m.mechanicName +
                                      (m.phoneNumber != null ? '  •  ${m.phoneNumber}' : '')),
                                )).toList(),
                            onChanged: (v) => setState(() => _selectedMechanic = v),
                            validator: (_) => _selectedMechanic == null ? 'Pilih mekanik' : null,
                          ),
                          if (_mechanics.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 8),
                              child: Text(
                                'Belum ada mekanik. Tambahkan mekanik terlebih dahulu.',
                                style: TextStyle(fontSize: 12, color: AppColors.orange),
                              ),
                            ),
                        ],
                      ),
                    ),

                    // ── Preview ────────────────────────────────────────
                    if (_canSubmit) ...[
                      const SizedBox(height: 14),
                      AppCard(
                        color: AppColors.green.withAlpha(15),
                        padding: const EdgeInsets.all(14),
                        child: Row(
                          children: [
                            const Icon(Icons.check_circle,
                                color: AppColors.green, size: 20),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _newCustomer
                                        ? _newNameCtrl.text.trim()
                                        : _selectedCustomer!.customerName,
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.green),
                                  ),
                                  Text(
                                    _newVehicle
                                        ? '${_plateCtrl.text.trim()}${_brandCtrl.text.trim().isNotEmpty ? ' - ${_brandCtrl.text.trim()}' : ''}${_modelCtrl.text.trim().isNotEmpty ? ' ${_modelCtrl.text.trim()}' : ''}'
                                        : _selectedVehicle!.displayName,
                                    style: const TextStyle(
                                        fontSize: 13, color: AppColors.green),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: 'Buka Order',
                      icon: Icons.receipt_long,
                      isLoading: _submitting,
                      color: AppColors.orange,
                      onPressed: _canSubmit ? _bukaOrder : null,
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _vehicleNewFields() {
    return Column(
      children: [
        TextFormField(
          controller: _plateCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Plat Nomor',
            prefixIcon: Icon(Icons.directions_car_outlined,
                color: AppColors.textMuted),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) =>
              v == null || v.trim().isEmpty ? 'Plat nomor wajib diisi' : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _brandCtrl,
          decoration: const InputDecoration(
            labelText: 'Merk (opsional)',
            prefixIcon: Icon(Icons.branding_watermark_outlined,
                color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _modelCtrl,
          decoration: const InputDecoration(
            labelText: 'Tipe/Model (opsional)',
            prefixIcon:
                Icon(Icons.car_repair_outlined, color: AppColors.textMuted),
          ),
        ),
      ],
    );
  }

  Widget _modeToggle({
    required String leftLabel,
    required String rightLabel,
    required bool isRight,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(child: _toggleBtn(leftLabel, !isRight, () => onChanged(false))),
          Expanded(child: _toggleBtn(rightLabel, isRight, () => onChanged(true))),
        ],
      ),
    );
  }

  Widget _toggleBtn(String label, bool active, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 9),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : AppColors.textMuted,
          ),
        ),
      ),
    );
  }

  Widget _stepLabel(String num, String label) {
    return Row(
      children: [
        Container(
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Center(
            child: Text(num,
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 13)),
          ),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: AppColors.textPrimary)),
      ],
    );
  }
}

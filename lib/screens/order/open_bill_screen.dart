import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/customer_model.dart';
import '../../models/vehicle_model.dart';
import '../../services/customer_service.dart';
import '../../services/vehicle_service.dart';
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
  List<CustomerModel> _customers = [];
  List<VehicleModel> _vehicles = [];

  CustomerModel? _selectedCustomer;
  VehicleModel? _selectedVehicle;

  bool _loadingData = true;
  bool _loadingVehicles = false;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _loadCustomers();
  }

  Future<void> _loadCustomers() async {
    try {
      _customers = await CustomerService.getAll();
    } catch (_) {}
    if (mounted) setState(() => _loadingData = false);
  }

  Future<void> _onCustomerSelected(CustomerModel? c) async {
    setState(() {
      _selectedCustomer = c;
      _selectedVehicle = null;
      _vehicles = [];
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
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loadingVehicles = false);
    }
  }

  Future<void> _bukaOrder() async {
    if (_selectedCustomer == null || _selectedVehicle == null) return;
    setState(() => _submitting = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = jsonDecode(prefs.getString('user_data') ?? '{}');
      final userId = userData['user_id'] ?? '';

      final order = await OrderService.create(
        customerId: _selectedCustomer!.customerId,
        vehicleId: _selectedVehicle!.vehicleId,
        userId: userId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Open bill berhasil dibuka'), backgroundColor: AppColors.green));

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
      );
    } catch (e) {
      if (mounted) {
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
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buka Open Bill')),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Info banner
                  AppCard(
                    color: AppColors.primary.withAlpha(15),
                    padding: const EdgeInsets.all(14),
                    child: Row(
                      children: [
                        const Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'Pilih pelanggan dan kendaraan untuk membuka order. Item/jasa ditambahkan setelah order dibuka.',
                            style: TextStyle(fontSize: 13, color: AppColors.primary),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Step 1: Pelanggan
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _stepLabel('1', 'Pilih Pelanggan'),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<CustomerModel>(
                          initialValue: _selectedCustomer,
                          decoration: const InputDecoration(
                            hintText: 'Pilih pelanggan',
                            prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
                          ),
                          items: _customers
                              .map((c) => DropdownMenuItem(
                                    value: c,
                                    child: Text('${c.customerId} - ${c.customerName}'),
                                  ))
                              .toList(),
                          onChanged: _onCustomerSelected,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Step 2: Kendaraan
                  AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _stepLabel('2', 'Pilih Kendaraan'),
                        const SizedBox(height: 12),
                        if (_loadingVehicles)
                          const Center(
                              child: Padding(
                            padding: EdgeInsets.all(8),
                            child: CircularProgressIndicator(color: AppColors.primary),
                          ))
                        else
                          DropdownButtonFormField<VehicleModel>(
                            initialValue: _selectedVehicle,
                            decoration: InputDecoration(
                              hintText: _selectedCustomer == null
                                  ? 'Pilih pelanggan dulu'
                                  : _vehicles.isEmpty
                                      ? 'Tidak ada kendaraan'
                                      : 'Pilih kendaraan',
                              prefixIcon: const Icon(Icons.directions_car_outlined, color: AppColors.textMuted),
                            ),
                            items: _vehicles
                                .map((v) => DropdownMenuItem(value: v, child: Text(v.displayName)))
                                .toList(),
                            onChanged: _selectedCustomer == null || _vehicles.isEmpty
                                ? null
                                : (v) => setState(() => _selectedVehicle = v),
                          ),
                        if (_selectedCustomer != null && !_loadingVehicles && _vehicles.isEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              'Pelanggan belum memiliki kendaraan. Tambahkan kendaraan terlebih dahulu.',
                              style: TextStyle(color: AppColors.orange, fontSize: 12),
                            ),
                          ),
                      ],
                    ),
                  ),

                  // Preview
                  if (_selectedCustomer != null && _selectedVehicle != null) ...[
                    const SizedBox(height: 14),
                    AppCard(
                      color: AppColors.green.withAlpha(15),
                      padding: const EdgeInsets.all(14),
                      child: Row(
                        children: [
                          const Icon(Icons.check_circle, color: AppColors.green, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedCustomer!.customerName,
                                    style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.green)),
                                Text(_selectedVehicle!.displayName,
                                    style: const TextStyle(fontSize: 13, color: AppColors.green)),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 32),
                  PrimaryButton(
                    label: 'Buka Order',
                    icon: Icons.receipt_long,
                    isLoading: _submitting,
                    color: AppColors.orange,
                    onPressed: _selectedCustomer != null && _selectedVehicle != null
                        ? _bukaOrder
                        : null,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _stepLabel(String num, String label) {
    return Row(
      children: [
        Container(
          width: 26, height: 26,
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(99),
          ),
          child: Center(
            child: Text(num, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
        ),
        const SizedBox(width: 10),
        Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
      ],
    );
  }
}

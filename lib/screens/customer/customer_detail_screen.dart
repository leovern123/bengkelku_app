import 'package:flutter/material.dart';
import '../../models/customer_model.dart';
import '../../models/vehicle_model.dart';
import '../../services/vehicle_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common.dart';
import '../vehicle/vehicle_form_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final CustomerModel customer;
  const CustomerDetailScreen({super.key, required this.customer});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  List<VehicleModel> _vehicles = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _vehicles = await VehicleService.getByCustomer(widget.customer.customerId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  void _addVehicle() {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => VehicleFormScreen(preselectedCustomer: widget.customer)),
    ).then((_) => _load());
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.customer;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 160,
            pinned: true,
            backgroundColor: AppColors.primaryDark,
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                ),
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 56, 20, 16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white.withAlpha(30),
                          child: Text(
                            c.customerName.isNotEmpty
                                ? c.customerName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 24),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(c.customerName,
                                  style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w900,
                                      color: Colors.white)),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(25),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(c.customerId,
                                    style: const TextStyle(
                                        fontSize: 12, color: Colors.white70)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 100),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Kendaraan (${_vehicles.length})',
                        style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w900,
                            color: AppColors.textPrimary),
                      ),
                      FilledButton.icon(
                        onPressed: _addVehicle,
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Tambah',
                            style: TextStyle(fontWeight: FontWeight.w700)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  if (_loading)
                    const Center(
                        child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(color: AppColors.primary),
                    ))
                  else if (_vehicles.isEmpty)
                    EmptyState(
                      message: 'Belum ada kendaraan terdaftar',
                      icon: Icons.two_wheeler_outlined,
                      buttonLabel: 'Tambah Kendaraan',
                      onButton: _addVehicle,
                    )
                  else
                    ...List.generate(_vehicles.length, (i) {
                      final v = _vehicles[i];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: AppCard(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              Container(
                                width: 48,
                                height: 48,
                                decoration: BoxDecoration(
                                  color: AppColors.primaryDark.withAlpha(18),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: const Icon(Icons.two_wheeler_rounded,
                                    color: AppColors.primaryDark, size: 24),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(v.licensePlate,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.w900,
                                            fontSize: 15,
                                            color: AppColors.textPrimary)),
                                    if (v.brand != null || v.model != null)
                                      Text(
                                        '${v.brand ?? ''} ${v.model ?? ''}'.trim(),
                                        style: const TextStyle(
                                            fontSize: 13,
                                            color: AppColors.textMuted),
                                      ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.border.withAlpha(80),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  v.vehicleId.toString(),
                                  style: const TextStyle(
                                      fontSize: 11, color: AppColors.textMuted),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

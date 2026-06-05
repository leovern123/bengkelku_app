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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.customer.customerName)),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.directions_car, color: Colors.white),
        label: const Text('Tambah Kendaraan', style: TextStyle(color: Colors.white)),
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => VehicleFormScreen(preselectedCustomer: widget.customer)),
        ).then((_) => _load()),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppColors.primary.withAlpha(20),
                    child: Text(widget.customer.customerName[0].toUpperCase(),
                        style: const TextStyle(
                            color: AppColors.primary, fontWeight: FontWeight.w900, fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.customer.customerName,
                          style: const TextStyle(
                              fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.textPrimary)),
                      const SizedBox(height: 2),
                      Text(widget.customer.customerId,
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            SectionTitle(
              title: 'Kendaraan (${_vehicles.length})',
              action: TextButton.icon(
                icon: const Icon(Icons.add, size: 16),
                label: const Text('Tambah'),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => VehicleFormScreen(preselectedCustomer: widget.customer)),
                ).then((_) => _load()),
              ),
            ),
            const SizedBox(height: 10),
            if (_loading)
              const Center(child: CircularProgressIndicator(color: AppColors.primary))
            else if (_vehicles.isEmpty)
              const EmptyState(
                  message: 'Belum ada kendaraan terdaftar', icon: Icons.directions_car_outlined)
            else
              ...List.generate(_vehicles.length, (i) {
                final v = _vehicles[i];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: AppCard(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark.withAlpha(20),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.directions_car, color: AppColors.primaryDark, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.licensePlate,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w900, fontSize: 15, color: AppColors.textPrimary)),
                              if (v.brand != null || v.model != null)
                                Text('${v.brand ?? ''} ${v.model ?? ''}',
                                    style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        Text(v.vehicleId,
                            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../../models/vehicle_model.dart';
import '../../services/vehicle_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common.dart';
import 'vehicle_form_screen.dart';

class VehicleListScreen extends StatefulWidget {
  const VehicleListScreen({super.key});

  @override
  State<VehicleListScreen> createState() => _VehicleListScreenState();
}

class _VehicleListScreenState extends State<VehicleListScreen> {
  List<VehicleModel> _all = [];
  String _search = '';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _all = await VehicleService.getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<VehicleModel> get _filtered => _all
      .where((v) =>
          v.licensePlate.toLowerCase().contains(_search.toLowerCase()) ||
          (v.brand ?? '').toLowerCase().contains(_search.toLowerCase()) ||
          (v.customer?.customerName ?? '').toLowerCase().contains(_search.toLowerCase()))
      .toList();

  Future<void> _delete(VehicleModel v) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Kendaraan'),
        content: Text('Hapus kendaraan ${v.licensePlate}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Hapus', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await VehicleService.delete(v.vehicleId);
      _load();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Kendaraan dihapus'), backgroundColor: AppColors.green));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus'), backgroundColor: AppColors.red));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Data Kendaraan')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primaryDark,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Tambah Kendaraan', style: TextStyle(color: Colors.white)),
        onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const VehicleFormScreen()))
            .then((_) => _load()),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 0),
            child: AppSearchBar(hint: 'Cari plat, merek, pelanggan...', onChanged: (v) => setState(() => _search = v)),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const EmptyState(message: 'Tidak ada kendaraan', icon: Icons.directions_car_outlined)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 0, 18, 100),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final v = _filtered[i];
                              return AppCard(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryDark.withAlpha(20),
                                        borderRadius: BorderRadius.circular(12),
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
                                                  fontWeight: FontWeight.w900, fontSize: 15)),
                                          Text(
                                            '${v.brand ?? '-'} ${v.model ?? ''}',
                                            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
                                          ),
                                          Text(
                                            v.customer?.customerName ?? v.customerId,
                                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.edit, color: AppColors.textMuted, size: 20),
                                      onPressed: () => Navigator.push(
                                              context, MaterialPageRoute(builder: (_) => VehicleFormScreen(vehicle: v)))
                                          .then((_) => _load()),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: AppColors.red, size: 20),
                                      onPressed: () => _delete(v),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

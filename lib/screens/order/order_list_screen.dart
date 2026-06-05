import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../services/order_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common.dart';
import 'open_bill_screen.dart';
import 'order_detail_screen.dart';

class OrderListScreen extends StatefulWidget {
  const OrderListScreen({super.key});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  List<OrderModel> _all = [];
  bool _loading = true;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      _all = await OrderService.getAll();
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  List<OrderModel> get _filtered {
    if (_filter == 'all') return _all;
    return _all.where((o) => o.orderStatus == _filter).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Riwayat Order')),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.orange,
        icon: const Icon(Icons.receipt_long, color: Colors.white),
        label: const Text('Open Bill', style: TextStyle(color: Colors.white)),
        onPressed: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => const OpenBillScreen()))
            .then((_) => _load()),
      ),
      body: Column(
        children: [
          // Filter chips
          SizedBox(
            height: 48,
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
              scrollDirection: Axis.horizontal,
              children: [
                _filterChip('all', 'Semua'),
                const SizedBox(width: 8),
                _filterChip('pending', 'Pending'),
                const SizedBox(width: 8),
                _filterChip('process', 'Diproses'),
                const SizedBox(width: 8),
                _filterChip('completed', 'Selesai'),
                const SizedBox(width: 8),
                _filterChip('cancelled', 'Dibatalkan'),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? const EmptyState(message: 'Tidak ada order', icon: Icons.receipt_long_outlined)
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(18, 4, 18, 100),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final o = _filtered[i];
                              return AppCard(
                                padding: const EdgeInsets.all(16),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => OrderDetailScreen(order: o)),
                                ).then((_) => _load()),
                                child: Row(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(10),
                                      decoration: BoxDecoration(
                                        color: AppColors.statusColor(o.orderStatus).withAlpha(20),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Icon(Icons.receipt_long,
                                          color: AppColors.statusColor(o.orderStatus), size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(o.orderCode,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary)),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${o.customer?.customerName ?? o.customerId} • ${o.vehicle?.licensePlate ?? o.vehicleId}',
                                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(rupiah(o.totalAmount),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary)),
                                        ],
                                      ),
                                    ),
                                    StatusPill(status: o.orderStatus),
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

  Widget _filterChip(String key, String label) {
    final active = _filter == key;
    Color color = AppColors.primary;
    if (key == 'pending') color = AppColors.primary;
    if (key == 'process') color = AppColors.orange;
    if (key == 'completed') color = AppColors.green;
    if (key == 'cancelled') color = AppColors.red;

    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: active ? color : Colors.white,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: active ? color : AppColors.border),
          boxShadow: active
              ? [BoxShadow(color: color.withAlpha(40), blurRadius: 6, offset: const Offset(0, 2))]
              : null,
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: active ? Colors.white : AppColors.textMuted)),
      ),
    );
  }
}

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
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Riwayat Order'),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            tooltip: 'Open Bill',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const OpenBillScreen()),
            ).then((_) => _load()),
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.primaryDark,
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: SizedBox(
              height: 36,
              child: ListView(
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
          ),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary))
                : RefreshIndicator(
                    onRefresh: _load,
                    child: _filtered.isEmpty
                        ? EmptyState(
                            message: 'Tidak ada order ditemukan',
                            icon: Icons.receipt_long_outlined,
                            buttonLabel: 'Buat Order Baru',
                            onButton: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => const OpenBillScreen()),
                            ).then((_) => _load()),
                          )
                        : ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                            itemCount: _filtered.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (_, i) {
                              final o = _filtered[i];
                              final statusColor =
                                  AppColors.statusColor(o.orderStatus);
                              return AppCard(
                                padding: const EdgeInsets.all(14),
                                onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) =>
                                          OrderDetailScreen(order: o)),
                                ).then((_) => _load()),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 46,
                                      height: 46,
                                      decoration: BoxDecoration(
                                        color: statusColor.withAlpha(18),
                                        borderRadius: BorderRadius.circular(14),
                                      ),
                                      child: Icon(Icons.receipt_long_rounded,
                                          color: statusColor, size: 22),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(o.orderCode,
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w900,
                                                  fontSize: 14,
                                                  color: AppColors.textPrimary)),
                                          const SizedBox(height: 2),
                                          Text(
                                            '${o.customer?.customerName ?? o.customerId}',
                                            style: const TextStyle(
                                                fontSize: 13,
                                                color: AppColors.textMuted),
                                          ),
                                          const SizedBox(height: 4),
                                          Text(rupiah(o.totalAmount),
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                  fontSize: 13,
                                                  color: AppColors.primary)),
                                        ],
                                      ),
                                    ),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.end,
                                      children: [
                                        StatusPill(status: o.orderStatus),
                                        const SizedBox(height: 6),
                                        Text(
                                          o.vehicle?.licensePlate ?? '',
                                          style: const TextStyle(
                                              fontSize: 11,
                                              color: AppColors.textMuted),
                                        ),
                                      ],
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

  Widget _filterChip(String key, String label) {
    final active = _filter == key;
    final color = key == 'all'
        ? AppColors.primary
        : key == 'pending'
            ? AppColors.primary
            : key == 'process'
                ? AppColors.orange
                : key == 'completed'
                    ? AppColors.green
                    : AppColors.red;

    return GestureDetector(
      onTap: () => setState(() => _filter = key),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? Colors.white : Colors.white.withAlpha(25),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(
              color: active ? Colors.transparent : Colors.white.withAlpha(60)),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? color : Colors.white70,
          ),
        ),
      ),
    );
  }
}

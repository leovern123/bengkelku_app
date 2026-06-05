import 'package:flutter/material.dart';
import '../../models/order_model.dart';
import '../../models/item_model.dart';
import '../../services/order_service.dart';
import '../../services/item_service.dart';
import '../../utils/app_colors.dart';
import '../../widgets/common.dart';
import '../payment/payment_screen.dart';

class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;
  const OrderDetailScreen({super.key, required this.order});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  late OrderModel _order;
  bool _loading = false;
  List<ItemModel> _items = [];

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      _items = await ItemService.getAll();
    } catch (_) {}
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    try {
      _order = await OrderService.getById(_order.orderId);
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _cancel() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Order'),
        content: const Text('Yakin membatalkan order ini? Stok item akan dikembalikan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Tidak')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Batalkan', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await OrderService.cancel(_order.orderId);
      _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Order dibatalkan'), backgroundColor: AppColors.orange));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal membatalkan'), backgroundColor: AppColors.red));
      }
    }
  }

  void _showAddItem() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AddItemSheet(
        items: _items,
        onAdd: (item, qty) async {
          Navigator.pop(context);
          setState(() => _loading = true);
          try {
            await OrderService.addDetail(
                orderId: _order.orderId, itemId: item.itemId, quantity: qty);
            await _refresh();
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text('${item.itemName} ditambahkan'),
                backgroundColor: AppColors.green,
              ));
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Gagal: $e'), backgroundColor: AppColors.red));
              setState(() => _loading = false);
            }
          }
        },
      ),
    );
  }

  Future<void> _deleteDetail(String detailId, String itemName) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Hapus Item'),
        content: Text('Hapus "$itemName" dari order?'),
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
    setState(() => _loading = true);
    try {
      await OrderService.deleteDetail(detailId);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Item dihapus'), backgroundColor: AppColors.orange));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menghapus item'), backgroundColor: AppColors.red));
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_order.orderCode),
        actions: [IconButton(icon: const Icon(Icons.refresh), onPressed: _refresh)],
      ),
      floatingActionButton: _order.canAddItems
          ? FloatingActionButton.extended(
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add, color: Colors.white),
              label: const Text('Tambah Item', style: TextStyle(color: Colors.white)),
              onPressed: _showAddItem,
            )
          : null,
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    const SizedBox(height: 14),
                    _buildInfo(),
                    const SizedBox(height: 14),
                    _buildItems(),
                    const SizedBox(height: 14),
                    _buildTotal(),
                    if (!_order.isCancelled && !_order.isCompleted) ...[
                      const SizedBox(height: 20),
                      _buildActions(),
                    ],
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildHeader() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Text('No. Order', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
            Text(_order.orderCode,
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18, color: AppColors.primary)),
          ]),
          StatusPill(status: _order.orderStatus),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SectionTitle(title: 'Informasi Order'),
          const SizedBox(height: 12),
          _row(Icons.person_outline, 'Pelanggan', _order.customer?.customerName ?? _order.customerId),
          const SizedBox(height: 8),
          _row(Icons.directions_car_outlined, 'Kendaraan',
              '${_order.vehicle?.licensePlate ?? _order.vehicleId} ${_order.vehicle?.brand != null ? '- ${_order.vehicle!.brand} ${_order.vehicle?.model ?? ''}' : ''}'),
        ],
      ),
    );
  }

  Widget _buildItems() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SectionTitle(
            title: 'Item & Jasa (${_order.details.length})',
            action: _order.canAddItems
                ? TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Tambah'),
                    onPressed: _showAddItem,
                  )
                : null,
          ),
          const SizedBox(height: 12),
          if (_order.details.isEmpty)
            const EmptyState(
              message: 'Belum ada item. Tap "Tambah Item" untuk menambahkan sparepart atau jasa.',
              icon: Icons.build_outlined,
            )
          else
            ..._order.details.asMap().entries.map((e) {
              final idx = e.key;
              final d = e.value;
              return Column(
                children: [
                  if (idx > 0) const Divider(height: 1, color: AppColors.border),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withAlpha(15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.inventory_2, size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.item?.itemName ?? d.itemId,
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                              Text('${d.quantity}x  ${rupiah(d.sellingPriceAtTransaction)}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        Text(rupiah(d.subtotal),
                            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.textPrimary)),
                        if (_order.canAddItems)
                          IconButton(
                            icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 20),
                            onPressed: () => _deleteDetail(d.orderDetailId, d.item?.itemName ?? d.itemId),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildTotal() {
    return AppCard(
      color: AppColors.primary.withAlpha(15),
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('TOTAL', style: TextStyle(fontWeight: FontWeight.w900, fontSize: 14, color: AppColors.primary)),
          Text(rupiah(_order.totalAmount),
              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 22, color: AppColors.primary)),
        ],
      ),
    );
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_order.canPay) ...[
          PrimaryButton(
            label: 'Proses Pembayaran',
            icon: Icons.payment,
            color: AppColors.green,
            onPressed: _order.details.isEmpty
                ? null
                : () async {
                    await Navigator.push(
                        context, MaterialPageRoute(builder: (_) => PaymentScreen(order: _order)));
                    _refresh();
                  },
          ),
          if (_order.details.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Tambahkan item terlebih dahulu sebelum bayar',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.orange)),
            ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          icon: const Icon(Icons.cancel_outlined, color: AppColors.red),
          label: const Text('Batalkan Order', style: TextStyle(color: AppColors.red)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.red),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _cancel,
        ),
      ],
    );
  }

  Widget _row(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: AppColors.textMuted),
        const SizedBox(width: 8),
        SizedBox(width: 80, child: Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 13))),
        const Text(': ', style: TextStyle(color: AppColors.textMuted)),
        Expanded(child: Text(value, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13))),
      ],
    );
  }
}

// Bottom sheet tambah item
class _AddItemSheet extends StatefulWidget {
  final List<ItemModel> items;
  final Function(ItemModel, int) onAdd;
  const _AddItemSheet({required this.items, required this.onAdd});

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  String _search = '';
  ItemModel? _selected;
  int _qty = 1;
  String _tab = 'all'; // all, sparepart, jasa

  List<ItemModel> get _filtered {
    var list = widget.items;
    if (_tab == 'sparepart') list = list.where((i) => !i.isService).toList();
    if (_tab == 'jasa') list = list.where((i) => i.isService).toList();
    if (_search.isNotEmpty) {
      list = list.where((i) => i.itemName.toLowerCase().contains(_search.toLowerCase())).toList();
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4, margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Tambah Item / Jasa',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
            child: Row(
              children: [
                _tabBtn('all', 'Semua'),
                const SizedBox(width: 8),
                _tabBtn('sparepart', 'Sparepart'),
                const SizedBox(width: 8),
                _tabBtn('jasa', 'Jasa'),
              ],
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: AppSearchBar(hint: 'Cari item...', onChanged: (v) => setState(() => _search = v)),
          ),
          // Selected item controls
          if (_selected != null)
            Container(
              margin: const EdgeInsets.fromLTRB(18, 0, 18, 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.green.withAlpha(15),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: AppColors.green.withAlpha(80)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_selected!.itemName,
                            style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                        Text(rupiah(_selected!.sellingPrice * _qty),
                            style: const TextStyle(color: AppColors.green, fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.remove_circle, color: AppColors.red, size: 26),
                    onPressed: _qty > 1 ? () => setState(() => _qty--) : null,
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text('$_qty',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                    onPressed: () => widget.onAdd(_selected!, _qty),
                    child: const Text('+  Tambahkan'),
                  ),
                ],
              ),
            ),
          // List
          Expanded(
            child: _filtered.isEmpty
                ? const EmptyState(message: 'Tidak ada item')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 16),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = _filtered[i];
                      final isSelected = _selected?.itemId == item.itemId;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selected = item;
                          _qty = 1;
                        }),
                        child: AppCard(
                          padding: const EdgeInsets.all(12),
                          color: isSelected ? AppColors.primary.withAlpha(15) : AppColors.card,
                          child: Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: (item.isService ? AppColors.orange : AppColors.primary).withAlpha(20),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  item.isService ? Icons.build : Icons.inventory_2,
                                  size: 18,
                                  color: item.isService ? AppColors.orange : AppColors.primary,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.itemName,
                                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                                    Text(
                                      '${rupiah(item.sellingPrice)}${item.stock != null ? ' • Stok: ${item.stock}' : ' • Jasa'}',
                                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected)
                                const Icon(Icons.check_circle, color: AppColors.primary, size: 20)
                              else
                                const Icon(Icons.add_circle_outline, color: AppColors.textMuted, size: 20),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _tabBtn(String key, String label) {
    final active = _tab == key;
    return GestureDetector(
      onTap: () => setState(() => _tab = key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: active ? AppColors.primary : AppColors.border),
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

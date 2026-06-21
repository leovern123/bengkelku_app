import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/order_model.dart';
import '../../models/item_model.dart';
import '../../models/category_model.dart';
import '../../services/order_service.dart';
import '../../services/item_service.dart';
import '../../services/item_category_service.dart';
import '../../utils/app_colors.dart';
import '../../utils/pdf_export.dart';
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
  List<CategoryModel> _categories = [];

  @override
  void initState() {
    super.initState();
    _order = widget.order;
    _loadItems();
  }

  Future<void> _loadItems() async {
    try {
      final itemsFuture = ItemService.getAll();
      final catsFuture = ItemCategoryService.getAll();
      _items = await itemsFuture;
      _categories = await catsFuture;
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
    final reasonCtrl = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Batalkan Order'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Yakin membatalkan order ini? Stok item akan dikembalikan.'),
              const SizedBox(height: 14),
              const Text('Alasan Pembatalan *',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
              const SizedBox(height: 6),
              TextFormField(
                controller: reasonCtrl,
                maxLines: 3,
                autofocus: true,
                decoration: const InputDecoration(hintText: 'Tuliskan alasan pembatalan...'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Alasan wajib diisi' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Tidak')),
          TextButton(
            onPressed: () {
              if (formKey.currentState!.validate()) {
                Navigator.pop(context, reasonCtrl.text.trim());
              }
            },
            child: const Text('Ya, Batalkan', style: TextStyle(color: AppColors.red)),
          ),
        ],
      ),
    );
    if (reason == null || reason.isEmpty) return;
    try {
      await OrderService.cancel(_order.orderId, reason);
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
        categories: _categories,
        onAdd: (cart) async {
          Navigator.pop(context);
          setState(() => _loading = true);
          final List<String> errors = [];
          int successCount = 0;

          for (final entry in cart.entries) {
            final item = entry.key;
            final addedQty = entry.value;
            try {
              final existing = _order.details
                  .where((d) => d.itemId == item.itemId)
                  .firstOrNull;
              if (existing != null) {
                await OrderService.updateDetail(
                    existing.orderDetailId, existing.quantity + addedQty);
              } else {
                await OrderService.addDetail(
                  orderId: _order.orderId,
                  itemId: item.itemId,
                  quantity: addedQty,
                );
              }
              successCount++;
            } catch (e) {
              String msg = item.itemName;
              if (e is DioException && e.response != null) {
                final data = e.response!.data;
                if (data is Map) {
                  final errs = data['errors'];
                  if (errs is Map) {
                    msg += ': ${errs.values.expand((v) => v is List ? v : [v]).join(', ')}';
                  } else {
                    msg += ': ${data['message'] ?? 'error'}';
                  }
                }
              }
              errors.add(msg);
            }
          }

          await _refresh();
          if (!mounted) return;

          if (successCount > 0) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('$successCount item ditambahkan ke order'),
              backgroundColor: AppColors.green,
            ));
          }
          if (errors.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: Text('Gagal: ${errors.join('\n')}'),
              backgroundColor: AppColors.red,
              duration: const Duration(seconds: 5),
            ));
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
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : RefreshIndicator(
              onRefresh: _refresh,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildHeader(),
                    if (_order.isCancelled && (_order.cancelReason ?? '').isNotEmpty) ...[
                      const SizedBox(height: 14),
                      _buildCancelReason(),
                    ],
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
                    if (_order.isCompleted && _order.payment != null) ...[
                      const SizedBox(height: 20),
                      PrimaryButton(
                        label: 'Cetak Struk',
                        icon: Icons.print_outlined,
                        color: AppColors.primary,
                        onPressed: _printStruk,
                      ),
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

  Widget _buildCancelReason() {
    return AppCard(
      color: AppColors.red.withAlpha(15),
      padding: const EdgeInsets.all(14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: AppColors.red, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Alasan Pembatalan',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.red)),
                const SizedBox(height: 3),
                Text(_order.cancelReason!,
                    style: const TextStyle(fontSize: 13, color: AppColors.textPrimary)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfo() {
    final txLabel = _order.isProductSale ? 'Beli Produk Saja' : 'Servis Kendaraan';
    final txColor = _order.isProductSale ? AppColors.green : AppColors.primary;
    final txIcon = _order.isProductSale ? Icons.shopping_cart_outlined : Icons.build_outlined;

    final customerName = _order.customer?.customerName ?? _order.customerId;
    final vehicleLabel = _order.vehicle != null
        ? '${_order.vehicle!.licensePlate}${_order.vehicle!.brand != null ? ' - ${_order.vehicle!.brand} ${_order.vehicle!.model ?? ''}' : ''}'
        : _order.vehicleId;

    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(child: SectionTitle(title: 'Informasi Order')),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: txColor.withAlpha(20),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(txIcon, size: 12, color: txColor),
                    const SizedBox(width: 5),
                    Text(txLabel,
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: txColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _row(Icons.person_outline, 'Pelanggan', customerName ?? 'Walk-in Customer'),
          if (_order.isService) ...[
            const SizedBox(height: 8),
            _row(Icons.two_wheeler, 'Kendaraan', vehicleLabel ?? '-'),
            const SizedBox(height: 8),
            _row(Icons.engineering_outlined, 'Mekanik',
                _order.mechanic?.mechanicName ?? _order.mechanicId ?? '-'),
          ],
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
              message: 'Belum ada item. Tap "Tambah" untuk menambahkan sparepart atau jasa.',
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

  Future<void> _printStruk() async {
    if (_order.payment == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = jsonDecode(prefs.getString('user_data') ?? '{}');
      final kasir = data['name']?.toString() ?? '-';
      await exportStruk(_order, _order.payment!, kasir: kasir);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Gagal mencetak struk'), backgroundColor: AppColors.red));
      }
    }
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

  Future<void> _processOrder() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Mulai Proses Pengerjaan'),
        content: const Text('Tandai order ini sebagai sedang dikerjakan?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Batal')),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ya, Proses', style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _loading = true);
    try {
      await OrderService.process(_order.orderId);
      await _refresh();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Order sedang diproses'), backgroundColor: AppColors.primary));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text('Gagal memproses order'), backgroundColor: AppColors.red));
        setState(() => _loading = false);
      }
    }
  }

  Widget _buildActions() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (_order.canProcess) ...[
          PrimaryButton(
            label: 'Mulai Proses Pengerjaan',
            icon: Icons.build_circle_outlined,
            color: AppColors.primary,
            onPressed: _order.details.isEmpty ? null : _processOrder,
          ),
          if (_order.details.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Tambahkan item terlebih dahulu sebelum memproses',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12, color: AppColors.orange)),
            ),
          const SizedBox(height: 10),
        ],
        if (_order.canPay) ...[
          PrimaryButton(
            label: 'Proses Pembayaran',
            icon: Icons.payment,
            color: AppColors.green,
            onPressed: () async {
              await Navigator.push(
                  context, MaterialPageRoute(builder: (_) => PaymentScreen(order: _order)));
              _refresh();
            },
          ),
          const SizedBox(height: 10),
        ],
        OutlinedButton.icon(
          icon: Icon(Icons.cancel_outlined,
              color: _order.canCancel ? AppColors.red : AppColors.textMuted),
          label: Text('Batalkan Order',
              style: TextStyle(color: _order.canCancel ? AppColors.red : AppColors.textMuted)),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: _order.canCancel ? AppColors.red : AppColors.border),
            padding: const EdgeInsets.symmetric(vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          onPressed: _order.canCancel ? _cancel : null,
        ),
        if (!_order.canCancel && !_order.isCompleted && !_order.isCancelled)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text('Order yang sedang diproses tidak dapat dibatalkan',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
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

// Bottom sheet tambah item — multi-select dengan cart
class _AddItemSheet extends StatefulWidget {
  final List<ItemModel> items;
  final List<CategoryModel> categories;
  final Function(Map<ItemModel, int>) onAdd;
  const _AddItemSheet({
    required this.items,
    required this.categories,
    required this.onAdd,
  });

  @override
  State<_AddItemSheet> createState() => _AddItemSheetState();
}

class _AddItemSheetState extends State<_AddItemSheet> {
  String _search = '';
  String _tab = 'all';
  int? _selectedCategoryId;

  final Map<String, MapEntry<ItemModel, int>> _cart = {};

  List<CategoryModel> get _visibleCategories {
    if (_tab == 'sparepart') return widget.categories.where((c) => c.itemTypeId == 1).toList();
    if (_tab == 'jasa') return widget.categories.where((c) => c.itemTypeId == 2).toList();
    return widget.categories;
  }

  List<ItemModel> get _filtered {
    var list = widget.items;
    if (_tab == 'sparepart') list = list.where((i) => !i.isService).toList();
    if (_tab == 'jasa') list = list.where((i) => i.isService).toList();
    if (_selectedCategoryId != null) {
      list = list.where((i) => i.itemCategoryId == _selectedCategoryId).toList();
    }
    if (_search.isNotEmpty) {
      list = list.where((i) => i.itemName.toLowerCase().contains(_search.toLowerCase())).toList();
    }
    return list;
  }

  int get _cartTotal => _cart.values.fold(0, (sum, e) => sum + e.value);

  void _onTabChanged(String tab) {
    setState(() {
      _tab = tab;
      _selectedCategoryId = null;
    });
  }

  bool _isOutOfStock(ItemModel item) {
    final qtyInCart = _cart[item.itemId]?.value ?? 0;
    return item.stock != null && (item.stock! - qtyInCart) <= 0;
  }

  void _tapItem(ItemModel item) {
    if (_isOutOfStock(item)) return;
    setState(() {
      if (_cart.containsKey(item.itemId)) {
        final current = _cart[item.itemId]!;
        final maxQty = item.stock ?? current.value + 1;
        if (current.value + 1 > maxQty) return;
        _cart[item.itemId] = MapEntry(item, current.value + 1);
      } else {
        _cart[item.itemId] = MapEntry(item, 1);
      }
    });
  }

  void _setQty(String itemId, int qty) {
    setState(() {
      if (qty <= 0) {
        _cart.remove(itemId);
      } else {
        final item = _cart[itemId]!.key;
        if (item.stock != null && qty > item.stock!) return;
        _cart[itemId] = MapEntry(item, qty);
      }
    });
  }

  Map<ItemModel, int> get _cartAsMap =>
      {for (final e in _cart.values) e.key: e.value};

  @override
  Widget build(BuildContext context) {
    final cats = _visibleCategories;

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(color: AppColors.border, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          // Header
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
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 6),
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

          // Category dropdown
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: DropdownButtonFormField<int?>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(
                hintText: 'Semua Kategori',
                prefixIcon: Icon(Icons.category_outlined, color: AppColors.textMuted),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua Kategori')),
                ...cats.map((c) => DropdownMenuItem(value: c.itemCategoryId, child: Text(c.categoryName))),
              ],
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
          ),

          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: AppSearchBar(hint: 'Cari item...', onChanged: (v) => setState(() => _search = v)),
          ),

          // Item list
          Expanded(
            child: _filtered.isEmpty
                ? const EmptyState(message: 'Tidak ada item')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = _filtered[i];
                      final inCart = _cart.containsKey(item.itemId);
                      final qty = inCart ? _cart[item.itemId]!.value : 0;
                      final effectiveStock = item.stock != null ? item.stock! - qty : null;
                      final outOfStock = effectiveStock != null && effectiveStock <= 0;
                      final atMaxStock = effectiveStock != null && effectiveStock <= 0;
                      return AppCard(
                        padding: const EdgeInsets.all(12),
                        color: outOfStock
                            ? AppColors.border.withAlpha(60)
                            : (inCart ? AppColors.primary.withAlpha(12) : AppColors.card),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: (item.isService ? AppColors.orange : AppColors.primary)
                                    .withAlpha(outOfStock ? 8 : 20),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                item.isService ? Icons.build : Icons.inventory_2,
                                size: 18,
                                color: outOfStock
                                    ? AppColors.textMuted
                                    : (item.isService ? AppColors.orange : AppColors.primary),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: GestureDetector(
                                onTap: outOfStock ? null : () => _tapItem(item),
                                behavior: HitTestBehavior.opaque,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.itemName,
                                        style: TextStyle(
                                            fontWeight: FontWeight.w700,
                                            fontSize: 13,
                                            color: outOfStock ? AppColors.textMuted : AppColors.textPrimary)),
                                    Text(
                                      outOfStock
                                          ? '${rupiah(item.sellingPrice)} • Stok Habis'
                                          : '${rupiah(item.sellingPrice)}${effectiveStock != null ? ' • Stok: $effectiveStock' : ' • Jasa'}',
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: outOfStock ? AppColors.red : AppColors.textMuted,
                                          fontWeight: outOfStock ? FontWeight.w600 : FontWeight.normal),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            if (outOfStock)
                              const Icon(Icons.block, color: AppColors.textMuted, size: 24)
                            else if (item.isService)
                              GestureDetector(
                                onTap: () => setState(() {
                                  if (inCart) {
                                    _cart.remove(item.itemId);
                                  } else {
                                    _cart[item.itemId] = MapEntry(item, 1);
                                  }
                                }),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 150),
                                  width: 28,
                                  height: 28,
                                  decoration: BoxDecoration(
                                    color: inCart ? AppColors.orange : Colors.transparent,
                                    shape: BoxShape.circle,
                                    border: Border.all(
                                      color: inCart ? AppColors.orange : AppColors.textMuted,
                                      width: 2,
                                    ),
                                  ),
                                  child: inCart
                                      ? const Icon(Icons.check, color: Colors.white, size: 16)
                                      : null,
                                ),
                              )
                            else if (inCart) ...[
                              GestureDetector(
                                onTap: () => _setQty(item.itemId, qty - 1),
                                child: const Icon(Icons.remove_circle, color: AppColors.red, size: 26),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                child: Text('$qty',
                                    style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                              ),
                              GestureDetector(
                                onTap: atMaxStock ? null : () => _setQty(item.itemId, qty + 1),
                                child: Icon(Icons.add_circle,
                                    color: atMaxStock ? AppColors.textMuted : AppColors.primary, size: 26),
                              ),
                            ] else
                              GestureDetector(
                                onTap: () => _tapItem(item),
                                child: const Icon(Icons.add_circle_outline, color: AppColors.textMuted, size: 26),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Cart summary + tombol tambah
          if (_cart.isNotEmpty)
            Container(
              margin: const EdgeInsets.fromLTRB(18, 8, 18, 16),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withAlpha(40),
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text('$_cartTotal item',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rupiah(_cart.values.fold(0.0, (s, e) => s + e.key.sellingPrice * e.value)),
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 14),
                    ),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    onPressed: () => widget.onAdd(_cartAsMap),
                    child: const Text('Tambahkan', style: TextStyle(fontWeight: FontWeight.w900)),
                  ),
                ],
              ),
            ),

          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _tabBtn(String key, String label) {
    final active = _tab == key;
    return GestureDetector(
      onTap: () => _onTabChanged(key),
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

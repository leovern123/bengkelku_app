import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../models/customer_model.dart';
import '../../models/vehicle_model.dart';
import '../../models/mechanic_model.dart';
import '../../models/item_model.dart';
import '../../models/category_model.dart';
import '../../services/customer_service.dart';
import '../../services/vehicle_service.dart';
import '../../services/mechanic_service.dart';
import '../../services/item_service.dart';
import '../../services/item_category_service.dart';
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
  // ── Jenis transaksi ────────────────────────────────────────────────────
  String _txType = 'service'; // 'service' | 'product_sale'

  // ── Data master ────────────────────────────────────────────────────────
  List<CustomerModel> _customers = [];
  List<VehicleModel> _vehicles = [];
  List<MechanicModel> _mechanics = [];
  List<ItemModel> _items = [];
  List<CategoryModel> _categories = [];

  // ── Servis: pilihan ────────────────────────────────────────────────────
  bool _newCustomer = false;
  bool _newVehicle = false;
  CustomerModel? _selectedCustomer;
  VehicleModel? _selectedVehicle;
  MechanicModel? _selectedMechanic;

  // ── Beli Produk: pilihan ───────────────────────────────────────────────
  CustomerModel? _saleCustomer; // opsional
  // cart: itemId → {item, qty}
  final Map<String, MapEntry<ItemModel, int>> _cart = {};

  // ── New customer/vehicle controllers ──────────────────────────────────
  final _newNameCtrl = TextEditingController();
  final _plateCtrl = TextEditingController();
  final _brandCtrl = TextEditingController();
  final _modelCtrl = TextEditingController();

  // ── State ──────────────────────────────────────────────────────────────
  bool _loadingData = true;
  bool _loadingVehicles = false;
  bool _submitting = false;
  final _formKey = GlobalKey<FormState>();

  // ══════════════════════════════════════════════════════════════════════
  // Lifecycle
  // ══════════════════════════════════════════════════════════════════════

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  @override
  void dispose() {
    _newNameCtrl.dispose();
    _plateCtrl.dispose();
    _brandCtrl.dispose();
    _modelCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    try {
      final results = await Future.wait([
        CustomerService.getAll(),
        MechanicService.getAll(),
        ItemService.getAll(),
        ItemCategoryService.getAll(),
      ]);
      if (mounted) {
        setState(() {
          _customers = results[0] as List<CustomerModel>;
          _mechanics = results[1] as List<MechanicModel>;
          _items = results[2] as List<ItemModel>;
          _categories = results[3] as List<CategoryModel>;
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingData = false);
  }

  // ══════════════════════════════════════════════════════════════════════
  // Servis: Vehicle loader
  // ══════════════════════════════════════════════════════════════════════

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

  // ══════════════════════════════════════════════════════════════════════
  // Cart helpers (product_sale)
  // ══════════════════════════════════════════════════════════════════════

  List<ItemModel> get _sparepartItems =>
      _items.where((i) => !i.isService).toList();

  void _setCartQty(ItemModel item, int qty) {
    setState(() {
      if (qty <= 0) {
        _cart.remove(item.itemId);
      } else {
        _cart[item.itemId] = MapEntry(item, qty);
      }
    });
  }

  double get _cartTotal => _cart.values.fold(
      0.0, (sum, e) => sum + e.key.sellingPrice * e.value);

  // ══════════════════════════════════════════════════════════════════════
  // Validation helpers
  // ══════════════════════════════════════════════════════════════════════

  bool get _canSubmit {
    if (_txType == 'service') {
      final customerOk = _newCustomer
          ? _newNameCtrl.text.trim().isNotEmpty
          : _selectedCustomer != null;
      final vehicleOk = _newVehicle
          ? _plateCtrl.text.trim().isNotEmpty
          : _selectedVehicle != null;
      return customerOk && vehicleOk && _selectedMechanic != null;
    } else {
      return _cart.isNotEmpty;
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // Submit — Servis Kendaraan
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _submitService() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = jsonDecode(prefs.getString('user_data') ?? '{}');
      final userId = userData['user_id'] ?? '';

      CustomerModel customer;
      if (_newCustomer) {
        customer = await CustomerService.create(_newNameCtrl.text.trim());
      } else {
        customer = _selectedCustomer!;
      }

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

      final order = await OrderService.create(
        transactionType: 'service',
        customerId: customer.customerId,
        vehicleId: vehicle.vehicleId,
        userId: userId,
        mechanicId: _selectedMechanic?.mechanicId,
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Open bill servis berhasil dibuka'),
          backgroundColor: AppColors.green));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
      );
    } catch (e) {
      _handleError(e, 'Gagal membuka order servis');
    }
  }

  // ══════════════════════════════════════════════════════════════════════
  // Submit — Beli Produk Saja
  // ══════════════════════════════════════════════════════════════════════

  Future<void> _submitProductSale() async {
    setState(() => _submitting = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final userData = jsonDecode(prefs.getString('user_data') ?? '{}');
      final userId = userData['user_id'] ?? '';

      // 1. Buat order (customer opsional, tanpa vehicle)
      final order = await OrderService.create(
        transactionType: 'product_sale',
        customerId: _saleCustomer?.customerId,
        userId: userId,
      );

      // 2. Tambahkan semua item dari cart
      for (final entry in _cart.entries) {
        await OrderService.addDetail(
          orderId: order.orderId,
          itemId: entry.key,
          quantity: entry.value.value,
        );
      }

      // 3. Auto-process: langsung ke status process agar Proses Pembayaran tampil
      await OrderService.process(order.orderId);

      // 4. Fetch order terbaru (dengan total yang sudah dihitung)
      final updated = await OrderService.getById(order.orderId);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Order berhasil dibuat'),
          backgroundColor: AppColors.green));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: updated)),
      );
    } catch (e) {
      _handleError(e, 'Gagal membuat order');
    }
  }

  void _handleError(Object e, String fallback) {
    if (!mounted) return;
    String msg = fallback;
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

  // ══════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Buka Open Bill')),
      body: _loadingData
          ? const Center(child: CircularProgressIndicator(color: AppColors.primary))
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── Jenis Transaksi ────────────────────────────────
                    _buildTxTypeCard(),
                    const SizedBox(height: 14),

                    // ── Servis: Customer ───────────────────────────────
                    if (_txType == 'service') ...[
                      _buildCustomerCard(),
                      const SizedBox(height: 14),
                      _buildVehicleCard(),
                      const SizedBox(height: 14),
                      _buildMechanicCard(),
                    ],

                    // ── Beli Produk: Customer opsional + Cart ──────────
                    if (_txType == 'product_sale') ...[
                      _buildSaleCustomerCard(),
                      const SizedBox(height: 14),
                      _buildCartCard(),
                    ],

                    // ── Preview ────────────────────────────────────────
                    if (_canSubmit) ...[
                      const SizedBox(height: 14),
                      _buildPreview(),
                    ],

                    const SizedBox(height: 28),
                    PrimaryButton(
                      label: _txType == 'service' ? 'Buka Order Servis' : 'Buat Order Pembelian',
                      icon: _txType == 'service' ? Icons.build_circle_outlined : Icons.shopping_cart_checkout,
                      isLoading: _submitting,
                      color: AppColors.orange,
                      onPressed: _canSubmit
                          ? (_txType == 'service' ? _submitService : _submitProductSale)
                          : null,
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  // ── Transaction Type Card ──────────────────────────────────────────────

  Widget _buildTxTypeCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepLabel('', 'Jenis Transaksi', icon: Icons.receipt_long_outlined),
          const SizedBox(height: 12),
          _modeToggle(
            leftLabel: '🔧  Servis Kendaraan',
            rightLabel: '🛒  Beli Produk Saja',
            isRight: _txType == 'product_sale',
            onChanged: (isRight) {
              setState(() {
                _txType = isRight ? 'product_sale' : 'service';
                // Reset semua pilihan saat ganti tipe
                _selectedCustomer = null;
                _selectedVehicle = null;
                _vehicles = [];
                _newCustomer = false;
                _newVehicle = false;
                _newNameCtrl.clear();
                _plateCtrl.clear();
                _brandCtrl.clear();
                _modelCtrl.clear();
                _saleCustomer = null;
                _cart.clear();
              });
            },
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: (_txType == 'service' ? AppColors.primary : AppColors.green).withAlpha(15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              _txType == 'service'
                  ? 'Pilih pelanggan, kendaraan, dan mekanik. Item & jasa ditambahkan setelah order dibuka.'
                  : 'Tambahkan produk ke keranjang. Order langsung siap bayar setelah dibuat.',
              style: TextStyle(
                fontSize: 12,
                color: _txType == 'service' ? AppColors.primary : AppColors.green,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Service: Customer Card ─────────────────────────────────────────────

  Widget _buildCustomerCard() {
    return AppCard(
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
              _newVehicle = v;
              _newNameCtrl.clear();
            }),
          ),
          const SizedBox(height: 12),
          if (_newCustomer)
            TextFormField(
              controller: _newNameCtrl,
              decoration: const InputDecoration(
                labelText: 'Nama Pelanggan',
                prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
              ),
              onChanged: (_) => setState(() {}),
              validator: (v) =>
                  _txType == 'service' && _newCustomer && (v == null || v.trim().isEmpty)
                      ? 'Nama pelanggan wajib diisi'
                      : null,
            )
          else
            DropdownButtonFormField<CustomerModel>(
              initialValue: _selectedCustomer,
              decoration: const InputDecoration(
                hintText: 'Pilih pelanggan',
                prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
              ),
              items: _customers
                  .map((c) => DropdownMenuItem(value: c, child: Text(c.customerName)))
                  .toList(),
              onChanged: _onCustomerSelected,
              validator: (_) =>
                  _txType == 'service' && !_newCustomer && _selectedCustomer == null
                      ? 'Pilih pelanggan'
                      : null,
            ),
        ],
      ),
    );
  }

  // ── Service: Vehicle Card ──────────────────────────────────────────────

  Widget _buildVehicleCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepLabel('2', 'Kendaraan'),
          const SizedBox(height: 12),
          if (!_newCustomer && _selectedCustomer != null && _vehicles.isNotEmpty) ...[
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
                    child: CircularProgressIndicator(color: AppColors.primary)))
          else if (_newVehicle || _newCustomer)
            _vehicleNewFields()
          else
            DropdownButtonFormField<VehicleModel>(
              initialValue: _selectedVehicle,
              decoration: InputDecoration(
                hintText: _selectedCustomer == null ? 'Pilih pelanggan dulu' : 'Pilih kendaraan',
                prefixIcon: const Icon(Icons.directions_car_outlined, color: AppColors.textMuted),
              ),
              items: _vehicles
                  .map((v) => DropdownMenuItem(value: v, child: Text(v.displayName)))
                  .toList(),
              onChanged: _selectedCustomer == null
                  ? null
                  : (v) => setState(() => _selectedVehicle = v),
              validator: (_) =>
                  _txType == 'service' && !_newVehicle && _selectedVehicle == null && _selectedCustomer != null
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
              child: Text('Pelanggan belum memiliki kendaraan.',
                  style: TextStyle(color: AppColors.orange, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  // ── Service: Mechanic Card ─────────────────────────────────────────────

  Widget _buildMechanicCard() {
    return AppCard(
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
              prefixIcon: Icon(Icons.engineering_outlined, color: AppColors.textMuted),
            ),
            items: _mechanics
                .map((m) => DropdownMenuItem(
                      value: m,
                      child: Text(m.mechanicName +
                          (m.phoneNumber != null ? '  •  ${m.phoneNumber}' : '')),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedMechanic = v),
            validator: (_) =>
                _txType == 'service' && _selectedMechanic == null ? 'Pilih mekanik' : null,
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
    );
  }

  // ── Product Sale: Optional Customer ───────────────────────────────────

  Widget _buildSaleCustomerCard() {
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _stepLabel('1', 'Pelanggan', subtitle: 'Opsional'),
          const SizedBox(height: 12),
          DropdownButtonFormField<CustomerModel?>(
            initialValue: _saleCustomer,
            decoration: const InputDecoration(
              hintText: 'Tanpa pelanggan (walk-in)',
              prefixIcon: Icon(Icons.person_outline, color: AppColors.textMuted),
            ),
            items: [
              const DropdownMenuItem<CustomerModel?>(
                value: null,
                child: Text('Tanpa pelanggan (walk-in)',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
              ..._customers.map((c) => DropdownMenuItem<CustomerModel?>(
                    value: c,
                    child: Text(c.customerName),
                  )),
            ],
            onChanged: (v) => setState(() => _saleCustomer = v),
          ),
        ],
      ),
    );
  }

  // ── Product Sale: Cart Card ────────────────────────────────────────────

  Widget _buildCartCard() {
    final cartItems = _cart.values.toList();
    return AppCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _stepLabel('2', 'Produk'),
              const Spacer(),
              TextButton.icon(
                icon: const Icon(Icons.add_shopping_cart, size: 16),
                label: const Text('Pilih Produk'),
                onPressed: _showProductPicker,
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (cartItems.isEmpty)
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              alignment: Alignment.center,
              child: const Text(
                'Belum ada produk. Tap "Pilih Produk" untuk menambahkan.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
            )
          else ...[
            ...cartItems.map((entry) {
              final item = entry.key;
              final qty = entry.value;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withAlpha(15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(Icons.inventory_2, size: 16, color: AppColors.primary),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(item.itemName,
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text(rupiah(item.sellingPrice),
                          style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
                    ]),
                  ),
                  // Qty control
                  GestureDetector(
                    onTap: () => _setCartQty(item, qty - 1),
                    child: const Icon(Icons.remove_circle, color: AppColors.red, size: 24),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    child: Text('$qty',
                        style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
                  ),
                  GestureDetector(
                    onTap: () => _setCartQty(item, qty + 1),
                    child: const Icon(Icons.add_circle, color: AppColors.primary, size: 24),
                  ),
                ]),
              );
            }),
            const Divider(height: 16),
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Text('Total ${_cart.length} produk',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              Text(rupiah(_cartTotal),
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w900, color: AppColors.primary)),
            ]),
          ],
        ],
      ),
    );
  }

  void _showProductPicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ProductPickerSheet(
        items: _sparepartItems,
        categories: _categories.where((c) => c.itemTypeId == 1).toList(),
        initialCart: Map.fromEntries(_cart.entries),
        onConfirm: (updatedCart) {
          setState(() {
            _cart.clear();
            _cart.addAll(updatedCart);
          });
        },
      ),
    );
  }

  // ── Preview ────────────────────────────────────────────────────────────

  Widget _buildPreview() {
    String line1 = '';
    String line2 = '';

    if (_txType == 'service') {
      line1 = _newCustomer ? _newNameCtrl.text.trim() : _selectedCustomer!.customerName;
      line2 = _newVehicle
          ? '${_plateCtrl.text.trim()}${_brandCtrl.text.trim().isNotEmpty ? ' - ${_brandCtrl.text.trim()}' : ''}'
          : _selectedVehicle!.displayName;
    } else {
      line1 = _saleCustomer?.customerName ?? 'Walk-in Customer';
      line2 = '${_cart.length} produk  •  ${rupiah(_cartTotal)}';
    }

    return AppCard(
      color: AppColors.green.withAlpha(15),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: AppColors.green, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(line1,
                  style: const TextStyle(fontWeight: FontWeight.w900, color: AppColors.green)),
              Text(line2, style: const TextStyle(fontSize: 13, color: AppColors.green)),
            ]),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════
  // Helper widgets
  // ══════════════════════════════════════════════════════════════════════

  Widget _vehicleNewFields() {
    return Column(
      children: [
        TextFormField(
          controller: _plateCtrl,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: 'Plat Nomor',
            prefixIcon: Icon(Icons.directions_car_outlined, color: AppColors.textMuted),
          ),
          onChanged: (_) => setState(() {}),
          validator: (v) =>
              _txType == 'service' && _newVehicle && (v == null || v.trim().isEmpty)
                  ? 'Plat nomor wajib diisi'
                  : null,
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _brandCtrl,
          decoration: const InputDecoration(
            labelText: 'Merk (opsional)',
            prefixIcon: Icon(Icons.branding_watermark_outlined, color: AppColors.textMuted),
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _modelCtrl,
          decoration: const InputDecoration(
            labelText: 'Tipe/Model (opsional)',
            prefixIcon: Icon(Icons.car_repair_outlined, color: AppColors.textMuted),
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

  Widget _stepLabel(String num, String label,
      {String? subtitle, IconData? icon}) {
    return Row(
      children: [
        if (num.isNotEmpty)
          Container(
            width: 26,
            height: 26,
            decoration: BoxDecoration(
                color: AppColors.primary, borderRadius: BorderRadius.circular(99)),
            child: Center(
                child: Text(num,
                    style: const TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13))),
          )
        else if (icon != null)
          Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(label,
            style: const TextStyle(
                fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
        if (subtitle != null) ...[
          const SizedBox(width: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.orange.withAlpha(30),
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(subtitle,
                style: const TextStyle(
                    fontSize: 10, fontWeight: FontWeight.w700, color: AppColors.orange)),
          ),
        ],
      ],
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════
// Product Picker Bottom Sheet (sparepart only)
// ══════════════════════════════════════════════════════════════════════════

class _ProductPickerSheet extends StatefulWidget {
  final List<ItemModel> items;
  final List<CategoryModel> categories;
  final Map<String, MapEntry<ItemModel, int>> initialCart;
  final ValueChanged<Map<String, MapEntry<ItemModel, int>>> onConfirm;

  const _ProductPickerSheet({
    required this.items,
    required this.categories,
    required this.initialCart,
    required this.onConfirm,
  });

  @override
  State<_ProductPickerSheet> createState() => _ProductPickerSheetState();
}

class _ProductPickerSheetState extends State<_ProductPickerSheet> {
  String _search = '';
  int? _selectedCategoryId;
  late final Map<String, MapEntry<ItemModel, int>> _cart;

  @override
  void initState() {
    super.initState();
    _cart = Map.from(widget.initialCart);
  }

  List<ItemModel> get _filtered {
    var list = widget.items;
    if (_selectedCategoryId != null) {
      list = list.where((i) => i.itemCategoryId == _selectedCategoryId).toList();
    }
    if (_search.isNotEmpty) {
      list = list.where((i) => i.itemName.toLowerCase().contains(_search.toLowerCase())).toList();
    }
    return list;
  }

  int get _totalQty => _cart.values.fold(0, (s, e) => s + e.value);

  void _setQty(ItemModel item, int qty) {
    setState(() {
      if (qty <= 0) {
        _cart.remove(item.itemId);
      } else {
        _cart[item.itemId] = MapEntry(item, qty);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
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
                const Text('Pilih Produk',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          // Category dropdown
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 4, 18, 4),
            child: DropdownButtonFormField<int?>(
              initialValue: _selectedCategoryId,
              decoration: const InputDecoration(
                hintText: 'Semua Kategori',
                prefixIcon: Icon(Icons.category_outlined, color: AppColors.textMuted),
                isDense: true,
              ),
              items: [
                const DropdownMenuItem(value: null, child: Text('Semua Kategori')),
                ...widget.categories
                    .map((c) => DropdownMenuItem(value: c.itemCategoryId, child: Text(c.categoryName))),
              ],
              onChanged: (v) => setState(() => _selectedCategoryId = v),
            ),
          ),
          // Search
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
            child: AppSearchBar(hint: 'Cari produk...', onChanged: (v) => setState(() => _search = v)),
          ),
          // List
          Expanded(
            child: _filtered.isEmpty
                ? const EmptyState(message: 'Tidak ada produk')
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(18, 0, 18, 8),
                    itemCount: _filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final item = _filtered[i];
                      final inCart = _cart.containsKey(item.itemId);
                      final qty = inCart ? _cart[item.itemId]!.value : 0;
                      final isOutOfStock = (item.stock ?? 0) <= 0;
                      return AppCard(
                        padding: const EdgeInsets.all(12),
                        color: inCart ? AppColors.primary.withAlpha(12) : AppColors.card,
                        child: Row(children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withAlpha(20),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.inventory_2, size: 18, color: AppColors.primary),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: GestureDetector(
                              onTap: isOutOfStock ? null : () => _setQty(item, qty + 1),
                              behavior: HitTestBehavior.opaque,
                              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                                Text(item.itemName,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 13,
                                        color: isOutOfStock ? AppColors.textMuted : AppColors.textPrimary)),
                                Text(
                                  '${rupiah(item.sellingPrice)}  •  Stok: ${item.stock ?? 0}',
                                  style: TextStyle(
                                      fontSize: 12,
                                      color: isOutOfStock ? AppColors.red : AppColors.textMuted),
                                ),
                              ]),
                            ),
                          ),
                          if (inCart) ...[
                            GestureDetector(
                              onTap: () => _setQty(item, qty - 1),
                              child: const Icon(Icons.remove_circle, color: AppColors.red, size: 26),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 10),
                              child: Text('$qty',
                                  style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16)),
                            ),
                            GestureDetector(
                              onTap: isOutOfStock ? null : () => _setQty(item, qty + 1),
                              child: Icon(Icons.add_circle,
                                  color: isOutOfStock ? AppColors.border : AppColors.primary, size: 26),
                            ),
                          ] else
                            GestureDetector(
                              onTap: isOutOfStock ? null : () => _setQty(item, qty + 1),
                              child: Icon(Icons.add_circle_outline,
                                  color: isOutOfStock ? AppColors.border : AppColors.textMuted, size: 26),
                            ),
                        ]),
                      );
                    },
                  ),
          ),
          // Confirm button
          Container(
            margin: const EdgeInsets.fromLTRB(18, 8, 18, 16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: _totalQty > 0 ? AppColors.primary : AppColors.border,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withAlpha(40),
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text('$_totalQty item',
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
                onPressed: _totalQty > 0
                    ? () {
                        widget.onConfirm(_cart);
                        Navigator.pop(context);
                      }
                    : null,
                child: const Text('Konfirmasi', style: TextStyle(fontWeight: FontWeight.w900)),
              ),
            ]),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }
}

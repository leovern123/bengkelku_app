import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../models/order_model.dart';
import '../services/auth_service.dart';
import '../services/order_service.dart';
import '../services/report_service.dart';
import '../utils/app_colors.dart';
import '../utils/notification_service.dart';
import '../widgets/common.dart';
import 'order/order_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserModel? _user;

  // Stats
  int _pending = 0;
  int _process = 0;
  int _completed = 0;
  double _income = 0;
  List<OrderModel> _recentOrders = [];

  // Notifications
  List<StockReport> _lowStock = [];
  List<OrderModel> _pendingOrders = [];
  List<OrderModel> _processOrders = [];
  int get _notifCount => _lowStock.length + _pendingOrders.length;

  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadUser();
    _loadStats();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_data');
    if (data != null && mounted) {
      setState(() => _user = UserModel.fromJson(jsonDecode(data)));
    }
  }

  Future<void> _loadStats() async {
    setState(() => _loadingStats = true);

    List<OrderModel> orders = [];
    List<StockReport> lowStock = [];

    // Load orders
    await OrderService.getAll().then((result) {
      orders = result;
      if (!mounted) return;
      setState(() {
        _pending = orders.where((o) => o.orderStatus == 'pending').length;
        _process = orders.where((o) => o.orderStatus == 'process').length;
        _completed = orders.where((o) => o.orderStatus == 'completed').length;
        _recentOrders = orders.take(5).toList();
        _pendingOrders = orders.where((o) => o.orderStatus == 'pending').toList();
        _processOrders = orders.where((o) => o.orderStatus == 'process').toList();
        _loadingStats = false;
      });
    }).catchError((_) {
      if (mounted) setState(() => _loadingStats = false);
    });

    // Load income summary (admin only — fails silently for kasir)
    ReportService.getSummary().then((summary) {
      if (!mounted) return;
      setState(() => _income = summary.totalIncome);
    }).catchError((_) {});

    // Load stock alerts then fire notifications
    await ReportService.getStock().then((stock) {
      lowStock = stock.where((s) => s.isLow).toList();
      if (!mounted) return;
      setState(() => _lowStock = lowStock);
    }).catchError((_) {});

    // Kirim notifikasi nyata untuk masalah baru
    NotificationService.checkAndNotify(
      lowStock: lowStock,
      pendingOrders: _pendingOrders,
    );
  }

  Future<void> _logout() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Keluar', style: TextStyle(fontWeight: FontWeight.w900)),
        content: const Text('Yakin ingin keluar dari aplikasi?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal')),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.red,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    if (ok != true) return;
    try {
      await AuthService.logout();
    } catch (_) {}
    await NotificationService.clearTracking();
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  void _dismissStockAlert(String itemId) =>
      setState(() => _lowStock.removeWhere((s) => s.itemId == itemId));

  void _dismissOrderAlert(String orderId) => setState(() {
        _pendingOrders.removeWhere((o) => o.orderId == orderId);
        _processOrders.removeWhere((o) => o.orderId == orderId);
      });

  void _dismissAllAlerts() => setState(() {
        _lowStock.clear();
        _pendingOrders.clear();
        _processOrders.clear();
      });

  void _showNotifications() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _NotificationSheet(
        lowStock: _lowStock,
        pendingOrders: _pendingOrders,
        processOrders: _processOrders,
        onDismissStock: _dismissStockAlert,
        onDismissOrder: _dismissOrderAlert,
        onDismissAll: _dismissAllAlerts,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _user?.isAdmin ?? false;

    final menus = <Map<String, dynamic>>[
      {'icon': Icons.receipt_long_rounded, 'label': 'Open Bill', 'route': '/open-bill', 'color': AppColors.orange},
      {'icon': Icons.history_rounded, 'label': 'Riwayat', 'route': '/orders', 'color': AppColors.primaryDark},
      {'icon': Icons.people_rounded, 'label': 'Pelanggan', 'route': '/customers', 'color': AppColors.primary},
      {'icon': Icons.two_wheeler_rounded, 'label': 'Kendaraan', 'route': '/vehicles', 'color': AppColors.primaryDark},
      {'icon': Icons.inventory_2_rounded, 'label': 'Produk', 'route': '/items', 'color': AppColors.green},
      if (isAdmin) ...[
        {'icon': Icons.category_rounded, 'label': 'Kategori', 'route': '/categories', 'color': AppColors.primary},
        {'icon': Icons.business_rounded, 'label': 'Supplier', 'route': '/suppliers', 'color': AppColors.primaryDark},
        {'icon': Icons.engineering_rounded, 'label': 'Mekanik', 'route': '/mechanics', 'color': AppColors.green},
        {'icon': Icons.money_off_rounded, 'label': 'Pengeluaran', 'route': '/expenses', 'color': AppColors.red},
        {'icon': Icons.bar_chart_rounded, 'label': 'Laporan', 'route': '/reports', 'color': AppColors.orange},
      ],
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      body: RefreshIndicator(
        onRefresh: _loadStats,
        child: CustomScrollView(
          slivers: [
            // ── Header ────────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 175,
              pinned: true,
              automaticallyImplyLeading: false,
              backgroundColor: AppColors.primaryDark,
              elevation: 0,
              actions: [
                // Notification bell with badge
                Stack(
                  alignment: Alignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.notifications_outlined, color: Colors.white),
                      onPressed: _showNotifications,
                    ),
                    if (_notifCount > 0)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 17,
                          height: 17,
                          decoration: BoxDecoration(
                            color: AppColors.red,
                            shape: BoxShape.circle,
                            border: Border.all(color: AppColors.primaryDark, width: 1.5),
                          ),
                          child: Center(
                            child: Text(
                              _notifCount > 9 ? '9+' : '$_notifCount',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.logout_rounded, color: Colors.white),
                  tooltip: 'Keluar',
                  onPressed: _logout,
                ),
                const SizedBox(width: 4),
              ],
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
                      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withAlpha(25),
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  isAdmin
                                      ? Icons.admin_panel_settings_rounded
                                      : Icons.point_of_sale_rounded,
                                  color: Colors.white,
                                  size: 26,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Selamat datang,',
                                        style: TextStyle(
                                            fontSize: 12, color: Colors.white70)),
                                    Text(
                                      _user?.name ?? '-',
                                      style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w900,
                                          color: Colors.white),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isAdmin
                                      ? AppColors.orange.withAlpha(200)
                                      : Colors.white.withAlpha(35),
                                  borderRadius: BorderRadius.circular(99),
                                ),
                                child: Text(
                                  isAdmin ? 'ADMIN' : 'KASIR',
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _user?.email ?? '',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.white54),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),

            // ── Content ───────────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 120),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  // ── Stat Cards ─────────────────────────────────────────
                  _loadingStats
                      ? const SizedBox(
                          height: 88,
                          child: Center(
                            child: CircularProgressIndicator(
                                color: AppColors.primary, strokeWidth: 2),
                          ),
                        )
                      : _StatsRow(
                          pending: _pending,
                          process: _process,
                          completed: _completed,
                          income: isAdmin ? _income : null,
                        ),
                  const SizedBox(height: 20),

                  // ── Alert Banner ───────────────────────────────────────
                  if (_notifCount > 0) ...[
                    _AlertBanner(
                      notifCount: _notifCount,
                      lowStockCount: _lowStock.length,
                      pendingCount: _pendingOrders.length,
                      onTap: _showNotifications,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Recent Orders ──────────────────────────────────────
                  if (_recentOrders.isNotEmpty) ...[
                    SectionTitle(
                      title: 'Order Terbaru',
                      action: TextButton(
                        onPressed: () =>
                            Navigator.pushNamed(context, '/orders'),
                        child: const Text('Lihat Semua',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.w700,
                                fontSize: 12)),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ..._recentOrders.map((o) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _RecentOrderCard(
                            order: o,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) => OrderDetailScreen(order: o)),
                            ).then((_) => _loadStats()),
                          ),
                        )),
                    const SizedBox(height: 20),
                  ],

                  // ── Menu Grid ──────────────────────────────────────────
                  const SectionTitle(title: 'Menu'),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 0.92,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                    ),
                    itemCount: menus.length,
                    itemBuilder: (_, i) {
                      final m = menus[i];
                      final color = m['color'] as Color;
                      return AppCard(
                        padding: EdgeInsets.zero,
                        borderRadius: 16,
                        onTap: () =>
                            Navigator.pushNamed(context, m['route'] as String),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: color.withAlpha(20),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(m['icon'] as IconData,
                                  color: color, size: 26),
                            ),
                            const SizedBox(height: 10),
                            Text(
                              m['label'] as String,
                              style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textPrimary),
                              textAlign: TextAlign.center,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Stat Cards Row ─────────────────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final int pending;
  final int process;
  final int completed;
  final double? income;

  const _StatsRow({
    required this.pending,
    required this.process,
    required this.completed,
    this.income,
  });

  @override
  Widget build(BuildContext context) {
    final cards = [
      _StatData('Pending', '$pending', AppColors.primary, Icons.hourglass_top_rounded),
      _StatData('Diproses', '$process', AppColors.orange, Icons.build_circle_rounded),
      _StatData('Selesai', '$completed', AppColors.green, Icons.check_circle_rounded),
      if (income != null)
        _StatData('Pendapatan', rupiah(income!), AppColors.primaryDark,
            Icons.payments_rounded, isSmallText: true),
    ];

    return SizedBox(
      height: 90,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: cards.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final d = cards[i];
          return Container(
            width: income != null ? 130 : 100,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: d.color.withAlpha(12),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: d.color.withAlpha(40)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(d.label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: d.color)),
                    Icon(d.icon, size: 16, color: d.color.withAlpha(160)),
                  ],
                ),
                Text(
                  d.value,
                  style: TextStyle(
                    fontSize: d.isSmallText ? 14 : 26,
                    fontWeight: FontWeight.w900,
                    color: d.color,
                    height: 1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatData {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool isSmallText;

  const _StatData(this.label, this.value, this.color, this.icon,
      {this.isSmallText = false});
}

// ── Alert Banner ───────────────────────────────────────────────────────────

class _AlertBanner extends StatelessWidget {
  final int notifCount;
  final int lowStockCount;
  final int pendingCount;
  final VoidCallback onTap;

  const _AlertBanner({
    required this.notifCount,
    required this.lowStockCount,
    required this.pendingCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.red.withAlpha(12),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.red.withAlpha(50)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.red.withAlpha(20),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.warning_amber_rounded,
                  color: AppColors.red, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$notifCount notifikasi memerlukan perhatian',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: AppColors.red),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (lowStockCount > 0) '$lowStockCount stok menipis',
                      if (pendingCount > 0) '$pendingCount order pending',
                    ].join(' • '),
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: AppColors.red, size: 20),
          ],
        ),
      ),
    );
  }
}

// ── Recent Order Card ──────────────────────────────────────────────────────

class _RecentOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _RecentOrderCard({required this.order, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.statusColor(order.orderStatus);
    return AppCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: statusColor.withAlpha(18),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.receipt_long_rounded, color: statusColor, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.orderCode,
                    style: const TextStyle(
                        fontWeight: FontWeight.w900,
                        fontSize: 14,
                        color: AppColors.textPrimary)),
                const SizedBox(height: 2),
                Text(
                  order.customer?.customerName ?? order.customerId ?? '-',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              StatusPill(status: order.orderStatus),
              const SizedBox(height: 4),
              Text(rupiah(order.totalAmount),
                  style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12,
                      color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ── Notification Bottom Sheet ──────────────────────────────────────────────

class _NotificationSheet extends StatelessWidget {
  final List<StockReport> lowStock;
  final List<OrderModel> pendingOrders;
  final List<OrderModel> processOrders;
  final void Function(String) onDismissStock;
  final void Function(String) onDismissOrder;
  final VoidCallback onDismissAll;

  const _NotificationSheet({
    required this.lowStock,
    required this.pendingOrders,
    required this.processOrders,
    required this.onDismissStock,
    required this.onDismissOrder,
    required this.onDismissAll,
  });

  @override
  Widget build(BuildContext context) {
    final stock = lowStock;
    final pending = pendingOrders;
    final process = processOrders;
    final total = stock.length + pending.length;
    final hasAny = stock.isNotEmpty || pending.isNotEmpty || process.isNotEmpty;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.80,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 8),
            child: Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2)),
              ),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: total > 0
                        ? AppColors.red.withAlpha(18)
                        : AppColors.green.withAlpha(18),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    total > 0
                        ? Icons.notifications_active_rounded
                        : Icons.notifications_none_rounded,
                    color: total > 0 ? AppColors.red : AppColors.green,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Notifikasi',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.w900)),
                      Text(
                        total > 0
                            ? '$total item memerlukan perhatian'
                            : 'Semua baik-baik saja',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                if (hasAny)
                  TextButton.icon(
                    onPressed: () {
                      onDismissAll();
                      _snack(context, 'Semua notifikasi dihapus');
                    },
                    icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                    label: const Text('Hapus Semua'),
                    style: TextButton.styleFrom(
                      foregroundColor: AppColors.textMuted,
                      textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.border),
          Flexible(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              shrinkWrap: true,
              children: [
                if (!hasAny)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 40),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.check_circle_outline_rounded,
                              size: 56, color: AppColors.green),
                          SizedBox(height: 12),
                          Text('Tidak ada notifikasi baru',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),

                // Stok Menipis
                if (stock.isNotEmpty) ...[
                  _NotifSection(
                    icon: Icons.inventory_2_rounded,
                    color: AppColors.red,
                    title: 'Stok Menipis',
                    subtitle: '${stock.length} item stok ≤ 5',
                  ),
                  const SizedBox(height: 8),
                  ...stock.map((s) => Dismissible(
                        key: ValueKey('stock-${s.itemId}'),
                        direction: DismissDirection.endToStart,
                        background: _dismissBg(),
                        onDismissed: (_) {
                          onDismissStock(s.itemId);
                          _snack(context, 'Notifikasi stok dihapus');
                        },
                        child: _StockNotifTile(
                          stock: s,
                          onDismiss: () {
                            onDismissStock(s.itemId);
                            _snack(context, 'Notifikasi stok dihapus');
                          },
                        ),
                      )),
                  const SizedBox(height: 16),
                ],

                // Order Pending
                if (pending.isNotEmpty) ...[
                  _NotifSection(
                    icon: Icons.hourglass_top_rounded,
                    color: AppColors.primary,
                    title: 'Order Menunggu',
                    subtitle: '${pending.length} order belum diproses',
                  ),
                  const SizedBox(height: 8),
                  ...pending.map((o) => Dismissible(
                        key: ValueKey('order-${o.orderId}'),
                        direction: DismissDirection.endToStart,
                        background: _dismissBg(),
                        onDismissed: (_) {
                          onDismissOrder(o.orderId);
                          _snack(context, 'Notifikasi order dihapus');
                        },
                        child: _OrderNotifTile(
                          order: o,
                          onDismiss: () {
                            onDismissOrder(o.orderId);
                            _snack(context, 'Notifikasi order dihapus');
                          },
                        ),
                      )),
                  const SizedBox(height: 16),
                ],

                // Order Diproses
                if (process.isNotEmpty) ...[
                  _NotifSection(
                    icon: Icons.build_circle_rounded,
                    color: AppColors.orange,
                    title: 'Sedang Diproses',
                    subtitle: '${process.length} order dalam pengerjaan',
                  ),
                  const SizedBox(height: 8),
                  ...process.map((o) => Dismissible(
                        key: ValueKey('process-${o.orderId}'),
                        direction: DismissDirection.endToStart,
                        background: _dismissBg(),
                        onDismissed: (_) {
                          onDismissOrder(o.orderId);
                          _snack(context, 'Notifikasi order dihapus');
                        },
                        child: _OrderNotifTile(
                          order: o,
                          onDismiss: () {
                            onDismissOrder(o.orderId);
                            _snack(context, 'Notifikasi order dihapus');
                          },
                        ),
                      )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  static void _snack(BuildContext context, String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        const Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 18),
        const SizedBox(width: 8),
        Text(msg),
      ]),
      backgroundColor: AppColors.green,
      behavior: SnackBarBehavior.floating,
      duration: const Duration(seconds: 2),
    ));
  }

  Widget _dismissBg() => Container(
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: AppColors.red.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline_rounded, color: AppColors.red, size: 22),
      );
}

class _NotifSection extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;

  const _NotifSection({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: 8),
        Text(title,
            style: TextStyle(
                fontWeight: FontWeight.w900, fontSize: 13, color: color)),
        const Spacer(),
        Text(subtitle,
            style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
      ],
    );
  }
}

class _StockNotifTile extends StatelessWidget {
  final StockReport stock;
  final VoidCallback? onDismiss;
  const _StockNotifTile({required this.stock, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final isCritical = stock.stock == 0;
    final color = isCritical ? AppColors.red : AppColors.orange;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: color.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: color.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.inventory_2_outlined, color: color, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(stock.itemName,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
                Text(stock.categoryName,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(99),
            ),
            child: Text(
              isCritical ? 'HABIS' : 'Sisa ${stock.stock}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w800),
            ),
          ),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(6, 0, 4, 0),
                child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

class _OrderNotifTile extends StatelessWidget {
  final OrderModel order;
  final VoidCallback? onDismiss;
  const _OrderNotifTile({required this.order, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final statusColor = AppColors.statusColor(order.orderStatus);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
      decoration: BoxDecoration(
        color: statusColor.withAlpha(10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: statusColor.withAlpha(40)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: statusColor.withAlpha(20),
              borderRadius: BorderRadius.circular(8),
            ),
            child:
                Icon(Icons.receipt_long_outlined, color: statusColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(order.orderCode,
                    style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: AppColors.textPrimary)),
                Text(
                  order.customer?.customerName ?? order.customerId ?? '-',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Text(rupiah(order.totalAmount),
              style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12,
                  color: AppColors.textPrimary)),
          if (onDismiss != null)
            GestureDetector(
              onTap: onDismiss,
              child: const Padding(
                padding: EdgeInsets.fromLTRB(6, 0, 4, 0),
                child: Icon(Icons.close_rounded, size: 16, color: AppColors.textMuted),
              ),
            ),
        ],
      ),
    );
  }
}

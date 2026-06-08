import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import '../widgets/common.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  UserModel? _user;

  @override
  void initState() {
    super.initState();
    _loadUser();
  }

  Future<void> _loadUser() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString('user_data');
    if (data != null && mounted) {
      setState(() => _user = UserModel.fromJson(jsonDecode(data)));
    }
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
            child: const Text('Batal'),
          ),
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
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, '/login');
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _user?.isAdmin ?? false;

    final menus = <Map<String, dynamic>>[
      {'icon': Icons.receipt_long_rounded, 'label': 'Open Bill', 'route': '/open-bill', 'color': AppColors.orange},
      {'icon': Icons.history_rounded, 'label': 'Riwayat Order', 'route': '/orders', 'color': AppColors.primaryDark},
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 180,
            pinned: true,
            automaticallyImplyLeading: false,
            backgroundColor: AppColors.primaryDark,
            elevation: 0,
            actions: [
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
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
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
                                isAdmin ? Icons.admin_panel_settings_rounded : Icons.point_of_sale_rounded,
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
                                      style: TextStyle(fontSize: 12, color: Colors.white70)),
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
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isAdmin
                                    ? AppColors.orange.withAlpha(200)
                                    : Colors.white.withAlpha(40),
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
                        const SizedBox(height: 12),
                        Text(
                          _user?.email ?? '',
                          style: const TextStyle(fontSize: 12, color: Colors.white54),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(18, 20, 18, 120),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SectionTitle(title: 'Menu Utama'),
                  const SizedBox(height: 14),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                        onTap: () => Navigator.pushNamed(context, m['route'] as String),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: color.withAlpha(22),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Icon(m['icon'] as IconData, color: color, size: 26),
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
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

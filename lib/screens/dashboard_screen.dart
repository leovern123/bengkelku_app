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
      {'icon': Icons.receipt_long, 'label': 'Open Bill', 'route': '/open-bill', 'color': AppColors.orange},
      {'icon': Icons.history, 'label': 'Riwayat Order', 'route': '/orders', 'color': AppColors.primaryDark},
      {'icon': Icons.people, 'label': 'Pelanggan', 'route': '/customers', 'color': AppColors.primary},
      {'icon': Icons.directions_car, 'label': 'Kendaraan', 'route': '/vehicles', 'color': AppColors.primaryDark},
      {'icon': Icons.inventory_2, 'label': 'Produk', 'route': '/items', 'color': AppColors.green},
      if (isAdmin) ...[
        {'icon': Icons.category, 'label': 'Kategori', 'route': '/categories', 'color': AppColors.primary},
        {'icon': Icons.business, 'label': 'Supplier', 'route': '/suppliers', 'color': AppColors.primaryDark},
        {'icon': Icons.engineering, 'label': 'Mekanik', 'route': '/mechanics', 'color': AppColors.green},
        {'icon': Icons.bar_chart, 'label': 'Laporan', 'route': '/reports', 'color': AppColors.orange},
      ],
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Dashboard ${isAdmin ? 'ADMIN' : 'KASIR'}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => showDialog(
              context: context,
              builder: (_) => AlertDialog(
                title: const Text('Keluar'),
                content: const Text('Yakin ingin keluar dari aplikasi?'),
                actions: [
                  TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Batal')),
                  TextButton(
                      onPressed: () { Navigator.pop(context); _logout(); },
                      child: const Text('Keluar', style: TextStyle(color: AppColors.red))),
                ],
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // User card
            AppCard(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: isAdmin ? AppColors.primaryDark : AppColors.orange,
                    child: Icon(
                      isAdmin ? Icons.admin_panel_settings : Icons.point_of_sale,
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
                            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        Text(_user?.name ?? '-',
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                        Text(_user?.email ?? '-',
                            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isAdmin ? AppColors.primaryDark : AppColors.orange,
                      borderRadius: BorderRadius.circular(99),
                    ),
                    child: Text(
                      isAdmin ? 'ADMIN' : 'KASIR',
                      style: const TextStyle(
                          color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Menu grid
            GridView.count(
              crossAxisCount: 2,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: 1.1,
              mainAxisSpacing: 14,
              crossAxisSpacing: 14,
              children: menus.map((m) {
                final color = m['color'] as Color;
                return AppCard(
                  padding: EdgeInsets.zero,
                  onTap: () => Navigator.pushNamed(context, m['route'] as String),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: color.withAlpha(30),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(m['icon'] as IconData, color: color, size: 28),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        m['label'] as String,
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import '../utils/app_colors.dart';
import 'dashboard_screen.dart';
import 'order/order_list_screen.dart';
import 'order/open_bill_screen.dart';
import 'customer/customer_list_screen.dart';
import 'item/item_list_screen.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _tab = 0; // 0=Dashboard, 1=Orders, 2=Customers, 3=Items

  void _onTap(int index) {
    setState(() => _tab = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _tab,
        children: const [
          DashboardScreen(),
          OrderListScreen(),
          CustomerListScreen(),
          ItemListScreen(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const OpenBillScreen()),
        ).then((_) {
          if (_tab == 1) setState(() {});
        }),
        backgroundColor: AppColors.orange,
        elevation: 4,
        shape: const CircleBorder(),
        child: const Icon(Icons.receipt_long, color: Colors.white, size: 26),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,
      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        notchMargin: 8,
        color: Colors.white,
        elevation: 12,
        child: SizedBox(
          height: 62,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavBtn(
                icon: Icons.home_rounded,
                label: 'Beranda',
                active: _tab == 0,
                onTap: () => _onTap(0),
              ),
              _NavBtn(
                icon: Icons.receipt_long_rounded,
                label: 'Riwayat',
                active: _tab == 1,
                onTap: () => _onTap(1),
              ),
              const SizedBox(width: 72), // space for FAB
              _NavBtn(
                icon: Icons.people_rounded,
                label: 'Pelanggan',
                active: _tab == 2,
                onTap: () => _onTap(2),
              ),
              _NavBtn(
                icon: Icons.inventory_2_rounded,
                label: 'Produk',
                active: _tab == 3,
                onTap: () => _onTap(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _NavBtn({
    required this.icon,
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              decoration: BoxDecoration(
                color: active ? AppColors.primary.withAlpha(20) : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 22,
                color: active ? AppColors.primary : AppColors.textMuted,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: active ? FontWeight.w800 : FontWeight.w500,
                color: active ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

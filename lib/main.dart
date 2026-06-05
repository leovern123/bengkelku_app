import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'utils/app_theme.dart';
import 'utils/app_colors.dart';
import 'screens/login_screen.dart';
import 'screens/dashboard_screen.dart';
import 'screens/customer/customer_list_screen.dart';
import 'screens/vehicle/vehicle_list_screen.dart';
import 'screens/category/category_list_screen.dart';
import 'screens/item/item_list_screen.dart';
import 'screens/order/open_bill_screen.dart';
import 'screens/order/order_list_screen.dart';
import 'screens/supplier/supplier_list_screen.dart';

void main() {
  runApp(const BengkelKuApp());
}

class BengkelKuApp extends StatelessWidget {
  const BengkelKuApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'BengkelKu',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const SplashScreen(),
      routes: {
        '/login': (_) => const LoginScreen(),
        '/dashboard': (_) => const DashboardScreen(),
        '/customers': (_) => const CustomerListScreen(),
        '/vehicles': (_) => const VehicleListScreen(),
        '/categories': (_) => const CategoryListScreen(),
        '/items': (_) => const ItemListScreen(),
        '/suppliers': (_) => const SupplierListScreen(),
        '/open-bill': (_) => const OpenBillScreen(),
        '/orders': (_) => const OrderListScreen(),
      },
    );
  }
}

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    await Future.delayed(const Duration(milliseconds: 600));
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('auth_token');
    if (!mounted) return;
    Navigator.pushReplacementNamed(context, token != null ? '/dashboard' : '/login');
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.car_repair, size: 80, color: Colors.white),
            SizedBox(height: 16),
            Text('BENGKELKU',
                style: TextStyle(
                    fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 2)),
            Text('Solusi Manajemen Bengkel',
                style: TextStyle(color: Colors.white70, fontSize: 13)),
            SizedBox(height: 32),
            CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
          ],
        ),
      ),
    );
  }
}

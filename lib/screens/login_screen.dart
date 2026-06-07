import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../services/auth_service.dart';
import '../services/api_service.dart';
import '../utils/app_colors.dart';
import '../widgets/common.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscure = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  void _quickFill(String email, String pass) {
    _emailCtrl.text = email;
    _passCtrl.text = pass;
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);

    try {
      final res = await AuthService.login(_emailCtrl.text.trim(), _passCtrl.text);

      if (res['success'] == true) {
        await ApiService.saveToken(res['data']['token']);
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('user_data', jsonEncode(res['data']['user']));

        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/dashboard');
      } else {
        _showError(res['message'] ?? 'Email atau password salah');
      }
    } catch (_) {
      _showError('Tidak dapat terhubung ke server');
    }

    if (mounted) setState(() => _loading = false);
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
            child: Column(
              children: [
                // Icon & Title
                const Icon(Icons.two_wheeler, size: 86, color: AppColors.primaryDark),
                const SizedBox(height: 12),
                const Text('BENGKELKU',
                    style: TextStyle(
                        fontSize: 30, fontWeight: FontWeight.w900, color: AppColors.primaryDark)),
                const SizedBox(height: 4),
                const Text('Solusi Manajemen Bengkel Motor',
                    style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                const SizedBox(height: 32),

                // Quick login buttons
                AppCard(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text('Login Cepat',
                          style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.textMuted)),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.admin_panel_settings, size: 18),
                              label: const Text('Admin'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.primaryDark,
                                side: const BorderSide(color: AppColors.primaryDark),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _quickFill('admin@bengkelku.com', 'admin123'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              icon: const Icon(Icons.point_of_sale, size: 18),
                              label: const Text('Kasir'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.orange,
                                side: const BorderSide(color: AppColors.orange),
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                              ),
                              onPressed: () => _quickFill('kasir@bengkelku.com', 'kasir123'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Form
                AppCard(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('Masuk ke Akun',
                            style: TextStyle(
                                fontSize: 18, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined, color: AppColors.textMuted),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Email wajib diisi' : null,
                        ),
                        const SizedBox(height: 14),
                        TextFormField(
                          controller: _passCtrl,
                          obscureText: _obscure,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.textMuted),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscure ? Icons.visibility_off : Icons.visibility,
                                color: AppColors.textMuted,
                              ),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                          validator: (v) =>
                              v == null || v.isEmpty ? 'Password wajib diisi' : null,
                        ),
                        const SizedBox(height: 20),
                        PrimaryButton(
                          label: 'Masuk',
                          icon: Icons.login,
                          isLoading: _loading,
                          onPressed: _login,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

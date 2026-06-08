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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primaryDark,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Gradient background
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppColors.primaryDark, AppColors.primary],
                stops: [0.0, 0.6],
              ),
            ),
          ),
          // Decorative circles
          Positioned(
            top: -60,
            right: -60,
            child: Container(
              width: 220,
              height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(12),
              ),
            ),
          ),
          Positioned(
            top: 80,
            left: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withAlpha(8),
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              children: [
                const Expanded(
                  flex: 5,
                  child: _HeroSection(),
                ),
                Expanded(
                  flex: 8,
                  child: _FormCard(
                    formKey: _formKey,
                    emailCtrl: _emailCtrl,
                    passCtrl: _passCtrl,
                    obscure: _obscure,
                    loading: _loading,
                    onToggleObscure: () => setState(() => _obscure = !_obscure),
                    onQuickFill: _quickFill,
                    onLogin: _login,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroSection extends StatelessWidget {
  const _HeroSection();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.only(top: 24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.two_wheeler, size: 72, color: Colors.white),
          SizedBox(height: 12),
          Text(
            'BENGKELKU',
            style: TextStyle(
              fontSize: 34,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: 3,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Solusi Manajemen Bengkel Motor',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white70,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController emailCtrl;
  final TextEditingController passCtrl;
  final bool obscure;
  final bool loading;
  final VoidCallback onToggleObscure;
  final void Function(String, String) onQuickFill;
  final VoidCallback onLogin;

  const _FormCard({
    required this.formKey,
    required this.emailCtrl,
    required this.passCtrl,
    required this.obscure,
    required this.loading,
    required this.onToggleObscure,
    required this.onQuickFill,
    required this.onLogin,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          24,
          28,
          24,
          MediaQuery.of(context).viewInsets.bottom + 24,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle indicator
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Masuk ke Akun',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Gunakan email dan password yang terdaftar',
              style: TextStyle(fontSize: 13, color: AppColors.textMuted),
            ),
            const SizedBox(height: 20),
            Form(
              key: formKey,
              child: Column(
                children: [
                  TextFormField(
                    controller: emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      prefixIcon: const Icon(Icons.email_outlined, color: AppColors.textMuted, size: 20),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Email wajib diisi' : null,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: passCtrl,
                    obscureText: obscure,
                    decoration: InputDecoration(
                      labelText: 'Password',
                      prefixIcon: const Icon(Icons.lock_outlined, color: AppColors.textMuted, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: AppColors.textMuted,
                          size: 20,
                        ),
                        onPressed: onToggleObscure,
                      ),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: AppColors.border),
                      ),
                    ),
                    validator: (v) => v == null || v.isEmpty ? 'Password wajib diisi' : null,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            PrimaryButton(
              label: 'Masuk',
              icon: Icons.login_rounded,
              isLoading: loading,
              onPressed: onLogin,
            ),
            const SizedBox(height: 20),
            const Row(
              children: [
                Expanded(child: Divider(color: AppColors.border)),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text('Login Cepat', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ),
                Expanded(child: Divider(color: AppColors.border)),
              ],
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _QuickBtn(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin',
                    color: AppColors.primaryDark,
                    onTap: () => onQuickFill('admin@bengkelku.com', 'admin123'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _QuickBtn(
                    icon: Icons.point_of_sale_rounded,
                    label: 'Kasir',
                    color: AppColors.orange,
                    onTap: () => onQuickFill('kasir@bengkelku.com', 'kasir123'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _QuickBtn extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _QuickBtn({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: color.withAlpha(15),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withAlpha(60)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label,
                  style: TextStyle(
                      color: color, fontWeight: FontWeight.w700, fontSize: 13)),
            ],
          ),
        ),
      ),
    );
  }
}

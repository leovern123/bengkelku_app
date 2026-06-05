import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

// Format angka ke Rupiah
String rupiah(num value) {
  final str = value.toStringAsFixed(0);
  final result = str.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return 'Rp$result';
}

// Card dengan shadow dan border kustom
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onTap;
  final Color? color;
  final double borderRadius;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.onTap,
    this.color,
    this.borderRadius = 18,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// Tombol utama
class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final double height;

  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: FilledButton.icon(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          disabledBackgroundColor: AppColors.border,
        ),
        icon: isLoading
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : (icon != null ? Icon(icon, size: 18) : const SizedBox.shrink()),
        label: Text(
          isLoading ? 'Memproses...' : label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

// Badge status order
class StatusPill extends StatelessWidget {
  final String status;
  final String? label;

  const StatusPill({super.key, required this.status, this.label});

  @override
  Widget build(BuildContext context) {
    final color = AppColors.statusColor(status);
    final text = label ?? AppColors.statusLabel(status);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withAlpha(128)),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// Section title
class SectionTitle extends StatelessWidget {
  final String title;
  final Widget? action;
  const SectionTitle({super.key, required this.title, this.action});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title,
            style: const TextStyle(
                fontSize: 14, fontWeight: FontWeight.w900, color: AppColors.textPrimary)),
        if (action != null) action!,
      ],
    );
  }
}

// Empty state
class EmptyState extends StatelessWidget {
  final String message;
  final IconData icon;
  final String? buttonLabel;
  final VoidCallback? onButton;

  const EmptyState({
    super.key,
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.buttonLabel,
    this.onButton,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: AppColors.border),
            const SizedBox(height: 12),
            Text(message,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 14),
                textAlign: TextAlign.center),
            if (buttonLabel != null && onButton != null) ...[
              const SizedBox(height: 16),
              TextButton(onPressed: onButton, child: Text(buttonLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

// Search bar
class AppSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const AppSearchBar({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
        contentPadding: const EdgeInsets.symmetric(vertical: 10),
      ),
    );
  }
}

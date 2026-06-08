import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

// ── Formatters ─────────────────────────────────────────────────────────────

String rupiah(num value) {
  final str = value.toStringAsFixed(0);
  final result = str.replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
  return 'Rp$result';
}

// ── AppCard ────────────────────────────────────────────────────────────────

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
    this.borderRadius = 16,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? AppColors.card,
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: AppColors.primary.withAlpha(15),
          child: Padding(
            padding: padding ?? const EdgeInsets.all(16),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ── PrimaryButton ──────────────────────────────────────────────────────────

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
      child: FilledButton(
        onPressed: isLoading ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: color ?? AppColors.primary,
          disabledBackgroundColor: AppColors.border,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 18, color: Colors.white),
                    const SizedBox(width: 8),
                  ],
                  Text(
                    label,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white),
                  ),
                ],
              ),
      ),
    );
  }
}

// ── SecondaryButton ────────────────────────────────────────────────────────

class SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final double height;

  const SecondaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: c,
          side: BorderSide(color: c, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 18),
              const SizedBox(width: 8),
            ],
            Text(label,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          ],
        ),
      ),
    );
  }
}

// ── StatusPill ─────────────────────────────────────────────────────────────

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
        color: color.withAlpha(22),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

// ── SectionTitle ───────────────────────────────────────────────────────────

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

// ── EmptyState ─────────────────────────────────────────────────────────────

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
        padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.border.withAlpha(60),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 44, color: AppColors.textMuted.withAlpha(120)),
            ),
            const SizedBox(height: 16),
            Text(message,
                style: const TextStyle(
                    color: AppColors.textMuted, fontSize: 14, height: 1.5),
                textAlign: TextAlign.center),
            if (buttonLabel != null && onButton != null) ...[
              const SizedBox(height: 20),
              FilledButton(
                onPressed: onButton,
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text(buttonLabel!,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ── AppSearchBar ───────────────────────────────────────────────────────────

class AppSearchBar extends StatelessWidget {
  final String hint;
  final ValueChanged<String> onChanged;

  const AppSearchBar({super.key, required this.hint, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        onChanged: onChanged,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textMuted, fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textMuted, size: 20),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14),
            borderSide: BorderSide.none,
          ),
          filled: true,
          fillColor: Colors.white,
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}

// ── InitialsAvatar ─────────────────────────────────────────────────────────

class InitialsAvatar extends StatelessWidget {
  final String name;
  final double radius;
  final Color? bgColor;

  const InitialsAvatar({
    super.key,
    required this.name,
    this.radius = 24,
    this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
    final bg = bgColor ?? AppColors.primary;
    return CircleAvatar(
      radius: radius,
      backgroundColor: bg.withAlpha(22),
      child: Text(
        initial,
        style: TextStyle(
          color: bg,
          fontWeight: FontWeight.w900,
          fontSize: radius * 0.76,
        ),
      ),
    );
  }
}

// ── InfoRow ────────────────────────────────────────────────────────────────

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;
  final bool bold;
  final double labelWidth;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.valueColor,
    this.bold = false,
    this.labelWidth = 100,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: labelWidth,
            child: Text(label,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          ),
          const Text(': ',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: bold ? FontWeight.w900 : FontWeight.w600,
                fontSize: bold ? 15 : 13,
                color: valueColor ?? AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── AppLabel ───────────────────────────────────────────────────────────────

class AppLabel extends StatelessWidget {
  final String text;
  final Color? color;

  const AppLabel({super.key, required this.text, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withAlpha(18),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        text,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: c),
      ),
    );
  }
}

// ── IconBox ────────────────────────────────────────────────────────────────
// Reusable colored icon background container

class IconBox extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;

  const IconBox({
    super.key,
    required this.icon,
    required this.color,
    this.size = 44,
    this.iconSize = 22,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(size * 0.28),
      ),
      child: Icon(icon, color: color, size: iconSize),
    );
  }
}

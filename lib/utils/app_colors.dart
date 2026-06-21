import 'package:flutter/material.dart';

class AppColors {
  static const Color primary     = Color(0xFF334155); // Slate 700
  static const Color primaryDark = Color(0xFF1E293B); // Slate 800
  static const Color accent      = Color(0xFF0891B2); // Cyan 600
  static const Color orange      = Color(0xFFF59E0B); // Amber 500
  static const Color green       = Color(0xFF10B981); // Emerald 500
  static const Color red         = Color(0xFFF43F5E); // Rose 500

  static const Color background  = Color(0xFFF1F5F9); // Slate 100
  static const Color card        = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF0F172A); // Slate 900
  static const Color textMuted   = Color(0xFF64748B); // Slate 500
  static const Color border      = Color(0xFFE2E8F0); // Slate 200

  static Color statusPending   = accent;
  static Color statusProcess   = orange;
  static Color statusCompleted = green;
  static Color statusCancelled = red;

  static Color statusColor(String status) {
    switch (status) {
      case 'pending':   return statusPending;
      case 'process':   return statusProcess;
      case 'completed': return statusCompleted;
      case 'cancelled': return statusCancelled;
      default:          return textMuted;
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'pending':   return 'Pending';
      case 'process':   return 'Diproses';
      case 'completed': return 'Selesai';
      case 'cancelled': return 'Dibatalkan';
      default:          return status;
    }
  }
}

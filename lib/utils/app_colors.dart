import 'package:flutter/material.dart';

class AppColors {
  static const Color primary = Color(0xFF075FD8);
  static const Color primaryDark = Color(0xFF06469D);
  static const Color orange = Color(0xFFFF8A00);
  static const Color green = Color(0xFF16A34A);
  static const Color red = Color(0xFFDC2626);

  static const Color background = Color(0xFFF5F8FC);
  static const Color card = Color(0xFFFFFFFF);
  static const Color textPrimary = Color(0xFF102033);
  static const Color textMuted = Color(0xFF6B7280);
  static const Color border = Color(0xFFE5EAF2);

  // Status
  static Color statusPending = primary;
  static Color statusProcess = orange;
  static Color statusCompleted = green;
  static Color statusCancelled = red;

  static Color statusColor(String status) {
    switch (status) {
      case 'pending': return statusPending;
      case 'process': return statusProcess;
      case 'completed': return statusCompleted;
      case 'cancelled': return statusCancelled;
      default: return textMuted;
    }
  }

  static String statusLabel(String status) {
    switch (status) {
      case 'pending': return 'Pending';
      case 'process': return 'Diproses';
      case 'completed': return 'Selesai';
      case 'cancelled': return 'Dibatalkan';
      default: return status;
    }
  }
}

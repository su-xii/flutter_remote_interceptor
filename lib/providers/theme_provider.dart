import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppColors {
  final Color primary;
  final Color success;
  final Color warning;
  final Color error;
  final Color textPrimary;
  final Color textSecondary;
  final Color bgCard;
  final Color bgPage;

  AppColors({
    required this.primary,
    required this.success,
    required this.warning,
    required this.error,
    required this.textPrimary,
    required this.textSecondary,
    required this.bgCard,
    required this.bgPage,
  });

  static AppColors get defaultColors {
    return AppColors(
      primary: const Color(0xFF165DFF),
      success: const Color(0xFF00B42A),
      warning: const Color(0xFFFF7D00),
      error: const Color(0xFFF53F3F),
      textPrimary: const Color(0xFF1D2129),
      textSecondary: const Color(0xFF86909C),
      bgCard: const Color(0xFFFFFFFF),
      bgPage: const Color(0xFFF2F3F5),
    );
  }
}

final themeProvider = Provider<AppColors>((ref) {
  return AppColors.defaultColors;
});

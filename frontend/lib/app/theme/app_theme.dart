import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:togli_app/app/theme/app_colors.dart';

abstract final class AppTheme {
  static const Color scaffoldBackground = Color(0xFFF5F2EB);
  static const Color cardBackground = Color(0xFFFFFFFF);
  static const Color surfaceOverlay06 = Color(0x0F2D3047);
  static const Color surfaceOverlay08 = Color(0x142D3047);
  static const Color surfaceOverlay12 = Color(0x1F2D3047);
  static const Color borderDefault = Color(0xFFDDD8CC);
  static const Color borderSubtle = Color(0x14DDD8CC);

  static const Color textPrimary = Color(0xFF2D3047);
  static const Color textSecondary = Color(0xFF4A4E6A);
  static const Color textTertiary = Color(0x802D3047);

  static ThemeData light() {
    return ThemeData(
      colorScheme: ColorScheme.light(
        primary: AppColors.coral,
        secondary: AppColors.teal,
        surface: AppColors.cream,
        onSurface: AppColors.navy,
      ),
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: GoogleFonts.interTextTheme(ThemeData.light().textTheme),
      useMaterial3: true,
    );
  }
}

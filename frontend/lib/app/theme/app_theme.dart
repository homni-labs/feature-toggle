import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:feature_toggle_app/app/theme/app_colors.dart';

abstract final class AppTheme {
  static const Color scaffoldBackground = Color(0xFF151530);
  static const Color cardBackground = Color(0xFF1E2040);
  static const Color surfaceOverlay06 = Color(0x0FFFFFFF);
  static const Color surfaceOverlay08 = Color(0x14FFFFFF);
  static const Color surfaceOverlay12 = Color(0x1FFFFFFF);
  static const Color borderDefault = Color(0x1FFFFFFF);
  static const Color borderSubtle = Color(0x14FFFFFF);

  static ThemeData dark() {
    return ThemeData(
      colorScheme: ColorScheme.dark(
        primary: AppColors.coral,
        secondary: AppColors.teal,
        surface: AppColors.navy,
      ),
      scaffoldBackgroundColor: scaffoldBackground,
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme),
      useMaterial3: true,
    );
  }
}

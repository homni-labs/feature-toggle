import 'package:flutter/material.dart';

class AppColors {
  // Colors extracted from the logo
  static const Color coral = Color(0xFFEF7B6C);
  static const Color coralLight = Color(0xFFF4A393);
  static const Color teal = Color(0xFF4ABFBF);
  static const Color tealDark = Color(0xFF3A9E9E);
  static const Color yellow = Color(0xFFF5C842);
  static const Color yellowLight = Color(0xFFF8D76B);
  static const Color purple = Color(0xFFBBA8D9);
  static const Color purpleLight = Color(0xFFD4C7EB);
  static const Color navy = Color(0xFF2D3047);
  static const Color navyLight = Color(0xFF3D4065);
  static const Color green = Color(0xFF7BC67E);
  static const Color greenLight = Color(0xFF9FD8A1);
  static const Color cream = Color(0xFFEAE7DC);
  static const Color white = Color(0xFFFFFFFF);
  static const Color offWhite = Color(0xFFF8F7F4);

  static const LinearGradient backgroundGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFFF5F2EB),
      Color(0xFFEDE9E0),
      Color(0xFFF5F2EB),
      Color(0xFFEDE9E0),
    ],
    stops: [0.0, 0.3, 0.7, 1.0],
  );

  static const LinearGradient buttonGradient = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [coral, Color(0xFFE8585A)],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [teal, purple],
  );
}

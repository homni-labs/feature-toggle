import 'package:flutter/material.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';
import 'package:feature_toggle_app/core/domain/failure.dart';

void showAppSnackBar(
  BuildContext context,
  Failure failure, {
  bool isWarning = false,
}) {
  ScaffoldMessenger.of(context).clearSnackBars();

  final Color color = isWarning ? AppColors.yellow : AppColors.coral;
  final IconData icon = isWarning
      ? Icons.warning_amber_rounded
      : Icons.error_outline_rounded;

  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isWarning ? 'Warning' : 'Error',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  failure.message,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.white.withOpacity(0.85),
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () =>
                ScaffoldMessenger.of(context).hideCurrentSnackBar(),
            child: Icon(
              Icons.close_rounded,
              color: Colors.white.withOpacity(0.5),
              size: 18,
            ),
          ),
        ],
      ),
      backgroundColor: color.withOpacity(0.95),
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.only(bottom: 24, left: 24, right: 24),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      elevation: 8,
      duration: const Duration(seconds: 5),
    ),
  );
}

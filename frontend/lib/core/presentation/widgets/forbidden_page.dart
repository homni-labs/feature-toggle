import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:feature_toggle_app/app/theme/app_colors.dart';

/// Full-page "Access Denied" widget shown when the backend returns 403.
class ForbiddenPage extends StatelessWidget {
  final String message;
  final VoidCallback? onBack;

  const ForbiddenPage({
    super.key,
    this.message = 'You do not have permission to view this page.\nContact your project admin to request access.',
    this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: 400,
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: Colors.white,
          border: Border.all(color: AppColors.navy, width: 3),
          boxShadow: const [
            BoxShadow(color: AppColors.navy, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppColors.coral.withOpacity(0.1),
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                size: 32,
                color: AppColors.coral,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Access Denied',
              style: GoogleFonts.fredoka(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.navy,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.navy.withOpacity(0.6),
                height: 1.5,
              ),
            ),
            if (onBack != null) ...[
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: onBack,
                  icon: const Icon(Icons.arrow_back_rounded, size: 18),
                  label: const Text('Go Back'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

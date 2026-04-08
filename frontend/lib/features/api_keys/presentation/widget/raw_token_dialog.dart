import 'package:flutter/material.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';

class RawTokenDialog extends StatelessWidget {
  final String rawToken;

  const RawTokenDialog({
    super.key,
    required this.rawToken,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF1E2040),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.key_rounded,
              size: 40,
              color: AppColors.teal,
            ),
            const SizedBox(height: 16),
            const Text(
              'API Key Created',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Copy this token now. It will not be shown again.',
              style: TextStyle(
                fontSize: 13,
                color: Colors.white.withOpacity(0.5),
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 20),

            // Token display
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withOpacity(0.06),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: SelectableText(
                rawToken,
                style: const TextStyle(
                  fontSize: 13,
                  fontFamily: 'monospace',
                  color: AppColors.teal,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Done button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).pop(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text('Done'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

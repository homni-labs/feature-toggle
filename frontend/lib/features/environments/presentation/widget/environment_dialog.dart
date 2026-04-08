import 'package:flutter/material.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';

class EnvironmentDialogResult {
  final String name;
  EnvironmentDialogResult({required this.name});
}

class EnvironmentDialog extends StatefulWidget {
  const EnvironmentDialog({super.key});

  @override
  State<EnvironmentDialog> createState() => _EnvironmentDialogState();
}

class _EnvironmentDialogState extends State<EnvironmentDialog> {
  late TextEditingController _nameController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim().toUpperCase();
    if (name.isEmpty) return;
    Navigator.of(context).pop(EnvironmentDialogResult(name: name));
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 420,
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          color: const Color(0xFF1E2040),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create Environment',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),

            // Name field
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: Colors.white.withOpacity(0.07),
                border: Border.all(color: Colors.white.withOpacity(0.12)),
              ),
              child: TextField(
                controller: _nameController,
                autofocus: true,
                textCapitalization: TextCapitalization.characters,
                style: const TextStyle(color: Colors.white, fontSize: 14),
                cursorColor: AppColors.coral,
                decoration: InputDecoration(
                  hintText: 'Environment name (e.g. STAGING)',
                  hintStyle:
                      TextStyle(color: Colors.white.withOpacity(0.3)),
                  prefixIcon: Icon(Icons.cloud_outlined,
                      size: 20, color: Colors.white.withOpacity(0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
                onSubmitted: (_) => _submit(),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Name will be converted to uppercase',
              style: TextStyle(
                fontSize: 11,
                color: Colors.white.withOpacity(0.3),
              ),
            ),

            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: Colors.white.withOpacity(0.12),
                          ),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text('Create'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

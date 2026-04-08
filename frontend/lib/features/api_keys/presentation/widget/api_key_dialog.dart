import 'package:flutter/material.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';

class ApiKeyDialogResult {
  final String name;
  final String? expiresAt; // ISO 8601 or null = never expires

  ApiKeyDialogResult({
    required this.name,
    this.expiresAt,
  });
}

class ApiKeyDialog extends StatefulWidget {
  const ApiKeyDialog({super.key});

  @override
  State<ApiKeyDialog> createState() => _ApiKeyDialogState();
}

class _ApiKeyDialogState extends State<ApiKeyDialog> {
  late TextEditingController _nameController;
  DateTime? _expiresAt;

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

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
    final String name = _nameController.text.trim();
    if (name.isEmpty) return;

    Navigator.of(context).pop(ApiKeyDialogResult(
      name: name,
      expiresAt: _expiresAt?.toUtc().toIso8601String(),
    ));
  }

  Future<void> _pickDate() async {
    final DateTime now = DateTime.now();
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _expiresAt ?? now.add(const Duration(days: 90)),
      firstDate: now.add(const Duration(days: 1)),
      lastDate: now.add(const Duration(days: 365 * 5)),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.coral,
              surface: Color(0xFF1E2040),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _expiresAt = picked);
    }
  }

  String _formatDate(DateTime dt) {
    return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
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
              'Create API Key',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'API keys are read-only and can only be used to fetch toggle states.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.35),
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
                style: const TextStyle(color: Colors.white, fontSize: 14),
                cursorColor: AppColors.coral,
                onSubmitted: (_) => _submit(),
                decoration: InputDecoration(
                  hintText: 'API key name',
                  hintStyle:
                      TextStyle(color: Colors.white.withOpacity(0.3)),
                  prefixIcon: Icon(Icons.key_outlined,
                      size: 20, color: Colors.white.withOpacity(0.4)),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16, vertical: 14),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // Expiration
            Text(
              'Expiration',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: Colors.white.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: _expiresAt != null
                          ? AppColors.teal.withOpacity(0.15)
                          : Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: _expiresAt != null
                            ? AppColors.teal.withOpacity(0.4)
                            : Colors.white.withOpacity(0.12),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.calendar_today_rounded,
                          size: 14,
                          color: _expiresAt != null
                              ? AppColors.teal
                              : Colors.white.withOpacity(0.4),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _expiresAt != null
                              ? _formatDate(_expiresAt!)
                              : 'Set expiry date',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: _expiresAt != null
                                ? FontWeight.w600
                                : FontWeight.w400,
                            color: _expiresAt != null
                                ? AppColors.teal
                                : Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if (_expiresAt != null) ...[
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () => setState(() => _expiresAt = null),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        color: Colors.white.withOpacity(0.06),
                      ),
                      child: Icon(Icons.close_rounded,
                          size: 16,
                          color: Colors.white.withOpacity(0.4)),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 6),
            Text(
              _expiresAt == null
                  ? 'No expiry — this key will be valid forever'
                  : 'Key will expire on ${_formatDate(_expiresAt!)}',
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
                        foregroundColor:
                            Colors.white.withOpacity(0.6),
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

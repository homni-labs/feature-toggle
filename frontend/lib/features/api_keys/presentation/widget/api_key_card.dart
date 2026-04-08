import 'package:flutter/material.dart';
import 'package:feature_toggle_app/features/api_keys/domain/model/api_key.dart';
import 'package:feature_toggle_app/core/domain/value_objects/project_role.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';

class ApiKeyCard extends StatelessWidget {
  final ApiKey apiKey;
  final VoidCallback? onRevoke;

  const ApiKeyCard({
    super.key,
    required this.apiKey,
    this.onRevoke,
  });

  static Color _roleColor(ProjectRole role) {
    switch (role) {
      case ProjectRole.admin:
        return AppColors.coral;
      case ProjectRole.editor:
        return AppColors.teal;
      case ProjectRole.reader:
        return AppColors.purple;
    }
  }

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDate(DateTime dt) {
    return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final Color roleColor = _roleColor(apiKey.role);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1E2040),
        border: Border.all(
          color: apiKey.active
              ? roleColor.withOpacity(0.2)
              : AppColors.coral.withOpacity(0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Name + masked token + role badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    apiKey.name,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: apiKey.active
                          ? Colors.white
                          : Colors.white.withOpacity(0.5),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        apiKey.maskedToken,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: Colors.white.withOpacity(0.3),
                          fontFamily: 'monospace',
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: roleColor.withOpacity(0.15),
                        ),
                        child: Text(
                          apiKey.roleLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: roleColor,
                          ),
                        ),
                      ),
                      if (!apiKey.active) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: AppColors.coral.withOpacity(0.15),
                          ),
                          child: const Text(
                            'Revoked',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: AppColors.coral,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Dates column
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Created ${_formatDate(apiKey.createdAt)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  apiKey.expiresAt != null
                      ? 'Expires ${_formatDate(apiKey.expiresAt!)}'
                      : 'No expiry',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ),
              ],
            ),

            // Revoke button
            if (apiKey.active && onRevoke != null) ...[
              const SizedBox(width: 8),
              _ActionButton(
                icon: Icons.block_rounded,
                onTap: onRevoke!,
                hoverColor: AppColors.coral,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ActionButton extends StatefulWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color? hoverColor;

  const _ActionButton({
    required this.icon,
    required this.onTap,
    this.hoverColor,
  });

  @override
  State<_ActionButton> createState() => _ActionButtonState();
}

class _ActionButtonState extends State<_ActionButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _hovering
                ? Colors.white.withOpacity(0.10)
                : Colors.transparent,
          ),
          child: Icon(
            widget.icon,
            size: 18,
            color: _hovering
                ? (widget.hoverColor ?? Colors.white.withOpacity(0.8))
                : Colors.white.withOpacity(0.3),
          ),
        ),
      ),
    );
  }
}

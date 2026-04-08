import 'package:flutter/material.dart';
import 'package:feature_toggle_app/features/environments/domain/model/environment.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';

class EnvironmentCard extends StatelessWidget {
  final Environment environment;
  final VoidCallback? onDelete;

  const EnvironmentCard({
    super.key,
    required this.environment,
    this.onDelete,
  });

  static Color _envColor(String env) {
    switch (env) {
      case 'DEV':
        return AppColors.teal;
      case 'TEST':
        return AppColors.yellow;
      case 'PROD':
        return AppColors.coral;
      default:
        return AppColors.purple;
    }
  }

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDate(DateTime dt) {
    return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final Color color = _envColor(environment.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1E2040),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Color accent bar
            Container(
              width: 4,
              height: 40,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(2),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [color, color.withOpacity(0.3)],
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name + created date
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    environment.name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(
                        Icons.calendar_today_rounded,
                        size: 12,
                        color: Colors.white.withOpacity(0.3),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Created ${_formatDate(environment.createdAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withOpacity(0.35),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Delete button
            if (onDelete != null)
              _ActionButton(
                icon: Icons.delete_outline_rounded,
                onTap: onDelete!,
                hoverColor: AppColors.coral,
              ),
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

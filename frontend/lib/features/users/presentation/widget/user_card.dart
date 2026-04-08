import 'package:flutter/material.dart';
import 'package:feature_toggle_app/features/auth/domain/model/user.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';

class UserCard extends StatelessWidget {
  final User user;
  final VoidCallback? onToggleRole;
  final VoidCallback? onToggleActive;

  const UserCard({
    super.key,
    required this.user,
    this.onToggleRole,
    this.onToggleActive,
  });

  @override
  Widget build(BuildContext context) {
    final Color roleColor =
        user.isPlatformAdmin ? AppColors.coral : AppColors.teal;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: const Color(0xFF1E2040),
        border: Border.all(color: roleColor.withOpacity(0.2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Avatar
            CircleAvatar(
              radius: 18,
              backgroundColor: roleColor.withOpacity(0.2),
              child: Text(
                user.displayName.isNotEmpty
                    ? user.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: roleColor,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Email + name + badges
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.email.value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                  if (user.name != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      user.name!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.35),
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      // Platform role badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: roleColor.withOpacity(0.15),
                        ),
                        child: Text(
                          user.roleLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: roleColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      // Active badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: user.active
                              ? AppColors.green.withOpacity(0.15)
                              : AppColors.coral.withOpacity(0.15),
                        ),
                        child: Text(
                          user.active ? 'Active' : 'Inactive',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: user.active
                                ? AppColors.green
                                : AppColors.coral,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Toggle role button
            if (onToggleRole != null) ...[
              _ActionButton(
                icon: user.isPlatformAdmin
                    ? Icons.arrow_downward
                    : Icons.arrow_upward,
                onTap: onToggleRole!,
                hoverColor: user.isPlatformAdmin
                    ? AppColors.yellow
                    : AppColors.coral,
              ),
              const SizedBox(width: 4),
            ],

            // Toggle active button
            if (onToggleActive != null)
              _ActionButton(
                icon: user.active
                    ? Icons.block
                    : Icons.check_circle_outline,
                onTap: onToggleActive!,
                hoverColor: user.active
                    ? AppColors.coral
                    : AppColors.green,
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

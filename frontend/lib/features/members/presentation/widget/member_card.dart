import 'package:flutter/material.dart';
import 'package:feature_toggle_app/features/members/domain/model/project_membership.dart';
import 'package:feature_toggle_app/core/domain/value_objects/project_role.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';

class MemberCard extends StatelessWidget {
  final ProjectMembership membership;
  final ValueChanged<ProjectRole>? onRoleChange;
  final VoidCallback? onDelete;

  const MemberCard({
    super.key,
    required this.membership,
    this.onRoleChange,
    this.onDelete,
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

  @override
  Widget build(BuildContext context) {
    final Color roleColor = _roleColor(membership.role);

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
                membership.displayName.isNotEmpty
                    ? membership.displayName[0].toUpperCase()
                    : '?',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: roleColor,
                ),
              ),
            ),
            const SizedBox(width: 14),

            // Name + email + role badge
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    membership.displayName,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (membership.email != null &&
                      membership.email != membership.name) ...[
                    const SizedBox(height: 2),
                    Text(
                      membership.email!,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.white.withOpacity(0.35),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(8),
                          color: roleColor.withOpacity(0.15),
                        ),
                        child: Text(
                          membership.roleLabel,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: roleColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Role change popup
            if (onRoleChange != null)
              PopupMenuButton<ProjectRole>(
                onSelected: onRoleChange,
                icon: Icon(
                  Icons.swap_horiz_rounded,
                  size: 18,
                  color: Colors.white.withOpacity(0.3),
                ),
                color: const Color(0xFF1E2040),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: Colors.white.withOpacity(0.12)),
                ),
                itemBuilder: (BuildContext context) => ProjectRole.values
                    .map(
                      (ProjectRole role) => PopupMenuItem<ProjectRole>(
                        value: role,
                        child: Text(
                          role.label,
                          style: TextStyle(
                            fontSize: 13,
                            color: membership.role == role
                                ? _roleColor(role)
                                : Colors.white.withOpacity(0.7),
                            fontWeight: membership.role == role
                                ? FontWeight.w600
                                : FontWeight.w400,
                          ),
                        ),
                      ),
                    )
                    .toList(),
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

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:feature_toggle_app/app/theme/app_colors.dart';
import 'package:feature_toggle_app/core/domain/value_objects/project_role.dart';
import 'package:feature_toggle_app/features/members/domain/model/project_membership.dart';

/// Compact card-row for a project member, matching Users V5 Grouped style.
///
/// Stripe left (role color) + avatar + name/email + role badge + date + actions.
class MemberCard extends StatefulWidget {
  final ProjectMembership membership;
  final ValueChanged<ProjectRole>? onRoleChange;
  final VoidCallback? onDelete;

  const MemberCard({
    super.key,
    required this.membership,
    this.onRoleChange,
    this.onDelete,
  });

  @override
  State<MemberCard> createState() => _MemberCardState();
}

class _MemberCardState extends State<MemberCard> {
  bool _hovering = false;

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

  static const _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  static String _formatDate(DateTime dt) {
    return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final m = widget.membership;
    final Color roleColor = _roleColor(m.role);

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(width: 3, color: AppColors.navy),
          boxShadow: [
            BoxShadow(
              color: _hovering ? AppColors.navy : const Color(0xFFDDD8CC),
              offset: Offset(0, _hovering ? 3 : 2),
            ),
          ],
        ),
        transform: _hovering
            ? Matrix4.translationValues(0, -1, 0)
            : Matrix4.identity(),
        child: Stack(
          children: [
            // Role stripe left
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 4, color: roleColor),
            ),
            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
              child: Row(
                children: [
                  // Avatar
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: roleColor.withOpacity(0.12),
                      border: Border.all(width: 2, color: AppColors.navy),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      m.displayName.isNotEmpty
                          ? m.displayName[0].toUpperCase()
                          : '?',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: roleColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Name + email
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          m.displayName,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (m.email != null && m.email != m.name)
                          Text(
                            m.email!,
                            style: TextStyle(
                              fontSize: 10,
                              color: AppColors.navy.withOpacity(0.4),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Role badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(5),
                      color: roleColor.withOpacity(0.1),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 5,
                          height: 5,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: roleColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          m.roleLabel,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: roleColor,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 10),

                  // Date
                  Text(
                    _formatDate(m.grantedAt),
                    style: TextStyle(
                      fontSize: 9,
                      color: AppColors.navy.withOpacity(0.3),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // Actions
                  if (widget.onRoleChange != null)
                    _RolePopup(
                      currentRole: m.role,
                      onSelected: widget.onRoleChange!,
                    ),
                  if (widget.onDelete != null)
                    _ActionBtn(
                      icon: Icons.delete_outline_rounded,
                      color: AppColors.coral,
                      onTap: widget.onDelete!,
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Role popup ────────────────────────────────────────────────

class _RolePopup extends StatelessWidget {
  final ProjectRole currentRole;
  final ValueChanged<ProjectRole> onSelected;

  const _RolePopup({required this.currentRole, required this.onSelected});

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
    return PopupMenuButton<ProjectRole>(
      onSelected: onSelected,
      offset: const Offset(0, 36),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.navy.withOpacity(0.12)),
      ),
      itemBuilder: (_) => ProjectRole.values.map((role) {
        final bool isCurrent = role == currentRole;
        return PopupMenuItem<ProjectRole>(
          value: role,
          height: 36,
          child: Row(
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: _roleColor(role),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                role.label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isCurrent ? FontWeight.w700 : FontWeight.w400,
                  color: isCurrent
                      ? _roleColor(role)
                      : AppColors.navy.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: _ActionBtn(
        icon: Icons.swap_horiz_rounded,
        color: AppColors.teal,
        onTap: () {},
        interactive: false,
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────

class _ActionBtn extends StatefulWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  final bool interactive;

  const _ActionBtn({
    required this.icon,
    required this.color,
    required this.onTap,
    this.interactive = true,
  });

  @override
  State<_ActionBtn> createState() => _ActionBtnState();
}

class _ActionBtnState extends State<_ActionBtn> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final child = MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 30,
        height: 30,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: widget.color.withOpacity(_hovering ? 0.15 : 0.06),
          border: Border.all(
            width: 2,
            color: widget.color.withOpacity(_hovering ? 0.6 : 0.35),
          ),
        ),
        child: Icon(widget.icon, size: 14, color: widget.color),
      ),
    );

    if (!widget.interactive) return child;

    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: child,
    );
  }
}

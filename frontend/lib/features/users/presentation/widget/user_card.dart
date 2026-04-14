import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:togli_app/features/auth/domain/model/user.dart';
import 'package:togli_app/app/theme/app_colors.dart';

const _months = [
  'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
  'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
];

String _formatDate(DateTime d) {
  final day = d.day.toString().padLeft(2, '0');
  final mon = _months[d.month - 1];
  final year = (d.year % 100).toString().padLeft(2, '0');
  return '$day $mon $year';
}

const _creamDark = Color(0xFFDDD8CC);

class UserCard extends StatefulWidget {
  final User user;
  final VoidCallback? onToggleRole;
  final VoidCallback? onToggleActive;
  final bool isCurrentUser;

  const UserCard({
    super.key,
    required this.user,
    this.onToggleRole,
    this.onToggleActive,
    this.isCurrentUser = false,
  });

  @override
  State<UserCard> createState() => _UserCardState();
}

class _UserCardState extends State<UserCard> {
  bool _hovering = false;

  Color get _stripeColor {
    if (!widget.user.active) return _creamDark;
    return widget.user.isPlatformAdmin
        ? const Color(0xFFF5C842)
        : AppColors.teal;
  }

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final isInactive = !user.active;

    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        transform: Matrix4.translationValues(0, _hovering ? -1 : 0, 0),
        margin: const EdgeInsets.only(bottom: 10),
        child: Opacity(
          opacity: isInactive ? 0.55 : 1.0,
          child: Stack(
            children: [
              // Main card body
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: widget.isCurrentUser ? AppColors.coral : AppColors.navy,
                    width: 3,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _hovering ? AppColors.navy : _creamDark,
                      offset: Offset(0, _hovering ? 3 : 2),
                    ),
                  ],
                ),
                padding: const EdgeInsets.only(
                    left: 18, right: 14, top: 10, bottom: 10),
                child: Row(
                  children: [
                    // Avatar
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.navy, width: 2),
                        color: _stripeColor.withOpacity(0.12),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        user.displayName.isNotEmpty
                            ? user.displayName[0].toUpperCase()
                            : '?',
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _stripeColor == _creamDark
                              ? AppColors.navy.withOpacity(0.4)
                              : _stripeColor,
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
                            user.displayName,
                            style: GoogleFonts.fredoka(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (user.name != null) ...[
                            const SizedBox(height: 1),
                            Text(
                              user.email.value,
                              style: GoogleFonts.fredoka(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Badges
                    _RoleBadge(user: user),
                    const SizedBox(width: 6),
                    _ActiveBadge(active: user.active),
                    const SizedBox(width: 12),

                    // Date
                    Text(
                      _formatDate(user.createdAt),
                      style: GoogleFonts.fredoka(
                        fontSize: 9,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 10),

                    // Action buttons or "You" badge
                    if (widget.isCurrentUser)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 3),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          color: AppColors.teal.withOpacity(0.12),
                          border: Border.all(
                            color: AppColors.teal.withOpacity(0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Text(
                          'You',
                          style: GoogleFonts.fredoka(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.teal,
                            letterSpacing: 0.5,
                          ),
                        ),
                      )
                    else ...[
                      if (widget.onToggleRole != null)
                        _CardActionButton(
                          icon: user.isPlatformAdmin
                              ? Icons.arrow_downward_rounded
                              : Icons.arrow_upward_rounded,
                          borderColor: AppColors.yellow,
                          bgColor: AppColors.yellow.withOpacity(0.10),
                          iconColor: AppColors.yellow,
                          onTap: widget.onToggleRole!,
                        ),
                      if (widget.onToggleRole != null)
                        const SizedBox(width: 6),

                      if (widget.onToggleActive != null)
                        _CardActionButton(
                          icon: user.active
                              ? Icons.block_rounded
                              : Icons.check_circle_outline_rounded,
                          borderColor: user.active
                              ? AppColors.coral
                              : AppColors.green,
                          bgColor: user.active
                              ? AppColors.coral.withOpacity(0.10)
                              : AppColors.green.withOpacity(0.10),
                          iconColor:
                              user.active ? AppColors.coral : AppColors.green,
                          onTap: widget.onToggleActive!,
                        ),
                    ],
                  ],
                ),
              ),

              // Left stripe (absolute positioned via Stack)
              Positioned(
                left: 3,
                top: 8,
                bottom: 8,
                child: Container(
                  width: 4,
                  decoration: BoxDecoration(
                    color: _stripeColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Role badge ─────────────────────────────────────────────────────

class _RoleBadge extends StatelessWidget {
  final User user;
  const _RoleBadge({required this.user});

  @override
  Widget build(BuildContext context) {
    final Color color =
        user.isPlatformAdmin ? AppColors.yellow : AppColors.teal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withOpacity(0.12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        user.roleLabel,
        style: GoogleFonts.fredoka(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

// ── Active / Inactive badge ────────────────────────────────────────

class _ActiveBadge extends StatelessWidget {
  final bool active;
  const _ActiveBadge({required this.active});

  @override
  Widget build(BuildContext context) {
    final Color color = active ? AppColors.green : _creamDark;
    final String label = active ? 'Active' : 'Inactive';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        color: color.withOpacity(active ? 0.12 : 0.25),
        border: Border.all(color: color.withOpacity(active ? 0.3 : 0.5)),
      ),
      child: Text(
        label,
        style: GoogleFonts.fredoka(
          fontSize: 9,
          fontWeight: FontWeight.w600,
          color: active ? color : AppColors.navy.withOpacity(0.4),
        ),
      ),
    );
  }
}

// ── Action button ──────────────────────────────────────────────────

class _CardActionButton extends StatefulWidget {
  final IconData icon;
  final Color borderColor;
  final Color bgColor;
  final Color iconColor;
  final VoidCallback onTap;

  const _CardActionButton({
    required this.icon,
    required this.borderColor,
    required this.bgColor,
    required this.iconColor,
    required this.onTap,
  });

  @override
  State<_CardActionButton> createState() => _CardActionButtonState();
}

class _CardActionButtonState extends State<_CardActionButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(9),
            color: _hovering
                ? widget.borderColor.withOpacity(0.18)
                : widget.bgColor,
            border: Border.all(
              color: widget.borderColor,
              width: _hovering ? 2 : 1.5,
            ),
          ),
          child: Icon(
            widget.icon,
            size: 16,
            color: widget.iconColor,
          ),
        ),
      ),
    );
  }
}

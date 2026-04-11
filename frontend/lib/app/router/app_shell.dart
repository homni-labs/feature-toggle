import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:feature_toggle_app/app/router/app_router.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_cubit.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_state.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';
import 'package:feature_toggle_app/app/theme/app_theme.dart';
import 'package:feature_toggle_app/core/presentation/widgets/animated_background.dart';

enum _PageId { projects, users }

class _NavItem {
  final IconData icon;
  final String label;
  final _PageId pageId;

  const _NavItem(
      {required this.icon, required this.label, required this.pageId});
}

class AppShell extends StatelessWidget {
  final String currentPath;
  final Widget child;

  const AppShell({super.key, required this.currentPath, required this.child});

  List<_NavItem> _buildNavItems(AuthAuthenticated auth) {
    final bool isPlatformAdmin =
        auth.currentUser?.isPlatformAdmin ?? false;
    return [
      const _NavItem(
          icon: Icons.folder_outlined,
          label: 'Projects',
          pageId: _PageId.projects),
      if (isPlatformAdmin)
        const _NavItem(
            icon: Icons.people_outline_rounded,
            label: 'Users',
            pageId: _PageId.users),
    ];
  }

  int _selectedIndex(List<_NavItem> navItems) {
    if (currentPath.startsWith('/users')) {
      final idx = navItems.indexWhere((n) => n.pageId == _PageId.users);
      return idx >= 0 ? idx : 0;
    }
    return 0;
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }

        final bool isNarrow = MediaQuery.of(context).size.width < 700;
        final String? userName = authState.currentUser?.displayName;
        final String? userEmail = authState.currentUser?.email.value;
        final String? userRole = authState.currentUser?.roleLabel;
        final List<_NavItem> navItems = _buildNavItems(authState);
        final int selected = _selectedIndex(navItems);

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          body: Stack(
            children: [
              const Positioned.fill(child: AnimatedBackground()),
              Row(
                children: [
                  _Sidebar(
                    navItems: navItems,
                    selectedIndex: selected,
                    collapsed: isNarrow,
                    userName: userName,
                    userEmail: userEmail,
                    userRole: userRole,
                    onSelect: (int i) {
                      switch (navItems[i].pageId) {
                        case _PageId.projects:
                          context.go(AppRoutes.projects);
                        case _PageId.users:
                          context.go(AppRoutes.users);
                      }
                    },
                    onLogout: () => context.read<AuthCubit>().logout(),
                  ),
                  Expanded(child: child),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Sidebar (cartoon style from sidebar-redesign.html) ──────────

class _Sidebar extends StatelessWidget {
  final List<_NavItem> navItems;
  final int selectedIndex;
  final bool collapsed;
  final String? userName;
  final String? userEmail;
  final String? userRole;
  final ValueChanged<int> onSelect;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.navItems,
    required this.selectedIndex,
    required this.collapsed,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.onSelect,
    required this.onLogout,
  });

  Color _roleColor() {
    switch (userRole) {
      case 'Platform Admin':
        return const Color(0xFFA08020); // yellow-ish for PA
      case 'User':
        return AppColors.teal;
      default:
        return AppColors.purple;
    }
  }

  Color _roleBg() {
    switch (userRole) {
      case 'Platform Admin':
        return AppColors.yellow.withOpacity(0.1);
      case 'User':
        return AppColors.teal.withOpacity(0.1);
      default:
        return AppColors.purple.withOpacity(0.1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = collapsed ? 68.0 : 240.0;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: width,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          right: BorderSide(color: AppColors.navy, width: 3),
        ),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // ── Top: Logo + brand ──────────────────────────
            Container(
              padding: const EdgeInsets.symmetric(vertical: 20),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: Color(0xFFDDD8CC),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    width: collapsed ? 40 : 96,
                    height: collapsed ? 40 : 96,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.cream,
                      border: Border.all(width: 3, color: AppColors.navy),
                      boxShadow: const [
                        BoxShadow(
                          color: AppColors.navy,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo_no_text.jpeg',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  if (!collapsed) ...[
                    const SizedBox(height: 10),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Tog',
                          style: GoogleFonts.fredoka(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.navy,
                            letterSpacing: 0.5,
                          ),
                        ),
                        Text(
                          'li',
                          style: GoogleFonts.fredoka(
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            color: AppColors.green,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            // ── Nav ────────────────────────────────────────
            if (!collapsed)
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 12, 10, 0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'NAVIGATION',
                    style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy.withOpacity(0.3),
                      letterSpacing: 1.5,
                    ),
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Column(
                children: List.generate(navItems.length, (int i) {
                  final _NavItem item = navItems[i];
                  return _NavButton(
                    icon: item.icon,
                    label: item.label,
                    active: i == selectedIndex,
                    collapsed: collapsed,
                    onTap: () => onSelect(i),
                  );
                }),
              ),
            ),

            const Spacer(),

            // ── Bottom: User info + logout ─────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Color(0xFFDDD8CC),
                    width: 2,
                  ),
                ),
              ),
              child: Column(
                children: [
                  if (userName != null)
                    Container(
                      padding: EdgeInsets.all(collapsed ? 8 : 10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFDDD8CC),
                          width: 2,
                        ),
                        color: const Color(0xFFF5F2EB),
                      ),
                      child: collapsed
                          ? Center(
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _roleBg(),
                                  border: Border.all(
                                    width: 2,
                                    color: AppColors.navy,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  (userName ?? '?')[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _roleColor(),
                                  ),
                                ),
                              ),
                            )
                          : Row(
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _roleBg(),
                                    border: Border.all(
                                      width: 2,
                                      color: AppColors.navy,
                                    ),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    (userName ?? '?')[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: _roleColor(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        userName ?? '',
                                        style: GoogleFonts.fredoka(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.navy,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (userEmail != null)
                                        Text(
                                          userEmail!,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: AppColors.navy
                                                .withOpacity(0.4),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (userRole != null) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 7,
                                                  vertical: 2),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(5),
                                            color: _roleBg(),
                                          ),
                                          child: Text(
                                            userRole!,
                                            style: TextStyle(
                                              fontSize: 9,
                                              fontWeight: FontWeight.w700,
                                              color: _roleColor(),
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  const SizedBox(height: 6),
                  _LogoutButton(
                    collapsed: collapsed,
                    onTap: onLogout,
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

// ── Logout button ─────────────────────────────────────────────

class _LogoutButton extends StatefulWidget {
  final bool collapsed;
  final VoidCallback onTap;
  const _LogoutButton({required this.collapsed, required this.onTap});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: _hovering
                ? AppColors.coral.withOpacity(0.06)
                : Colors.transparent,
          ),
          child: Row(
            mainAxisAlignment: widget.collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                Icons.logout_rounded,
                size: 16,
                color: _hovering
                    ? AppColors.coral
                    : AppColors.navy.withOpacity(0.4),
              ),
              if (!widget.collapsed) ...[
                const SizedBox(width: 8),
                Text(
                  'Sign out',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _hovering
                        ? AppColors.coral
                        : AppColors.navy.withOpacity(0.4),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── Nav button (cartoon style) ────────────────────────────────

class _NavButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool active;
  final bool collapsed;
  final VoidCallback onTap;

  const _NavButton({
    required this.icon,
    required this.label,
    required this.active,
    required this.collapsed,
    required this.onTap,
  });

  @override
  State<_NavButton> createState() => _NavButtonState();
}

class _NavButtonState extends State<_NavButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    final Color iconColor = widget.active
        ? AppColors.coral
        : _hovering
            ? AppColors.navy.withOpacity(0.8)
            : AppColors.navy.withOpacity(0.4);
    final Color textColor =
        widget.active ? AppColors.navy : AppColors.navy.withOpacity(0.5);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 0 : 12,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: widget.active
                  ? AppColors.coral.withOpacity(0.06)
                  : _hovering
                      ? AppColors.navy.withOpacity(0.04)
                      : Colors.transparent,
              border: widget.active
                  ? Border.all(
                      color: AppColors.coral.withOpacity(0.15), width: 2)
                  : Border.all(color: Colors.transparent, width: 2),
            ),
            child: widget.collapsed
                ? Center(
                    child: Icon(widget.icon, size: 20, color: iconColor))
                : Row(
                    children: [
                      Icon(widget.icon, size: 20, color: iconColor),
                      const SizedBox(width: 10),
                      Text(
                        widget.label,
                        style: GoogleFonts.fredoka(
                          fontSize: 13,
                          fontWeight: widget.active
                              ? FontWeight.w700
                              : FontWeight.w500,
                          color: textColor,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

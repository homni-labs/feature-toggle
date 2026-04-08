import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feature_toggle_app/features/auth/application/bloc/auth_cubit.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_state.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';
import 'package:feature_toggle_app/app/theme/app_theme.dart';
import 'package:feature_toggle_app/core/presentation/widgets/animated_background.dart';
import 'package:feature_toggle_app/features/projects/presentation/screen/projects_screen.dart';
import 'package:feature_toggle_app/features/users/presentation/screen/users_screen.dart';

enum _PageId { projects, users }

class _NavItem {
  final IconData icon;
  final String label;
  final _PageId pageId;

  const _NavItem(
      {required this.icon, required this.label, required this.pageId});
}

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _selectedIndex = 0;

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

        if (_selectedIndex >= navItems.length) {
          _selectedIndex = 0;
        }

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          body: Stack(
            children: [
              const Positioned.fill(child: AnimatedBackground()),
              Row(
                children: [
                  _Sidebar(
                    navItems: navItems,
                    selectedIndex: _selectedIndex,
                    collapsed: isNarrow,
                    userName: userName,
                    userEmail: userEmail,
                    userRole: userRole,
                    onSelect: (int i) => setState(() => _selectedIndex = i),
                    onLogout: () => context.read<AuthCubit>().logout(),
                  ),
                  Expanded(child: _buildPage(navItems)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildPage(List<_NavItem> navItems) {
    final _PageId pageId = navItems[_selectedIndex].pageId;
    switch (pageId) {
      case _PageId.projects:
        return const ProjectsPage();
      case _PageId.users:
        return const UsersPage();
    }
  }
}

// ── Sidebar ─────────────────────────────────────────────────────

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
        return AppColors.coral;
      case 'User':
        return AppColors.teal;
      default:
        return AppColors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final double width = collapsed ? 68.0 : 230.0;

    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: width,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.06),
            border: Border(
              right: BorderSide(color: Colors.white.withOpacity(0.08)),
            ),
          ),
          child: SafeArea(
            child: Column(
              children: [
                const SizedBox(height: 20),

                // Logo
                Container(
                  width: collapsed ? 44 : 120,
                  height: collapsed ? 44 : 120,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.cream,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.coral.withOpacity(0.3),
                        blurRadius: 14,
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

                const SizedBox(height: 32),

                // Nav items
                ...List.generate(navItems.length, (int i) {
                  final _NavItem item = navItems[i];
                  return _NavButton(
                    icon: item.icon,
                    label: item.label,
                    active: i == selectedIndex,
                    collapsed: collapsed,
                    onTap: () => onSelect(i),
                  );
                }),

                const Spacer(),

                // User info
                if (userName != null) ...[
                  Padding(
                    padding: EdgeInsets.symmetric(
                        horizontal: collapsed ? 8 : 16),
                    child: Container(
                      padding: EdgeInsets.all(collapsed ? 8 : 12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withOpacity(0.06),
                      ),
                      child: collapsed
                          ? Center(
                              child: CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    _roleColor().withOpacity(0.2),
                                child: Text(
                                  (userName ?? '?')[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _roleColor(),
                                  ),
                                ),
                              ),
                            )
                          : Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      _roleColor().withOpacity(0.2),
                                  child: Text(
                                    (userName ?? '?')[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
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
                                        style: const TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      if (userEmail != null)
                                        Text(
                                          userEmail!,
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: Colors.white
                                                .withOpacity(0.4),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      if (userRole != null) ...[
                                        const SizedBox(height: 4),
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                                  horizontal: 8,
                                                  vertical: 2),
                                          decoration: BoxDecoration(
                                            borderRadius:
                                                BorderRadius.circular(8),
                                            color: _roleColor()
                                                .withOpacity(0.15),
                                          ),
                                          child: Text(
                                            userRole!,
                                            style: TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w600,
                                              color: _roleColor(),
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
                  ),
                  const SizedBox(height: 8),
                ],

                // Logout
                _NavButton(
                  icon: Icons.logout_rounded,
                  label: 'Logout',
                  active: false,
                  collapsed: collapsed,
                  onTap: onLogout,
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Nav button ──────────────────────────────────────────────────

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
    final double bgOpacity = widget.active
        ? 0.12
        : _hovering
            ? 0.08
            : 0.0;
    final Color iconColor = widget.active
        ? AppColors.coral
        : _hovering
            ? Colors.white.withOpacity(0.8)
            : Colors.white.withOpacity(0.4);
    final Color textColor =
        widget.active ? Colors.white : Colors.white.withOpacity(0.5);

    return Padding(
      padding: EdgeInsets.symmetric(
        horizontal: widget.collapsed ? 12 : 14,
        vertical: 3,
      ),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hovering = true),
        onExit: (_) => setState(() => _hovering = false),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: EdgeInsets.symmetric(
              horizontal: widget.collapsed ? 0 : 14,
              vertical: 12,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              color: Colors.white.withOpacity(bgOpacity),
              border: widget.active
                  ? Border.all(color: AppColors.coral.withOpacity(0.2))
                  : null,
            ),
            child: widget.collapsed
                ? Center(
                    child:
                        Icon(widget.icon, size: 22, color: iconColor))
                : Row(
                    children: [
                      Icon(widget.icon, size: 20, color: iconColor),
                      const SizedBox(width: 12),
                      Text(
                        widget.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: widget.active
                              ? FontWeight.w600
                              : FontWeight.w400,
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

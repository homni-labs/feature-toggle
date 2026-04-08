import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feature_toggle_app/features/auth/application/bloc/auth_cubit.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_state.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';
import 'package:feature_toggle_app/app/theme/app_theme.dart';
import 'package:feature_toggle_app/core/domain/value_objects/project_role.dart';
import 'package:feature_toggle_app/core/presentation/widgets/animated_background.dart';
import 'package:feature_toggle_app/features/api_keys/presentation/screen/api_keys_screen.dart';
import 'package:feature_toggle_app/features/environments/presentation/screen/environments_screen.dart';
import 'package:feature_toggle_app/features/toggles/presentation/screen/toggles_screen.dart';
import 'package:feature_toggle_app/features/members/presentation/screen/members_screen.dart';
import 'package:feature_toggle_app/features/projects/presentation/screen/project_settings_screen.dart';

enum _PageId { toggles, environments, members, apiKeys, settings }

class _NavItem {
  final IconData icon;
  final String label;
  final _PageId pageId;

  const _NavItem(
      {required this.icon, required this.label, required this.pageId});
}

/// Project-level shell. Shown when the auth state has a selected project.
class ShellPage extends StatefulWidget {
  const ShellPage({super.key});

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  int _selectedIndex = 0;

  List<_NavItem> _buildNavItems(AuthAuthenticated auth) {
    final bool canManage = auth.canManageMembers;
    return [
      const _NavItem(
          icon: Icons.toggle_on_rounded,
          label: 'Toggles',
          pageId: _PageId.toggles),
      const _NavItem(
          icon: Icons.cloud_outlined,
          label: 'Environments',
          pageId: _PageId.environments),
      if (canManage)
        const _NavItem(
            icon: Icons.people_outlined,
            label: 'Members',
            pageId: _PageId.members),
      if (canManage)
        const _NavItem(
            icon: Icons.key_outlined,
            label: 'API Keys',
            pageId: _PageId.apiKeys),
      if (canManage)
        const _NavItem(
            icon: Icons.settings_outlined,
            label: 'Settings',
            pageId: _PageId.settings),
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
        final user = authState.currentUser;
        final project = authState.currentProject;
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
                  _ProjectSidebar(
                    navItems: navItems,
                    selectedIndex: _selectedIndex,
                    collapsed: isNarrow,
                    projectKey: project?.slug.value ?? '',
                    projectName: project?.name ?? '',
                    projectRole: authState.currentProjectRole,
                    userName: user?.displayName,
                    userEmail: user?.email.value,
                    userRole: authState.currentProjectRole?.label,
                    onSelect: (i) => setState(() => _selectedIndex = i),
                    onBack: () => context.read<AuthCubit>().clearProject(),
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
      case _PageId.toggles:
        return const HomePage();
      case _PageId.environments:
        return const EnvironmentsPage();
      case _PageId.members:
        return const MembersPage();
      case _PageId.apiKeys:
        return const ApiKeysPage();
      case _PageId.settings:
        return const ProjectSettingsPage();
    }
  }
}

// ── Project Sidebar ────────────────────────────────────────────

class _ProjectSidebar extends StatelessWidget {
  final List<_NavItem> navItems;
  final int selectedIndex;
  final bool collapsed;
  final String projectKey;
  final String projectName;
  final ProjectRole? projectRole;
  final String? userName;
  final String? userEmail;
  final String? userRole;
  final ValueChanged<int> onSelect;
  final VoidCallback onBack;
  final VoidCallback onLogout;

  const _ProjectSidebar({
    required this.navItems,
    required this.selectedIndex,
    required this.collapsed,
    required this.projectKey,
    required this.projectName,
    this.projectRole,
    required this.userName,
    required this.userEmail,
    required this.userRole,
    required this.onSelect,
    required this.onBack,
    required this.onLogout,
  });

  Color _userRoleColor() {
    switch (userRole) {
      case 'Admin':
        return AppColors.coral;
      case 'Editor':
        return AppColors.teal;
      case 'Reader':
        return AppColors.purple;
      default:
        return AppColors.coral;
    }
  }

  Color _projectRoleColor() {
    switch (projectRole) {
      case ProjectRole.admin:
        return AppColors.coral;
      case ProjectRole.editor:
        return AppColors.teal;
      case ProjectRole.reader:
        return AppColors.purple;
      case null:
        return AppColors.coral; // Platform Admin
    }
  }

  String _projectRoleLabel() {
    if (projectRole == null) return 'Platform Admin';
    return projectRole!.label;
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
                const SizedBox(height: 12),

                // Back button
                _NavButton(
                  icon: Icons.arrow_back_rounded,
                  label: 'Projects',
                  active: false,
                  collapsed: collapsed,
                  onTap: onBack,
                ),

                const SizedBox(height: 8),

                // Project info
                if (!collapsed)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        color: Colors.white.withOpacity(0.06),
                        border: Border.all(
                            color: AppColors.coral.withOpacity(0.15)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            projectKey,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.coral.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            projectName,
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                              color:
                                  _projectRoleColor().withOpacity(0.15),
                            ),
                            child: Text(
                              _projectRoleLabel(),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: _projectRoleColor(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                const SizedBox(height: 16),

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
                                    _userRoleColor().withOpacity(0.2),
                                child: Text(
                                  (userName ?? '?')[0].toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _userRoleColor(),
                                  ),
                                ),
                              ),
                            )
                          : Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      _userRoleColor().withOpacity(0.2),
                                  child: Text(
                                    (userName ?? '?')[0].toUpperCase(),
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: _userRoleColor(),
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

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:togli_app/app/di/injection.dart';
import 'package:togli_app/app/router/app_router.dart';
import 'package:togli_app/features/auth/application/bloc/auth_cubit.dart';
import 'package:togli_app/features/auth/application/bloc/auth_state.dart';
import 'package:togli_app/app/theme/app_colors.dart';
import 'package:togli_app/app/theme/app_theme.dart';
import 'package:togli_app/core/domain/value_objects/project_role.dart';
import 'package:togli_app/core/presentation/widgets/animated_background.dart';
import 'package:togli_app/core/domain/failure.dart';
import 'package:togli_app/features/projects/domain/port/project_repository.dart';

enum _PageId { toggles, environments, members, apiKeys, settings }
enum _ProjectError { none, forbidden, notFound }

class _NavItem {
  final IconData icon;
  final String label;
  final _PageId pageId;

  const _NavItem(
      {required this.icon, required this.label, required this.pageId});
}

/// Project-level shell. Shown when the URL contains a project slug.
class ShellPage extends StatefulWidget {
  final String slug;
  final String currentPath;
  final Widget child;

  const ShellPage({
    super.key,
    required this.slug,
    required this.currentPath,
    required this.child,
  });

  @override
  State<ShellPage> createState() => _ShellPageState();
}

class _ShellPageState extends State<ShellPage> {
  bool _loadingProject = false;
  _ProjectError _error = _ProjectError.none;

  @override
  void initState() {
    super.initState();
    _ensureProjectLoaded();
  }

  @override
  void didUpdateWidget(ShellPage old) {
    super.didUpdateWidget(old);
    if (old.slug != widget.slug) {
      _error = _ProjectError.none;
      _ensureProjectLoaded();
    }
  }

  Future<void> _ensureProjectLoaded() async {
    final authCubit = context.read<AuthCubit>();
    final state = authCubit.state;
    if (state is! AuthAuthenticated) return;
    if (state.currentProject?.slug.value == widget.slug) return;

    setState(() {
      _loadingProject = true;
      _error = _ProjectError.none;
    });

    final token = await authCubit.getValidAccessToken();
    if (token == null || !mounted) {
      if (mounted) context.go(AppRoutes.projects);
      return;
    }

    final result = await sl<ProjectRepository>().getBySlug(
      accessToken: token,
      slug: widget.slug,
    );

    if (!mounted) return;

    result.fold(
      (failure) {
        if (failure is ForbiddenFailure) {
          setState(() {
            _loadingProject = false;
            _error = _ProjectError.forbidden;
          });
        } else if (failure is NotFoundFailure) {
          setState(() {
            _loadingProject = false;
            _error = _ProjectError.notFound;
          });
        } else {
          context.go(AppRoutes.projects);
        }
      },
      (project) {
        authCubit.selectProject(project, project.myRole);
        setState(() => _loadingProject = false);
      },
    );
  }

  List<_NavItem> _buildNavItems(AuthAuthenticated auth) {
    if (auth.isProjectArchived) {
      return const [
        _NavItem(
          icon: Icons.settings_outlined,
          label: 'Settings',
          pageId: _PageId.settings,
        ),
      ];
    }

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

  int _selectedIndex(List<_NavItem> navItems) {
    final path = widget.currentPath;
    _PageId? pageId;
    if (path.endsWith('/environments')) {
      pageId = _PageId.environments;
    } else if (path.endsWith('/members')) {
      pageId = _PageId.members;
    } else if (path.endsWith('/api-keys') || path.contains('/api-keys/')) {
      pageId = _PageId.apiKeys;
    } else if (path.endsWith('/settings')) {
      pageId = _PageId.settings;
    } else {
      pageId = _PageId.toggles;
    }
    final idx = navItems.indexWhere((n) => n.pageId == pageId);
    return idx >= 0 ? idx : 0;
  }

  void _onNavSelect(List<_NavItem> navItems, int i) {
    final slug = widget.slug;
    switch (navItems[i].pageId) {
      case _PageId.toggles:
        context.go(AppRoutes.projectToggles(slug));
      case _PageId.environments:
        context.go(AppRoutes.projectEnvironments(slug));
      case _PageId.members:
        context.go(AppRoutes.projectMembers(slug));
      case _PageId.apiKeys:
        context.go(AppRoutes.projectApiKeys(slug));
      case _PageId.settings:
        context.go(AppRoutes.projectSettings(slug));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthCubit, AuthState>(
      builder: (context, authState) {
        if (authState is! AuthAuthenticated) {
          return const SizedBox.shrink();
        }

        // Show error page for 403 / 404
        if (_error != _ProjectError.none) {
          return _ProjectErrorPage(
            error: _error,
            slug: widget.slug,
            onBack: () => context.go(AppRoutes.projects),
          );
        }

        // Show loading while restoring project from URL
        if (_loadingProject || !authState.isInProject) {
          return Scaffold(
            backgroundColor: AppTheme.scaffoldBackground,
            body: Stack(
              children: [
                const Positioned.fill(child: AnimatedBackground()),
                const Center(
                  child: CircularProgressIndicator(color: AppColors.coral),
                ),
              ],
            ),
          );
        }

        final bool isNarrow = MediaQuery.of(context).size.width < 700;
        final user = authState.currentUser;
        final project = authState.currentProject;
        final List<_NavItem> navItems = _buildNavItems(authState);
        final int selected = _selectedIndex(navItems);

        return Scaffold(
          backgroundColor: AppTheme.scaffoldBackground,
          body: Stack(
            children: [
              const Positioned.fill(child: AnimatedBackground()),
              Row(
                children: [
                  _ProjectSidebar(
                    navItems: navItems,
                    selectedIndex: selected,
                    collapsed: isNarrow,
                    projectKey: project?.slug.value ?? '',
                    projectName: project?.name ?? '',
                    projectRole: authState.currentProjectRole,
                    userName: user?.displayName,
                    userEmail: user?.email.value,
                    userRole: authState.currentProjectRole?.label,
                    onSelect: (i) => _onNavSelect(navItems, i),
                    onBack: () {
                      context.read<AuthCubit>().clearProject();
                      context.go(AppRoutes.projects);
                    },
                    onLogout: () => context.read<AuthCubit>().logout(),
                  ),
                  Expanded(child: widget.child),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Project Sidebar (cartoon style from sidebar-redesign.html) ──

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

  Color _projectRoleColor() {
    switch (projectRole) {
      case ProjectRole.admin:
        return AppColors.coral;
      case ProjectRole.editor:
        return AppColors.teal;
      case ProjectRole.reader:
        return AppColors.purple;
      case null:
        return const Color(0xFFA08020);
    }
  }

  String _projectRoleLabel() {
    if (projectRole == null) return 'Platform Admin';
    return projectRole!.label;
  }

  Color _platformRoleColor() {
    // Platform-level role for user card
    final bool isPA = projectRole == null; // null means PA
    return isPA ? const Color(0xFFA08020) : AppColors.teal;
  }

  Color _platformRoleBg() {
    final bool isPA = projectRole == null;
    return isPA
        ? AppColors.yellow.withOpacity(0.1)
        : AppColors.teal.withOpacity(0.1);
  }

  String _platformRoleLabel() {
    return projectRole == null ? 'Platform Admin' : 'User';
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
            // ── Top: Back + project info ──────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Color(0xFFDDD8CC), width: 2),
                ),
              ),
              child: Column(
                children: [
                  // Back button
                  _BackButton(
                    collapsed: collapsed,
                    onTap: onBack,
                  ),
                  if (!collapsed) ...[
                    const SizedBox(height: 10),
                    // Project info card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.coral,
                          width: 2,
                        ),
                        color: AppColors.coral.withOpacity(0.04),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            projectKey,
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: AppColors.coral,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            projectName,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.navy,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(6),
                              color: _projectRoleColor().withOpacity(0.1),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(
                                  width: 5,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _projectRoleColor(),
                                  ),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  _projectRoleLabel(),
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: _projectRoleColor(),
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                    'PROJECT',
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

            // ���─ Bottom: User + logout ──────────────────────
            Container(
              padding: const EdgeInsets.all(14),
              decoration: const BoxDecoration(
                border: Border(
                  top: BorderSide(color: Color(0xFFDDD8CC), width: 2),
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
                                  color: _platformRoleBg(),
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
                                    color: _platformRoleColor(),
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
                                    color: _platformRoleBg(),
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
                                      color: _platformRoleColor(),
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
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                          horizontal: 7,
                                          vertical: 2,
                                        ),
                                        decoration: BoxDecoration(
                                          borderRadius:
                                              BorderRadius.circular(5),
                                          color: _platformRoleBg(),
                                        ),
                                        child: Text(
                                          _platformRoleLabel(),
                                          style: TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.w700,
                                            color: _platformRoleColor(),
                                            letterSpacing: 0.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                    ),
                  const SizedBox(height: 6),
                  _LogoutBtn(collapsed: collapsed, onTap: onLogout),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Back button ───────────────────────────────────────────────

class _BackButton extends StatefulWidget {
  final bool collapsed;
  final VoidCallback onTap;
  const _BackButton({required this.collapsed, required this.onTap});

  @override
  State<_BackButton> createState() => _BackButtonState();
}

class _BackButtonState extends State<_BackButton> {
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
          padding: EdgeInsets.symmetric(
            horizontal: widget.collapsed ? 0 : 10,
            vertical: 8,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              width: 2,
              color: _hovering
                  ? AppColors.navy
                  : const Color(0xFFDDD8CC),
            ),
            color: const Color(0xFFF5F2EB),
          ),
          child: Row(
            mainAxisAlignment: widget.collapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                Icons.arrow_back_rounded,
                size: 14,
                color: _hovering
                    ? AppColors.navy
                    : AppColors.navy.withOpacity(0.5),
              ),
              if (!widget.collapsed) ...[
                const SizedBox(width: 8),
                Text(
                  'Back to Projects',
                  style: GoogleFonts.fredoka(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: _hovering
                        ? AppColors.navy
                        : AppColors.navy.withOpacity(0.5),
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

// ── Logout button ─────────────────────────────────────────────

class _LogoutBtn extends StatefulWidget {
  final bool collapsed;
  final VoidCallback onTap;
  const _LogoutBtn({required this.collapsed, required this.onTap});

  @override
  State<_LogoutBtn> createState() => _LogoutBtnState();
}

class _LogoutBtnState extends State<_LogoutBtn> {
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

// ── Project error page (403 / 404) ───────────────────────────

class _ProjectErrorPage extends StatelessWidget {
  final _ProjectError error;
  final String slug;
  final VoidCallback onBack;

  const _ProjectErrorPage({
    required this.error,
    required this.slug,
    required this.onBack,
  });

  @override
  Widget build(BuildContext context) {
    final bool isForbidden = error == _ProjectError.forbidden;
    final IconData icon = isForbidden ? Icons.lock_outline_rounded : Icons.search_off_rounded;
    final String title = isForbidden ? 'Access Denied' : 'Project Not Found';
    final String message = isForbidden
        ? 'You do not have access to project "$slug".\nContact the project admin to request access.'
        : 'Project "$slug" does not exist or has been removed.';

    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          Center(
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: Colors.white,
                border: Border.all(color: AppColors.navy, width: 3),
                boxShadow: const [
                  BoxShadow(color: AppColors.navy, offset: Offset(0, 4)),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isForbidden
                          ? AppColors.coral.withOpacity(0.1)
                          : AppColors.yellow.withOpacity(0.15),
                    ),
                    child: Icon(icon, size: 32,
                        color: isForbidden ? AppColors.coral : AppColors.yellow),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    title,
                    style: GoogleFonts.fredoka(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    message,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.navy.withOpacity(0.6),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: onBack,
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Back to Projects'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

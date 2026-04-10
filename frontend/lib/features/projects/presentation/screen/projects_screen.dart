import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feature_toggle_app/app/di/injection.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';
import 'package:feature_toggle_app/core/domain/failure.dart';
import 'package:feature_toggle_app/core/domain/value_objects/project_role.dart';
import 'package:feature_toggle_app/core/presentation/widgets/app_snackbar.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_cubit.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_state.dart';
import 'package:feature_toggle_app/features/projects/application/bloc/projects_cubit.dart';
import 'package:feature_toggle_app/features/projects/application/bloc/projects_state.dart';
import 'package:feature_toggle_app/features/projects/domain/model/project.dart';
import 'package:feature_toggle_app/features/projects/presentation/widget/project_card.dart';
import 'package:feature_toggle_app/features/projects/presentation/widget/project_dialog.dart'
    show ProjectDialog, ProjectDialogResult;

class ProjectsPage extends StatelessWidget {
  const ProjectsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthCubit authCubit = context.read<AuthCubit>();
    return BlocProvider<ProjectsCubit>(
      create: (_) {
        final ProjectsCubit cubit = sl<ProjectsCubit>();
        _loadProjects(authCubit, cubit);
        return cubit;
      },
      child: const _ProjectsView(),
    );
  }

  static Future<void> _loadProjects(
    AuthCubit auth,
    ProjectsCubit cubit,
  ) async {
    final String? token = await auth.getValidAccessToken();
    if (token != null) {
      await cubit.load(accessToken: token);
    }
  }
}

// ── Main view ──────────────────────────────────────────────────

class _ProjectsView extends StatefulWidget {
  const _ProjectsView();

  @override
  State<_ProjectsView> createState() => _ProjectsViewState();
}

class _ProjectsViewState extends State<_ProjectsView> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  /// Debounces every keystroke for 300ms before firing the cubit search.
  /// Empty string is normalised to `null` so the backend doesn't get a
  /// useless `q=` query parameter.
  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      _runSearch(value);
    });
  }

  Future<void> _runSearch(String value) async {
    final AuthCubit auth = context.read<AuthCubit>();
    final String? token = await auth.getValidAccessToken();
    if (token == null || !mounted) return;
    await context.read<ProjectsCubit>().setSearch(
          accessToken: token,
          searchText: value.isEmpty ? null : value,
        );
  }

  Future<void> _onArchivedFilterChanged(bool? archived) async {
    final AuthCubit auth = context.read<AuthCubit>();
    final String? token = await auth.getValidAccessToken();
    if (token == null || !mounted) return;
    await context.read<ProjectsCubit>().setArchivedFilter(
          accessToken: token,
          archived: archived,
        );
  }

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthCubit>().state;
    final bool isPlatformAdmin = authState is AuthAuthenticated &&
        (authState.currentUser?.isPlatformAdmin ?? false);

    return BlocConsumer<ProjectsCubit, ProjectsState>(
      listener: (BuildContext context, ProjectsState state) {
        if (state is ProjectsError) {
          showAppSnackBar(
            context,
            state.failure,
            isWarning: state.failure is ConflictFailure ||
                state.failure is NotFoundFailure,
          );
        }
      },
      builder: (BuildContext context, ProjectsState state) {
        final ProjectsLoaded? loaded =
            state is ProjectsLoaded ? state : null;

        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row: title + create button ──────────────────
              Row(
                children: [
                  Text(
                    'Projects',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.92),
                    ),
                  ),
                  const Spacer(),
                  if (isPlatformAdmin)
                    _CreateButton(onPressed: () => _onCreate(context)),
                ],
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 4),

              // ── Subtitle ───────────────────────────────────────────
              Text(
                _subtitle(loaded, isPlatformAdmin),
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withOpacity(0.35),
                ),
              ),
              const SizedBox(height: 20),

              // ── Toolbar: search + filters + create ─────────────────
              _Toolbar(
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                archivedFilter: loaded?.archivedFilter,
                onArchivedFilterChanged: _onArchivedFilterChanged,
              ),
              const SizedBox(height: 20),

              // ── Body ──────────────────────────────────────────────
              Expanded(child: _Body(state: state)),

              // ── Pagination ────────────────────────────────────────
              if (loaded != null && loaded.totalPages > 1) ...[
                const SizedBox(height: 16),
                _Pagination(
                  page: loaded.page,
                  totalPages: loaded.totalPages,
                  totalElements: loaded.totalElements,
                  pageSize: loaded.projects.length,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _subtitle(ProjectsLoaded? loaded, bool isPlatformAdmin) {
    if (loaded == null) return '\u00A0'; // non-breaking space, keeps height
    if (isPlatformAdmin) {
      final String archivedFragment = loaded.archivedCount > 0
          ? ' · ${loaded.archivedCount} archived'
          : '';
      return '${loaded.totalCount} projects$archivedFragment · viewing all';
    }
    return '${loaded.totalCount} of your projects';
  }

  Future<void> _onCreate(BuildContext context) async {
    final ProjectDialogResult? result = await showDialog<ProjectDialogResult>(
      context: context,
      builder: (_) => const ProjectDialog(),
    );
    if (result == null || !context.mounted) return;

    final String? token =
        await context.read<AuthCubit>().getValidAccessToken();
    if (token == null || !context.mounted) return;

    await context.read<ProjectsCubit>().create(
          accessToken: token,
          slug: result.slug,
          name: result.name,
          description: result.description,
          environments: result.environments,
        );
  }
}

// ── Body ───────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  const _Body({required this.state});

  final ProjectsState state;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      ProjectsInitial() ||
      ProjectsLoading() =>
        const Center(child: CircularProgressIndicator(color: AppColors.coral)),
      ProjectsError(:final Failure failure) => _ErrorBody(failure: failure),
      ProjectsLoaded(:final List<Project> projects) =>
        projects.isEmpty
            ? const _EmptyState()
            : _ProjectsGrid(projects: projects),
    };
  }
}

// ── Error body ─────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.failure});
  final Failure failure;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 48, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            failure.message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _retry(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.coral,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Future<void> _retry(BuildContext context) async {
    final String? token =
        await context.read<AuthCubit>().getValidAccessToken();
    if (token != null && context.mounted) {
      await context.read<ProjectsCubit>().load(accessToken: token);
    }
  }
}

// ── Projects grid ──────────────────────────────────────────────

class _ProjectsGrid extends StatelessWidget {
  const _ProjectsGrid({required this.projects});

  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthCubit>().state;
    final bool isPlatformAdmin = authState is AuthAuthenticated &&
        (authState.currentUser?.isPlatformAdmin ?? false);

    return LayoutBuilder(
      builder: (context, constraints) {
        // Use the same 2-column 16px-gap grid as the mockup. The 720 cap
        // matches the toggles list cap so the two screens feel related.
        final int columns = constraints.maxWidth >= 800 ? 2 : 1;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                mainAxisExtent: 320,
              ),
              itemCount: projects.length,
              itemBuilder: (BuildContext context, int index) {
                final Project project = projects[index];
                final bool userIsAdmin =
                    project.myRole == ProjectRole.admin;
                final bool canEdit = isPlatformAdmin || userIsAdmin;
                final bool canArchive = isPlatformAdmin;
                final bool canUnarchive = isPlatformAdmin || userIsAdmin;

                return ProjectCard(
                  key: ValueKey(project.id),
                  project: project,
                  showRoleBadge: !isPlatformAdmin,
                  onTap: () => _onTap(context, project),
                  onEdit: canEdit && !project.archived
                      ? () => _onEdit(context, project)
                      : null,
                  onArchive: canArchive && !project.archived
                      ? () => _onArchive(context, project)
                      : null,
                  onUnarchive: canUnarchive && project.archived
                      ? () => _onUnarchive(context, project)
                      : null,
                );
              },
            ),
          ),
        );
      },
    );
  }

  void _onTap(BuildContext context, Project project) {
    context.read<AuthCubit>().selectProject(project, project.myRole);
  }

  Future<void> _onEdit(BuildContext context, Project project) async {
    final ProjectDialogResult? result = await showDialog<ProjectDialogResult>(
      context: context,
      builder: (_) => ProjectDialog(
        isEdit: true,
        initialName: project.name,
        initialDescription: project.description,
      ),
    );
    if (result == null || !context.mounted) return;

    final String? token =
        await context.read<AuthCubit>().getValidAccessToken();
    if (token == null || !context.mounted) return;

    await context.read<ProjectsCubit>().updateProject(
          accessToken: token,
          projectId: project.id,
          name: result.name,
          description: result.description,
        );
  }

  Future<void> _onArchive(BuildContext context, Project project) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Archive Project',
        message: 'Are you sure you want to archive "${project.name}"? '
            'All feature toggles in this project will be disabled and the '
            'project will become read-only.',
        confirmLabel: 'Archive',
      ),
    );
    if (confirmed != true || !context.mounted) return;

    final String? token =
        await context.read<AuthCubit>().getValidAccessToken();
    if (token == null || !context.mounted) return;

    await context.read<ProjectsCubit>().updateProject(
          accessToken: token,
          projectId: project.id,
          archived: true,
        );
  }

  Future<void> _onUnarchive(BuildContext context, Project project) async {
    final String? token =
        await context.read<AuthCubit>().getValidAccessToken();
    if (token == null || !context.mounted) return;

    await context.read<ProjectsCubit>().updateProject(
          accessToken: token,
          projectId: project.id,
          archived: false,
        );
  }
}

// ── Empty state ────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthCubit>().state;
    final bool isPlatformAdmin = authState is AuthAuthenticated &&
        (authState.currentUser?.isPlatformAdmin ?? false);

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_outlined,
              size: 64, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            'No projects found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPlatformAdmin
                ? 'Try adjusting your filters or create a new project'
                : "You're not a member of any project",
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.25),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Toolbar ────────────────────────────────────────────────────

class _Toolbar extends StatelessWidget {
  const _Toolbar({
    required this.searchController,
    required this.onSearchChanged,
    required this.archivedFilter,
    required this.onArchivedFilterChanged,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final bool? archivedFilter;
  final ValueChanged<bool?> onArchivedFilterChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: _SearchField(
            controller: searchController,
            onChanged: onSearchChanged,
          ),
        ),
        _FilterPill(
          label: 'All',
          active: archivedFilter == null,
          onTap: () => onArchivedFilterChanged(null),
        ),
        _FilterPill(
          label: 'Archived',
          active: archivedFilter == true,
          onTap: () =>
              onArchivedFilterChanged(archivedFilter == true ? null : true),
        ),
      ],
    );
  }
}

// ── Search field ───────────────────────────────────────────────

class _SearchField extends StatelessWidget {
  const _SearchField({required this.controller, required this.onChanged});

  final TextEditingController controller;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 480,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF1E2040),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded,
              size: 18, color: Colors.white.withOpacity(0.35)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14, color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search projects by name or slug…',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.35),
                ),
                isCollapsed: true,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (controller.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                controller.clear();
                onChanged('');
              },
              child: Icon(Icons.close_rounded,
                  size: 16, color: Colors.white.withOpacity(0.35)),
            ),
        ],
      ),
    );
  }
}

// ── Filter pill ────────────────────────────────────────────────

class _FilterPill extends StatelessWidget {
  const _FilterPill({
    required this.label,
    required this.active,
    required this.onTap,
  });

  final String label;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? AppColors.teal.withOpacity(0.15)
              : const Color(0xFF1E2040),
          border: Border.all(
            color: active
                ? AppColors.teal.withOpacity(0.4)
                : Colors.white.withOpacity(0.12),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? AppColors.teal : Colors.white.withOpacity(0.7),
          ),
        ),
      ),
    );
  }
}

// ── Pagination ─────────────────────────────────────────────────

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.totalPages,
    required this.totalElements,
    required this.pageSize,
  });

  final int page;
  final int totalPages;
  final int totalElements;
  final int pageSize;

  @override
  Widget build(BuildContext context) {
    final int from = totalElements == 0 ? 0 : page * pageSize + 1;
    final int to = totalElements == 0
        ? 0
        : (page * pageSize + pageSize).clamp(0, totalElements);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Showing $from–$to of $totalElements',
          style: TextStyle(
            fontSize: 13,
            color: Colors.white.withOpacity(0.5),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _PaginationArrow(
              icon: Icons.chevron_left_rounded,
              enabled: page > 0,
              onTap: () => _goToPage(context, page - 1),
            ),
            const SizedBox(width: 8),
            ...List.generate(totalPages, (int i) {
              final bool isActive = i == page;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: GestureDetector(
                  onTap: () => _goToPage(context, i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 36,
                    height: 36,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: isActive
                          ? AppColors.coral.withOpacity(0.25)
                          : Colors.white.withOpacity(0.06),
                      border: Border.all(
                        color: isActive
                            ? AppColors.coral.withOpacity(0.4)
                            : Colors.white.withOpacity(0.08),
                      ),
                    ),
                    child: Text(
                      '${i + 1}',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight:
                            isActive ? FontWeight.w600 : FontWeight.w400,
                        color: isActive
                            ? AppColors.coral
                            : Colors.white.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              );
            }),
            const SizedBox(width: 8),
            _PaginationArrow(
              icon: Icons.chevron_right_rounded,
              enabled: page < totalPages - 1,
              onTap: () => _goToPage(context, page + 1),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _goToPage(BuildContext context, int targetPage) async {
    final String? token =
        await context.read<AuthCubit>().getValidAccessToken();
    if (token == null || !context.mounted) return;
    await context.read<ProjectsCubit>().goToPage(
          accessToken: token,
          page: targetPage,
        );
  }
}

class _PaginationArrow extends StatelessWidget {
  const _PaginationArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(
          icon,
          size: 18,
          color: enabled
              ? Colors.white.withOpacity(0.7)
              : Colors.white.withOpacity(0.2),
        ),
      ),
    );
  }
}

// ── Create button ──────────────────────────────────────────────

class _CreateButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _CreateButton({required this.onPressed});

  @override
  State<_CreateButton> createState() => _CreateButtonState();
}

class _CreateButtonState extends State<_CreateButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 11),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            gradient: const LinearGradient(
                colors: [AppColors.coral, Color(0xFFE8585A)]),
            boxShadow: [
              BoxShadow(
                color: AppColors.coral.withOpacity(_hovering ? 0.4 : 0.2),
                blurRadius: _hovering ? 16 : 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 18, color: Colors.white),
              SizedBox(width: 6),
              Text('New project',
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Confirm dialog ─────────────────────────────────────────────

class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        width: 360,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: const Color(0xFF1E2040),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.coral, size: 40),
            const SizedBox(height: 16),
            Text(title,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.white.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: Colors.white.withOpacity(0.12)),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: Text(confirmLabel),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

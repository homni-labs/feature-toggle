import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:togli_app/app/di/injection.dart';
import 'package:togli_app/app/theme/app_colors.dart';
import 'package:togli_app/core/domain/failure.dart';
import 'package:togli_app/core/domain/value_objects/project_role.dart';
import 'package:togli_app/core/presentation/widgets/app_snackbar.dart';
import 'package:togli_app/core/presentation/widgets/comic_button.dart';
import 'package:go_router/go_router.dart';
import 'package:togli_app/app/router/app_router.dart';
import 'package:togli_app/features/auth/application/bloc/auth_cubit.dart';
import 'package:togli_app/features/auth/application/bloc/auth_state.dart';
import 'package:togli_app/features/projects/application/bloc/projects_cubit.dart';
import 'package:togli_app/features/projects/application/bloc/projects_state.dart';
import 'package:togli_app/features/projects/domain/model/project.dart';
import 'package:togli_app/features/projects/presentation/widget/project_card.dart';
import 'package:togli_app/features/projects/presentation/widget/project_dialog.dart'
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
      buildWhen: (previous, current) =>
          current is! ProjectsError || previous is! ProjectsLoaded,
      builder: (BuildContext context, ProjectsState state) {
        final ProjectsLoaded? loaded =
            state is ProjectsLoaded ? state : null;

        return Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row: title + search + filters + create ─────
              Wrap(
                spacing: 16,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    'Projects',
                    style: GoogleFonts.fredoka(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 400),
                    child: _SearchField(
                      controller: _searchController,
                      onChanged: _onSearchChanged,
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _FilterPill(
                        label: 'All',
                        active: loaded?.archivedFilter == null,
                        onTap: () => _onArchivedFilterChanged(null),
                      ),
                      const SizedBox(width: 6),
                      _FilterPill(
                        label: 'Archived',
                        active: loaded?.archivedFilter == true,
                        onTap: () => _onArchivedFilterChanged(
                            loaded?.archivedFilter == true ? null : true),
                      ),
                    ],
                  ),
                  if (isPlatformAdmin)
                    _CreateButton(onPressed: () => _onCreate(context)),
                ],
              ).animate().fadeIn(duration: 400.ms),
              const SizedBox(height: 20),

              // ── Body ──────────────────────────────────────────────
              Expanded(child: _Body(state: state)),
            ],
          ),
        );
      },
    );
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
            : _ProjectsGrid(state: state as ProjectsLoaded),
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
              size: 48, color: AppColors.navy.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            failure.message,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.navy.withOpacity(0.5),
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
  const _ProjectsGrid({required this.state});

  final ProjectsLoaded state;

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthCubit>().state;
    final bool isPlatformAdmin = authState is AuthAuthenticated &&
        (authState.currentUser?.isPlatformAdmin ?? false);

    return LayoutBuilder(
      builder: (context, constraints) {
        final int columns = constraints.maxWidth >= 800 ? 2 : 1;
        final double gap = 16;
        final double cardWidth = columns == 1
            ? constraints.maxWidth.clamp(0, 1100)
            : ((constraints.maxWidth.clamp(0, 1100) - gap) / 2);

        final List<Project> projects = state.projects;
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 1100),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  Wrap(
                    spacing: gap,
                    runSpacing: gap,
                    children: [
                      for (final project in projects)
                        SizedBox(
                          width: cardWidth,
                          child: Builder(builder: (context) {
                            final bool userIsAdmin =
                                project.myRole == ProjectRole.admin;
                            final bool canEdit =
                                isPlatformAdmin || userIsAdmin;
                            final bool canArchive = isPlatformAdmin;
                            final bool canUnarchive =
                                isPlatformAdmin || userIsAdmin;

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
                          }),
                        ),
                    ],
                  ),
                  if (state.totalPages > 1) ...[
                    const SizedBox(height: 20),
                    _Pagination(
                      page: state.page,
                      totalPages: state.totalPages,
                      totalElements: state.totalElements,
                      pageSize: projects.length,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _onTap(BuildContext context, Project project) {
    context.read<AuthCubit>().selectProject(project, project.myRole);
    context.go(AppRoutes.projectToggles(project.slug.value));
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
              size: 64, color: AppColors.navy.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            'No projects found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.navy.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPlatformAdmin
                ? 'Try adjusting your filters or create a new project'
                : "You're not a member of any project",
            style: TextStyle(
              fontSize: 14,
              color: AppColors.navy.withOpacity(0.25),
            ),
          ),
        ],
      ),
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
        color: const Color(0xFFFFFFFF),
        border: Border.all(color: AppColors.navy.withOpacity(0.12)),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded,
              size: 18, color: AppColors.navy.withOpacity(0.35)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              onChanged: onChanged,
              style: const TextStyle(fontSize: 14, color: AppColors.navy),
              decoration: InputDecoration(
                hintText: 'Search projects by name or slug…',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors.navy.withOpacity(0.35),
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
                  size: 16, color: AppColors.navy.withOpacity(0.35)),
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
              : const Color(0xFFFFFFFF),
          border: Border.all(
            color: active
                ? AppColors.teal.withOpacity(0.4)
                : AppColors.navy.withOpacity(0.12),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: active ? AppColors.teal : AppColors.navy.withOpacity(0.7),
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PagerButton(
          text: '\u00AB',
          enabled: page > 0,
          active: false,
          onTap: () => _goToPage(context, page - 1),
        ),
        ...List.generate(totalPages, (int i) {
          return _PagerButton(
            text: '${i + 1}',
            enabled: true,
            active: i == page,
            onTap: () => _goToPage(context, i),
          );
        }),
        _PagerButton(
          text: '\u00BB',
          enabled: page < totalPages - 1,
          active: false,
          onTap: () => _goToPage(context, page + 1),
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

class _PagerButton extends StatelessWidget {
  const _PagerButton({
    required this.text,
    required this.enabled,
    required this.active,
    required this.onTap,
  });

  final String text;
  final bool enabled;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: active
                ? AppColors.coral.withOpacity(0.1)
                : Colors.white,
            border: Border.all(
              width: 2,
              color: active
                  ? AppColors.coral
                  : const Color(0xFFDDD8CC),
            ),
          ),
          child: Text(
            text,
            style: GoogleFonts.fredoka(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: !enabled
                  ? AppColors.navy.withOpacity(0.2)
                  : active
                      ? AppColors.coral
                      : AppColors.navy.withOpacity(0.5),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Create button ──────────────────────────────────────────────

class _CreateButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CreateButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ComicButton(
      label: 'New Project',
      icon: Icons.add_rounded,
      onPressed: onPressed,
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
          color: const Color(0xFFFFFFFF),
          border: Border.all(color: AppColors.navy.withOpacity(0.12)),
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
                    color: AppColors.navy)),
            const SizedBox(height: 8),
            Text(message,
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14, color: AppColors.navy.withOpacity(0.5))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.navy.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color: AppColors.navy.withOpacity(0.12)),
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

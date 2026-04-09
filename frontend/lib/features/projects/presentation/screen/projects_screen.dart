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

class _ProjectsView extends StatelessWidget {
  const _ProjectsView();

  @override
  Widget build(BuildContext context) {
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
        return switch (state) {
          ProjectsInitial() ||
          ProjectsLoading() =>
            const Center(
              child: CircularProgressIndicator(color: AppColors.coral),
            ),
          ProjectsError(:final Failure failure) =>
            _ErrorBody(failure: failure),
          ProjectsLoaded(:final List<Project> projects) =>
            _LoadedBody(projects: projects),
        };
      },
    );
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

// ── Loaded body ────────────────────────────────────────────────

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.projects});
  final List<Project> projects;

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthCubit>().state;
    final bool isPlatformAdmin = authState is AuthAuthenticated &&
        (authState.currentUser?.isPlatformAdmin ?? false);

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Text(
                'Projects',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const Spacer(),
              if (isPlatformAdmin)
                _CreateButton(
                  label: 'New Project',
                  onPressed: () => _onCreate(context),
                ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 16),

          // Count
          Text(
            '${projects.length} project(s)',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 16),

          // List
          Expanded(
            child: projects.isEmpty
                ? _EmptyState(isPlatformAdmin: isPlatformAdmin)
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: ListView.builder(
                        itemCount: projects.length,
                        itemBuilder: (BuildContext context, int index) {
                          final Project project = projects[index];
                          final bool canManage = isPlatformAdmin ||
                              project.myRole == ProjectRole.admin;
                          return ProjectCard(
                            key: ValueKey(project.id),
                            project: project,
                            onTap: () => _onTap(context, project),
                            onArchive: canManage && !project.archived
                                ? () => _onArchive(context, project)
                                : null,
                            onUnarchive: canManage && project.archived
                                ? () => _onUnarchive(context, project)
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  void _onTap(BuildContext context, Project project) {
    context.read<AuthCubit>().selectProject(project, project.myRole);
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
  const _EmptyState({required this.isPlatformAdmin});
  final bool isPlatformAdmin;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.folder_outlined,
              size: 64, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            'No projects yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isPlatformAdmin
                ? 'Create your first project'
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

// ── Create button ──────────────────────────────────────────────

class _CreateButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  const _CreateButton({required this.label, required this.onPressed});

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
          padding:
              const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.add_rounded, size: 18, color: Colors.white),
              const SizedBox(width: 6),
              Text(widget.label,
                  style: const TextStyle(
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
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 44,
                    child: TextButton(
                      onPressed: () =>
                          Navigator.of(context).pop(false),
                      style: TextButton.styleFrom(
                        foregroundColor:
                            Colors.white.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color:
                                  Colors.white.withOpacity(0.12)),
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
                      onPressed: () =>
                          Navigator.of(context).pop(true),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(12)),
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

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feature_toggle_app/app/di/injection.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';
import 'package:feature_toggle_app/core/domain/failure.dart';
import 'package:feature_toggle_app/core/presentation/widgets/app_snackbar.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_cubit.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_state.dart';
import 'package:feature_toggle_app/features/projects/application/bloc/project_settings_cubit.dart';
import 'package:feature_toggle_app/features/projects/application/bloc/project_settings_state.dart';
import 'package:feature_toggle_app/features/projects/domain/model/project.dart';

class ProjectSettingsPage extends StatelessWidget {
  const ProjectSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<ProjectSettingsCubit>(
      create: (_) => sl<ProjectSettingsCubit>(),
      child: const _ProjectSettingsView(),
    );
  }
}

// ── Main view (StatefulWidget for TextEditingControllers) ──────

class _ProjectSettingsView extends StatefulWidget {
  const _ProjectSettingsView();

  @override
  State<_ProjectSettingsView> createState() => _ProjectSettingsViewState();
}

class _ProjectSettingsViewState extends State<_ProjectSettingsView> {
  late final TextEditingController _nameController;
  late final TextEditingController _descController;

  @override
  void initState() {
    super.initState();
    final AuthState authState = context.read<AuthCubit>().state;
    final Project? project = authState is AuthAuthenticated
        ? authState.currentProject
        : null;

    _nameController = TextEditingController(text: project?.name ?? '');
    _descController =
        TextEditingController(text: project?.description ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descController.dispose();
    super.dispose();
  }

  // ── Operations ─────────────────────────────────────────────────

  Future<void> _onSave() async {
    final String name = _nameController.text.trim();
    if (name.isEmpty) {
      showAppSnackBar(
        context,
        const ValidationFailure('Project name cannot be empty'),
        isWarning: true,
      );
      return;
    }

    final AuthCubit authCubit = context.read<AuthCubit>();
    final AuthState authState = authCubit.state;
    if (authState is! AuthAuthenticated) return;

    final Project? current = authState.currentProject;
    if (current == null) return;

    final String descText = _descController.text.trim();
    final String? description = descText.isEmpty ? null : descText;

    final String? token = await authCubit.getValidAccessToken();
    if (token == null || !mounted) return;

    await context.read<ProjectSettingsCubit>().save(
          accessToken: token,
          projectId: current.id,
          name: name,
          description: description,
        );
  }

  Future<void> _onArchiveToggle() async {
    final AuthCubit authCubit = context.read<AuthCubit>();
    final AuthState authState = authCubit.state;
    if (authState is! AuthAuthenticated) return;

    final Project? current = authState.currentProject;
    if (current == null) return;

    final bool newArchived = !current.archived;

    final String message = newArchived
        ? 'Are you sure you want to archive "${current.name}"? '
            'All feature toggles in this project will be disabled and the '
            'project will become read-only.'
        : 'Are you sure you want to unarchive "${current.name}"?';

    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: '${newArchived ? 'Archive' : 'Unarchive'} Project',
        message: message,
        confirmLabel: newArchived ? 'Archive' : 'Unarchive',
      ),
    );
    if (confirmed != true || !mounted) return;

    final String? token = await authCubit.getValidAccessToken();
    if (token == null || !mounted) return;

    await context.read<ProjectSettingsCubit>().toggleArchive(
          accessToken: token,
          projectId: current.id,
          archived: newArchived,
        );
  }

  // ── Build ──────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProjectSettingsCubit, ProjectSettingsState>(
      listener: (BuildContext context, ProjectSettingsState state) {
        if (state is ProjectSettingsSaved) {
          final AuthCubit authCubit = context.read<AuthCubit>();
          final AuthState authState = authCubit.state;
          if (authState is AuthAuthenticated) {
            authCubit.selectProject(
              state.project,
              authState.currentProjectRole,
            );
          }
        } else if (state is ProjectSettingsError) {
          showAppSnackBar(
            context,
            state.failure,
            isWarning: state.failure is ConflictFailure ||
                state.failure is NotFoundFailure,
          );
        }
      },
      child: _buildContent(context),
    );
  }

  Widget _buildContent(BuildContext context) {
    final AuthState authState = context.watch<AuthCubit>().state;
    final bool isPlatformAdmin = authState is AuthAuthenticated &&
        (authState.currentUser?.isPlatformAdmin ?? false);
    final bool canManageProject = authState is AuthAuthenticated &&
        authState.canManageMembers;
    final bool isArchived =
        authState is AuthAuthenticated && authState.isProjectArchived;
    final Project? project = authState is AuthAuthenticated
        ? authState.currentProject
        : null;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Settings',
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: Colors.white.withOpacity(0.9),
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 500),
                child: ListView(
                  children: [
                    if (isArchived)
                      _ArchivedProjectPanel(
                        project: project,
                        canUnarchive: canManageProject,
                        onUnarchive: _onArchiveToggle,
                      )
                    else ...[
                      // ── Project Details ─────────────────────────
                      Text(
                        'Project Details',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Name field
                      _SettingsField(
                        controller: _nameController,
                        hint: 'Project name',
                        icon: Icons.folder_outlined,
                      ),
                      const SizedBox(height: 14),

                      // Description field
                      _SettingsField(
                        controller: _descController,
                        hint: 'Description (optional)',
                        icon: Icons.notes_rounded,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 20),

                      // Save button
                      SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed: _onSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.coral,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Save',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),

                      // ── Danger Zone ─────────────────────────────
                      if (isPlatformAdmin) ...[
                        const SizedBox(height: 32),
                        Divider(color: Colors.white.withOpacity(0.1)),
                        const SizedBox(height: 24),
                        const Text(
                          'Danger Zone',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.coral,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 48,
                          child: OutlinedButton(
                            onPressed: _onArchiveToggle,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.coral,
                              side:
                                  const BorderSide(color: AppColors.coral),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Archive Project',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Archived project panel ─────────────────────────────────────

class _ArchivedProjectPanel extends StatelessWidget {
  const _ArchivedProjectPanel({
    required this.project,
    required this.canUnarchive,
    required this.onUnarchive,
  });

  final Project? project;
  final bool canUnarchive;
  final Future<void> Function() onUnarchive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white.withOpacity(0.04),
        border: Border.all(color: Colors.white.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.archive_rounded,
                  size: 22, color: Colors.white.withOpacity(0.6)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  project?.name ?? 'Project',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(6),
                  color: Colors.white.withOpacity(0.08),
                ),
                child: Text(
                  'Archived',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'This project is archived. All feature toggles inside it are '
            'disabled and cannot be edited. You can unarchive the project to '
            'restore access.',
            style: TextStyle(
              fontSize: 13,
              height: 1.4,
              color: Colors.white.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          if (canUnarchive)
            SizedBox(
              height: 48,
              child: ElevatedButton.icon(
                onPressed: onUnarchive,
                icon: const Icon(Icons.unarchive_outlined, size: 18),
                label: const Text(
                  'Unarchive Project',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.coral,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            )
          else
            Text(
              'You do not have permission to unarchive this project.',
              style: TextStyle(
                fontSize: 12,
                color: Colors.white.withOpacity(0.4),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Settings field ─────────────────────────────────────────────

class _SettingsField extends StatelessWidget {
  const _SettingsField({
    required this.controller,
    required this.hint,
    required this.icon,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: Colors.white.withOpacity(0.07),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        cursorColor: AppColors.coral,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
          prefixIcon:
              Icon(icon, size: 20, color: Colors.white.withOpacity(0.4)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

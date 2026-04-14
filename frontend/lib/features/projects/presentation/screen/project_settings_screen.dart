import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:togli_app/app/di/injection.dart';
import 'package:togli_app/app/theme/app_colors.dart';
import 'package:togli_app/core/domain/failure.dart';
import 'package:togli_app/core/presentation/widgets/app_snackbar.dart';
import 'package:togli_app/core/presentation/widgets/comic_button.dart';
import 'package:togli_app/features/auth/application/bloc/auth_cubit.dart';
import 'package:togli_app/features/auth/application/bloc/auth_state.dart';
import 'package:togli_app/features/projects/application/bloc/project_settings_cubit.dart';
import 'package:togli_app/features/projects/application/bloc/project_settings_state.dart';
import 'package:togli_app/features/projects/domain/model/project.dart';

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
            style: GoogleFonts.fredoka(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 12),
          Expanded(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 520),
                child: ListView(
                  children: [
                    if (isArchived)
                      _ArchivedProjectPanel(
                        project: project,
                        canUnarchive: canManageProject,
                        onUnarchive: _onArchiveToggle,
                      )
                    else ...[
                      // ── Project Details card ────────────────────
                      _SettingsCard(
                        icon: '\u{1F4C4}',
                        title: 'Project Details',
                        children: [
                          _LabeledField(
                            label: 'Project Name',
                            controller: _nameController,
                          ),
                          const SizedBox(height: 14),
                          _LabeledField(
                            label: 'Description',
                            controller: _descController,
                            maxLines: 3,
                          ),
                          const SizedBox(height: 20),
                          ComicButton(
                            label: 'Save Changes',
                            onPressed: _onSave,
                            expand: true,
                          ),
                        ],
                      ),

                      // ── Danger Zone ─────────────────────────────
                      if (isPlatformAdmin) ...[
                        const SizedBox(height: 20),
                        _DangerCard(
                          onArchive: _onArchiveToggle,
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

// ── Archived project banner ───────────────────────────────────

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
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: Colors.white,
        border: Border.all(color: AppColors.navy, width: 3),
        boxShadow: const [
          BoxShadow(color: AppColors.navy, offset: Offset(0, 4)),
        ],
      ),
      child: Column(
        children: [
          const Text('\u{1F4E6}', style: TextStyle(fontSize: 40)),
          const SizedBox(height: 8),
          Text(
            project?.name ?? 'Project',
            style: GoogleFonts.fredoka(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(5),
              color: AppColors.coral.withOpacity(0.1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.coral,
                  ),
                ),
                const SizedBox(width: 4),
                const Text(
                  'Archived',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppColors.coral,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'This project is archived. All toggles are disabled and no '
            'modifications are allowed. Unarchive to restore full functionality.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.navy.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 20),
          if (canUnarchive)
            ComicButton(
              label: '\u21B4 Unarchive Project',
              onPressed: onUnarchive,
              color: AppColors.green,
              expand: true,
            )
          else
            Text(
              'You do not have permission to unarchive this project.',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.navy.withOpacity(0.4),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Settings card ─────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  const _SettingsCard({
    required this.icon,
    required this.title,
    required this.children,
  });

  final String icon;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: AppColors.navy, width: 3),
        boxShadow: const [
          BoxShadow(color: Color(0xFFDDD8CC), offset: Offset(0, 3)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(icon, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                title,
                style: GoogleFonts.fredoka(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ...children,
        ],
      ),
    );
  }
}

// ── Danger card ───────────────────────────────────────────────

class _DangerCard extends StatelessWidget {
  const _DangerCard({required this.onArchive});

  final Future<void> Function() onArchive;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        border: Border.all(color: AppColors.coral, width: 3),
        boxShadow: [
          BoxShadow(
            color: AppColors.coral.withOpacity(0.3),
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u26A0 Danger Zone',
            style: GoogleFonts.fredoka(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.coral,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Archiving this project will disable all feature toggles and '
            'prevent any modifications. Members retain read-only access. '
            'This can be reversed.',
            style: TextStyle(
              fontSize: 13,
              height: 1.5,
              color: AppColors.navy.withOpacity(0.55),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: _ArchiveButton(onTap: onArchive),
          ),
        ],
      ),
    );
  }
}

class _ArchiveButton extends StatefulWidget {
  final VoidCallback onTap;
  const _ArchiveButton({required this.onTap});

  @override
  State<_ArchiveButton> createState() => _ArchiveButtonState();
}

class _ArchiveButtonState extends State<_ArchiveButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 100),
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: Colors.white,
            border: Border.all(color: AppColors.coral, width: 3),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFDDD8CC),
                offset: Offset(0, _hovering ? 4 : 3),
              ),
            ],
          ),
          transform: _hovering
              ? Matrix4.translationValues(0, -1, 0)
              : Matrix4.identity(),
          child: Text(
            'Archive Project',
            style: GoogleFonts.fredoka(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.coral,
            ),
          ),
        ),
      ),
    );
  }
}

// ── Labeled field ─────────────────────────────────────────────

class _LabeledField extends StatelessWidget {
  const _LabeledField({
    required this.label,
    required this.controller,
    this.maxLines = 1,
  });

  final String label;
  final TextEditingController controller;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.navy.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFDDD8CC), width: 3),
            color: Colors.white,
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            style: const TextStyle(color: AppColors.navy, fontSize: 14),
            cursorColor: AppColors.coral,
            decoration: const InputDecoration(
              border: InputBorder.none,
              contentPadding:
                  EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ),
      ],
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
                    fontSize: 14,
                    color: AppColors.navy.withOpacity(0.5))),
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
                            AppColors.navy.withOpacity(0.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(
                              color:
                                  AppColors.navy.withOpacity(0.12)),
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

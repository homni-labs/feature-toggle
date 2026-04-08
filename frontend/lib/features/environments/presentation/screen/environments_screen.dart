import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feature_toggle_app/app/di/injection.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';
import 'package:feature_toggle_app/core/presentation/widgets/app_snackbar.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_cubit.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_state.dart';
import 'package:feature_toggle_app/features/environments/application/bloc/environments_cubit.dart';
import 'package:feature_toggle_app/features/environments/application/bloc/environments_state.dart';
import 'package:feature_toggle_app/features/environments/domain/model/environment.dart';
import 'package:feature_toggle_app/features/environments/presentation/widget/environment_card.dart';
import 'package:feature_toggle_app/features/environments/presentation/widget/environment_dialog.dart'
    show EnvironmentDialog, EnvironmentDialogResult;

class EnvironmentsPage extends StatelessWidget {
  const EnvironmentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<EnvironmentsCubit>();
        _load(context.read<AuthCubit>(), cubit);
        return cubit;
      },
      child: const _EnvironmentsView(),
    );
  }

  static Future<void> _load(AuthCubit auth, EnvironmentsCubit cubit) async {
    final token = await auth.getValidAccessToken();
    if (token == null) return;
    final authState = auth.state as AuthAuthenticated;
    await cubit.load(
      accessToken: token,
      projectId: authState.currentProject!.id,
    );
  }
}

class _EnvironmentsView extends StatelessWidget {
  const _EnvironmentsView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<EnvironmentsCubit, EnvironmentsState>(
      listener: (context, state) {
        if (state is EnvironmentsError) {
          showAppSnackBar(context, state.failure);
        }
      },
      builder: (context, state) => switch (state) {
        EnvironmentsInitial() || EnvironmentsLoading() => _buildLoading(),
        EnvironmentsError(:final failure) => _buildError(context, failure.message),
        EnvironmentsLoaded(:final environments) =>
          _buildLoaded(context, environments),
      },
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.coral),
    );
  }

  Widget _buildError(BuildContext context, String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 48, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(message,
              style: TextStyle(
                  fontSize: 16, color: Colors.white.withOpacity(0.5))),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _reload(context),
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

  Widget _buildLoaded(BuildContext context, List<Environment> environments) {
    final authState =
        context.read<AuthCubit>().state as AuthAuthenticated;
    final canWrite =
        authState.canWriteToggles && !authState.isProjectArchived;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Text(
                'Environments',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const Spacer(),
              if (canWrite)
                _CreateButton(onPressed: () => _onCreate(context)),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 16),

          // Count
          Text(
            '${environments.length} environment(s)',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 16),

          // List
          Expanded(
            child: environments.isEmpty
                ? _buildEmptyState()
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: ListView.builder(
                        itemCount: environments.length,
                        itemBuilder: (context, index) {
                          final env = environments[index];
                          return EnvironmentCard(
                            key: ValueKey(env.id.value),
                            environment: env,
                            onDelete: canWrite
                                ? () => _onDelete(context, env)
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

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_queue_rounded,
              size: 64, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text('No environments yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.4))),
          const SizedBox(height: 8),
          Text('Create your first deployment environment',
              style: TextStyle(
                  fontSize: 14, color: Colors.white.withOpacity(0.25))),
        ],
      ),
    );
  }

  // ── Operations ───────────────────────────────────────────────────

  Future<void> _reload(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    final cubit = context.read<EnvironmentsCubit>();
    await EnvironmentsPage._load(authCubit, cubit);
  }

  Future<void> _onCreate(BuildContext context) async {
    final result = await showDialog<EnvironmentDialogResult>(
      context: context,
      builder: (_) => const EnvironmentDialog(),
    );
    if (result == null) return;
    if (!context.mounted) return;

    final token = await context.read<AuthCubit>().getValidAccessToken();
    if (token == null) return;
    if (!context.mounted) return;

    final authState =
        context.read<AuthCubit>().state as AuthAuthenticated;
    await context.read<EnvironmentsCubit>().create(
          accessToken: token,
          projectId: authState.currentProject!.id,
          name: result.name,
        );
  }

  Future<void> _onDelete(BuildContext context, Environment env) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(name: env.name),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final token = await context.read<AuthCubit>().getValidAccessToken();
    if (token == null) return;
    if (!context.mounted) return;

    final authState =
        context.read<AuthCubit>().state as AuthAuthenticated;
    await context.read<EnvironmentsCubit>().delete(
          accessToken: token,
          projectId: authState.currentProject!.id,
          environmentId: env.id,
        );
  }
}

// ── Create button ───────────────────────────────────────────────

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
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.add_rounded, size: 18, color: Colors.white),
              SizedBox(width: 6),
              Text('New Environment',
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

// ── Delete confirmation dialog ──────────────────────────────────

class _DeleteConfirmDialog extends StatelessWidget {
  final String name;
  const _DeleteConfirmDialog({required this.name});

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
            const Text('Delete Environment',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text('Are you sure you want to delete "$name"?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.5))),
            const SizedBox(height: 4),
            Text(
                'This will fail if any toggles use this environment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.3))),
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
                      child: const Text('Delete'),
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

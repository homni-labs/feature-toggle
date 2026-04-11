import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:feature_toggle_app/app/di/injection.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';
import 'package:feature_toggle_app/core/domain/failure.dart';
import 'package:feature_toggle_app/core/presentation/widgets/app_snackbar.dart';
import 'package:feature_toggle_app/core/presentation/widgets/comic_button.dart';
import 'package:feature_toggle_app/core/presentation/widgets/forbidden_page.dart';
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
      buildWhen: (previous, current) =>
          current is! EnvironmentsError || previous is! EnvironmentsLoaded,
      builder: (context, state) => switch (state) {
        EnvironmentsInitial() || EnvironmentsLoading() => _buildLoading(),
        EnvironmentsError(:final failure) => _buildError(context, failure),
        EnvironmentsLoaded() => _buildLoaded(context, state),
      },
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(color: AppColors.coral),
    );
  }

  Widget _buildError(BuildContext context, Failure failure) {
    if (failure is ForbiddenFailure) return const ForbiddenPage();
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 48, color: AppColors.navy.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(failure.message,
              style: TextStyle(
                  fontSize: 16, color: AppColors.navy.withOpacity(0.5))),
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

  Widget _buildLoaded(BuildContext context, EnvironmentsLoaded state) {
    final authState =
        context.read<AuthCubit>().state as AuthAuthenticated;
    final canWrite =
        authState.canWriteToggles && !authState.isProjectArchived;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Environments',
                style: GoogleFonts.fredoka(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const Spacer(),
              if (canWrite)
                _CreateButton(onPressed: () => _onCreate(context)),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 2),
          Text(
            '${state.totalElements} environments',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.navy.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 16),

          Expanded(
            child: state.environments.isEmpty
                ? _buildEmptyState()
                : LayoutBuilder(
                    builder: (context, constraints) {
                      const double minCard = 260;
                      const double gap = 14;
                      final int cols = (constraints.maxWidth / (minCard + gap))
                          .floor()
                          .clamp(1, 3);
                      final double cardWidth = cols == 1
                          ? constraints.maxWidth
                          : (constraints.maxWidth - gap * (cols - 1)) / cols;

                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            Wrap(
                              spacing: gap,
                              runSpacing: gap,
                              children: state.environments.map((env) {
                                return SizedBox(
                                  width: cardWidth,
                                  child: EnvironmentCard(
                                    key: ValueKey(env.id.value),
                                    environment: env,
                                    onDelete: canWrite
                                        ? () => _onDelete(context, env)
                                        : null,
                                  ),
                                );
                              }).toList(),
                            ),
                            if (state.totalPages > 1) ...[
                              const SizedBox(height: 20),
                              _buildPagination(context, state),
                            ],
                          ],
                        ),
                      );
                    },
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
              size: 64, color: AppColors.navy.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text('No environments yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.navy.withOpacity(0.4))),
          const SizedBox(height: 8),
          Text('Create your first deployment environment',
              style: TextStyle(
                  fontSize: 14, color: AppColors.navy.withOpacity(0.25))),
        ],
      ),
    );
  }

  Widget _buildPagination(BuildContext context, EnvironmentsLoaded state) {
    Widget pagerBtn(String text, bool enabled, bool active, VoidCallback onTap) {
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
              color: active ? AppColors.coral.withOpacity(0.1) : Colors.white,
              border: Border.all(
                width: 2,
                color: active ? AppColors.coral : const Color(0xFFDDD8CC),
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

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        pagerBtn('\u00AB', state.page > 0, false,
            () => _goToPage(context, state.page - 1)),
        ...List.generate(state.totalPages, (i) =>
            pagerBtn('${i + 1}', true, i == state.page,
                () => _goToPage(context, i))),
        pagerBtn('\u00BB', state.page < state.totalPages - 1, false,
            () => _goToPage(context, state.page + 1)),
      ],
    );
  }

  Future<void> _goToPage(BuildContext context, int page) async {
    final authCubit = context.read<AuthCubit>();
    final authState = authCubit.state;
    if (authState is! AuthAuthenticated) return;
    final projectId = authState.currentProject?.id;
    if (projectId == null) return;
    final token = await authCubit.getValidAccessToken();
    if (token == null || !context.mounted) return;
    await context.read<EnvironmentsCubit>().load(
          accessToken: token,
          projectId: projectId,
          page: page,
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

// ── Pagination (mockup cartoon style) ─────────────────────────

// ── Create button (cartoon style) ─────────────────────────────

class _CreateButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CreateButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ComicButton(
      label: 'New Environment',
      icon: Icons.add_rounded,
      onPressed: onPressed,
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
          color: Colors.white,
          border: Border.all(color: AppColors.navy, width: 3),
          boxShadow: const [
            BoxShadow(color: AppColors.navy, offset: Offset(0, 3)),
          ],
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
                    color: AppColors.navy)),
            const SizedBox(height: 8),
            Text('Are you sure you want to delete "$name"?',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 14,
                    color: AppColors.navy.withOpacity(0.5))),
            const SizedBox(height: 4),
            Text(
                'This will fail if any toggles use this environment.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    color: AppColors.navy.withOpacity(0.3))),
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

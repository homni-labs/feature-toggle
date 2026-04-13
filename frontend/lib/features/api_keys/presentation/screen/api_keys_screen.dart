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
import 'package:feature_toggle_app/features/api_keys/application/bloc/api_keys_cubit.dart';
import 'package:feature_toggle_app/features/api_keys/application/bloc/api_keys_state.dart';
import 'package:feature_toggle_app/features/api_keys/domain/model/api_key.dart';
import 'package:feature_toggle_app/features/api_keys/presentation/widget/api_key_card.dart';
import 'package:feature_toggle_app/features/api_keys/presentation/widget/api_key_dialog.dart'
    show ApiKeyDialog, ApiKeyDialogResult;
import 'package:feature_toggle_app/features/api_keys/presentation/widget/raw_token_dialog.dart'
    show RawTokenDialog;

class ApiKeysPage extends StatelessWidget {
  const ApiKeysPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<ApiKeysCubit>();
        _load(context.read<AuthCubit>(), cubit);
        return cubit;
      },
      child: const _ApiKeysView(),
    );
  }

  static Future<void> _load(
    AuthCubit auth,
    ApiKeysCubit cubit, {
    int page = 0,
  }) async {
    final token = await auth.getValidAccessToken();
    if (token == null) return;
    final authState = auth.state as AuthAuthenticated;
    await cubit.load(
      accessToken: token,
      projectId: authState.currentProject!.id,
      page: page,
    );
  }
}

class _ApiKeysView extends StatelessWidget {
  const _ApiKeysView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ApiKeysCubit, ApiKeysState>(
      listener: (context, state) {
        if (state is ApiKeysError) {
          showAppSnackBar(context, state.failure);
        }
        if (state is ApiKeyIssued) {
          _handleIssued(context, state.created);
        }
      },
      buildWhen: (previous, current) =>
          current is! ApiKeyIssued &&
          (current is! ApiKeysError || previous is! ApiKeysLoaded),
      builder: (context, state) => switch (state) {
        ApiKeysInitial() || ApiKeysLoading() => _buildLoading(),
        ApiKeysError(:final failure) =>
          _buildError(context, failure),
        ApiKeysLoaded() => _buildLoaded(context, state as ApiKeysLoaded),
        ApiKeyIssued() => _buildLoading(),
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

  Widget _buildLoaded(BuildContext context, ApiKeysLoaded state) {
    final authState =
        context.read<AuthCubit>().state as AuthAuthenticated;
    final canManage =
        authState.canManageMembers && !authState.isProjectArchived;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Text(
                'API Keys',
                style: GoogleFonts.fredoka(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
                ),
              ),
              const Spacer(),
              if (canManage)
                _CreateButton(
                  label: 'New API Key',
                  onPressed: () => _onCreate(context),
                ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          Text(
            '${state.totalElements} API keys \u00B7 All keys grant read-only access',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.navy.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 20),

          // Grid
          Expanded(
            child: state.apiKeys.isEmpty
                ? _buildEmptyState()
                : _ApiKeyGrid(
                    state: state,
                    canManage: canManage,
                    onRevoke: (apiKey) => _onRevoke(context, apiKey),
                    onDelete: (apiKey) => _onDelete(context, apiKey),
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
          Icon(Icons.vpn_key_outlined,
              size: 64, color: AppColors.navy.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text('No API keys yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.navy.withOpacity(0.4))),
          const SizedBox(height: 8),
          Text('Create your first API key',
              style: TextStyle(
                  fontSize: 14, color: AppColors.navy.withOpacity(0.25))),
        ],
      ),
    );
  }

  // ── Operations ───────────────────────────────────────────────────

  Future<void> _reload(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    final cubit = context.read<ApiKeysCubit>();
    await ApiKeysPage._load(authCubit, cubit);
  }

  Future<void> _onCreate(BuildContext context) async {
    final dialogResult = await showDialog<ApiKeyDialogResult>(
      context: context,
      builder: (_) => const ApiKeyDialog(),
    );
    if (dialogResult == null) return;
    if (!context.mounted) return;

    final token = await context.read<AuthCubit>().getValidAccessToken();
    if (token == null) return;
    if (!context.mounted) return;

    final authState =
        context.read<AuthCubit>().state as AuthAuthenticated;
    await context.read<ApiKeysCubit>().issue(
          accessToken: token,
          projectId: authState.currentProject!.id,
          name: dialogResult.name,
          expiresAt: dialogResult.expiresAt,
        );
  }

  Future<void> _handleIssued(
      BuildContext context, ApiKeyCreated created) async {
    await showDialog<void>(
      context: context,
      builder: (_) => RawTokenDialog(rawToken: created.rawToken),
    );
    if (!context.mounted) return;

    final authState =
        context.read<AuthCubit>().state as AuthAuthenticated;
    context.read<ApiKeysCubit>().addIssuedToList(
          created,
          authState.currentProject!.id,
        );
  }

  Future<void> _onRevoke(BuildContext context, ApiKey apiKey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Revoke API Key',
        message: 'Are you sure you want to revoke "${apiKey.name}"?',
        confirmLabel: 'Revoke',
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final token = await context.read<AuthCubit>().getValidAccessToken();
    if (token == null) return;
    if (!context.mounted) return;

    final authState =
        context.read<AuthCubit>().state as AuthAuthenticated;
    await context.read<ApiKeysCubit>().revoke(
          accessToken: token,
          projectId: authState.currentProject!.id,
          apiKeyId: apiKey.id,
        );
  }

  Future<void> _onDelete(BuildContext context, ApiKey apiKey) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Delete API Key',
        message:
            'Permanently delete "${apiKey.name}"? This cannot be undone.',
        confirmLabel: 'Delete',
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final token = await context.read<AuthCubit>().getValidAccessToken();
    if (token == null) return;
    if (!context.mounted) return;

    final authState =
        context.read<AuthCubit>().state as AuthAuthenticated;
    await context.read<ApiKeysCubit>().delete(
          accessToken: token,
          projectId: authState.currentProject!.id,
          apiKeyId: apiKey.id,
        );
  }
}

// ── API Key Grid ──────────────────────────────────────────────

class _ApiKeyGrid extends StatelessWidget {
  const _ApiKeyGrid({
    required this.state,
    required this.canManage,
    required this.onRevoke,
    required this.onDelete,
  });

  final ApiKeysLoaded state;
  final bool canManage;
  final void Function(ApiKey) onRevoke;
  final void Function(ApiKey) onDelete;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double minCard = 360;
        const double gap = 14;
        final int columns =
            (constraints.maxWidth / (minCard + gap)).floor().clamp(1, 3);
        final double cardWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap * (columns - 1)) / columns;

        return SingleChildScrollView(
          child: Column(
            children: [
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (final apiKey in state.apiKeys)
                    SizedBox(
                      width: cardWidth,
                      child: ApiKeyCard(
                        key: ValueKey(apiKey.id),
                        apiKey: apiKey,
                        onRevoke: canManage && apiKey.active
                            ? () => onRevoke(apiKey)
                            : null,
                        onDelete: canManage && !apiKey.active
                            ? () => onDelete(apiKey)
                            : null,
                      ),
                    ),
                ],
              ),
              if (state.totalPages > 1) ...[
                const SizedBox(height: 20),
                _buildPagination(context),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildPagination(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PagerBtn(
          text: '\u00AB',
          enabled: state.page > 0,
          active: false,
          onTap: () => _goToPage(context, state.page - 1),
        ),
        ...List.generate(state.totalPages, (i) {
          return _PagerBtn(
            text: '${i + 1}',
            enabled: true,
            active: i == state.page,
            onTap: () => _goToPage(context, i),
          );
        }),
        _PagerBtn(
          text: '\u00BB',
          enabled: state.page < state.totalPages - 1,
          active: false,
          onTap: () => _goToPage(context, state.page + 1),
        ),
      ],
    );
  }

  Future<void> _goToPage(BuildContext context, int page) async {
    final authCubit = context.read<AuthCubit>();
    final cubit = context.read<ApiKeysCubit>();
    await ApiKeysPage._load(authCubit, cubit, page: page);
  }
}

// ── Create button ───────────────────────────────────────────────

class _CreateButton extends StatelessWidget {
  final String label;
  final VoidCallback onPressed;
  const _CreateButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ComicButton(
      label: label,
      icon: Icons.add_rounded,
      onPressed: onPressed,
    );
  }
}

// ── Pager button ────────────────────────────────────────────────

class _PagerBtn extends StatelessWidget {
  const _PagerBtn({
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

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

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
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy.withOpacity(0.9),
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
          const SizedBox(height: 16),

          // Count
          Text(
            '${state.totalElements} API key(s)',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.navy.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 16),

          // List
          Expanded(
            child: state.apiKeys.isEmpty
                ? _buildEmptyState()
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: ListView.builder(
                        itemCount: state.apiKeys.length,
                        itemBuilder: (context, index) {
                          final apiKey = state.apiKeys[index];
                          return ApiKeyCard(
                            key: ValueKey(apiKey.id.value),
                            apiKey: apiKey,
                            onRevoke: canManage
                                ? () => _onRevoke(context, apiKey)
                                : null,
                          );
                        },
                      ),
                    ),
                  ),
          ),

          // Pagination
          if (state.totalPages > 1) ...[
            const SizedBox(height: 16),
            _buildPagination(context, state),
          ],
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

  Widget _buildPagination(BuildContext context, ApiKeysLoaded state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PaginationArrow(
          icon: Icons.chevron_left_rounded,
          enabled: state.page > 0,
          onTap: () => _goToPage(context, state.page - 1),
        ),
        const SizedBox(width: 8),
        ...List.generate(state.totalPages, (i) {
          final isActive = i == state.page;
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
                      : AppColors.navy.withOpacity(0.06),
                  border: Border.all(
                    color: isActive
                        ? AppColors.coral.withOpacity(0.4)
                        : AppColors.navy.withOpacity(0.08),
                  ),
                ),
                child: Text('${i + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.coral
                          : AppColors.navy.withOpacity(0.5),
                    )),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        _PaginationArrow(
          icon: Icons.chevron_right_rounded,
          enabled: state.page < state.totalPages - 1,
          onTap: () => _goToPage(context, state.page + 1),
        ),
      ],
    );
  }

  // ── Operations ───────────────────────────────────────────────────

  Future<void> _reload(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    final cubit = context.read<ApiKeysCubit>();
    await ApiKeysPage._load(authCubit, cubit);
  }

  Future<void> _goToPage(BuildContext context, int page) async {
    final authCubit = context.read<AuthCubit>();
    final cubit = context.read<ApiKeysCubit>();
    await ApiKeysPage._load(authCubit, cubit, page: page);
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

// ── Pagination arrow ────────────────────────────────────────────

class _PaginationArrow extends StatelessWidget {
  final IconData icon;
  final bool enabled;
  final VoidCallback onTap;

  const _PaginationArrow({
    required this.icon,
    required this.enabled,
    required this.onTap,
  });

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
          color: AppColors.navy.withOpacity(0.06),
          border: Border.all(color: AppColors.navy.withOpacity(0.08)),
        ),
        child: Icon(icon,
            size: 20,
            color: enabled
                ? AppColors.navy.withOpacity(0.7)
                : AppColors.navy.withOpacity(0.15)),
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

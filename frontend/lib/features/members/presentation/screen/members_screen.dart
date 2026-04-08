import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feature_toggle_app/app/di/injection.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/core/domain/value_objects/project_role.dart';
import 'package:feature_toggle_app/core/presentation/widgets/app_snackbar.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_cubit.dart';
import 'package:feature_toggle_app/features/users/application/usecase/search_users_usecase.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_state.dart';
import 'package:feature_toggle_app/features/members/application/bloc/members_cubit.dart';
import 'package:feature_toggle_app/features/members/application/bloc/members_state.dart';
import 'package:feature_toggle_app/features/members/domain/model/project_membership.dart';
import 'package:feature_toggle_app/features/members/presentation/widget/member_card.dart';
import 'package:feature_toggle_app/features/members/presentation/widget/add_member_dialog.dart'
    show AddMemberDialog, AddMemberDialogResult;

class MembersPage extends StatelessWidget {
  const MembersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<MembersCubit>();
        _load(context.read<AuthCubit>(), cubit);
        return cubit;
      },
      child: const _MembersView(),
    );
  }

  static Future<void> _load(
    AuthCubit auth,
    MembersCubit cubit, {
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

class _MembersView extends StatelessWidget {
  const _MembersView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<MembersCubit, MembersState>(
      listener: (context, state) {
        if (state is MembersError) {
          showAppSnackBar(context, state.failure);
        }
      },
      builder: (context, state) => switch (state) {
        MembersInitial() || MembersLoading() => _buildLoading(),
        MembersError(:final failure) => _buildError(context, failure.message),
        MembersLoaded() => _buildLoaded(context, state as MembersLoaded),
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

  Widget _buildLoaded(BuildContext context, MembersLoaded state) {
    final authState =
        context.read<AuthCubit>().state as AuthAuthenticated;
    final canManage =
        authState.canManageMembers && !authState.isProjectArchived;

    final currentUserId = authState.currentUser?.id;
    final visibleMembers = state.members
        .where((m) => m.userId != currentUserId)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Text(
                'Members',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const Spacer(),
              if (canManage)
                _CreateButton(
                  label: 'Add Member',
                  onPressed: () => _onAdd(context),
                ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 16),

          // Count
          Text(
            '${state.totalElements} member(s)',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 16),

          // List
          Expanded(
            child: visibleMembers.isEmpty
                ? _buildEmptyState()
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: ListView.builder(
                        itemCount: visibleMembers.length,
                        itemBuilder: (context, index) {
                          final member = visibleMembers[index];
                          return MemberCard(
                            key: ValueKey(member.id.value),
                            membership: member,
                            onRoleChange: canManage
                                ? (newRole) => _onRoleChange(
                                    context, member, newRole)
                                : null,
                            onDelete: canManage
                                ? () => _onDelete(context, member)
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
          Icon(Icons.people_outline_rounded,
              size: 64, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text('No members yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.4))),
          const SizedBox(height: 8),
          Text('Add the first member to this project',
              style: TextStyle(
                  fontSize: 14, color: Colors.white.withOpacity(0.25))),
        ],
      ),
    );
  }

  Widget _buildPagination(BuildContext context, MembersLoaded state) {
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
                      : Colors.white.withOpacity(0.06),
                  border: Border.all(
                    color: isActive
                        ? AppColors.coral.withOpacity(0.4)
                        : Colors.white.withOpacity(0.08),
                  ),
                ),
                child: Text('${i + 1}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isActive ? FontWeight.w600 : FontWeight.w400,
                      color: isActive
                          ? AppColors.coral
                          : Colors.white.withOpacity(0.5),
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
    final cubit = context.read<MembersCubit>();
    await MembersPage._load(authCubit, cubit);
  }

  Future<void> _goToPage(BuildContext context, int page) async {
    final authCubit = context.read<AuthCubit>();
    final cubit = context.read<MembersCubit>();
    await MembersPage._load(authCubit, cubit, page: page);
  }

  Future<void> _onAdd(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();

    final result = await showDialog<AddMemberDialogResult>(
      context: context,
      builder: (_) => AddMemberDialog(
        onSearch: (query) async {
          final token = await authCubit.getValidAccessToken();
          if (token == null) return [];
          final result = await sl<SearchUsersUseCase>()(
            accessToken: token,
            query: query,
          );
          return result.getOrElse((_) => []);
        },
      ),
    );
    if (result == null) return;
    if (!context.mounted) return;

    final token = await authCubit.getValidAccessToken();
    if (token == null) return;
    if (!context.mounted) return;

    final authState = authCubit.state as AuthAuthenticated;
    await context.read<MembersCubit>().add(
          accessToken: token,
          projectId: authState.currentProject!.id,
          userId: UserId(result.userId),
          role: result.role.value,
        );
  }

  Future<void> _onRoleChange(
    BuildContext context,
    ProjectMembership member,
    ProjectRole newRole,
  ) async {
    final token = await context.read<AuthCubit>().getValidAccessToken();
    if (token == null) return;
    if (!context.mounted) return;

    final authState =
        context.read<AuthCubit>().state as AuthAuthenticated;
    await context.read<MembersCubit>().changeRole(
          accessToken: token,
          projectId: authState.currentProject!.id,
          userId: member.userId,
          role: newRole.value,
        );
  }

  Future<void> _onDelete(
    BuildContext context,
    ProjectMembership member,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: 'Remove Member',
        message:
            'Are you sure you want to remove this member from the project?',
        confirmLabel: 'Remove',
      ),
    );
    if (confirmed != true) return;
    if (!context.mounted) return;

    final token = await context.read<AuthCubit>().getValidAccessToken();
    if (token == null) return;
    if (!context.mounted) return;

    final authState =
        context.read<AuthCubit>().state as AuthAuthenticated;
    await context.read<MembersCubit>().remove(
          accessToken: token,
          projectId: authState.currentProject!.id,
          userId: member.userId,
        );
  }
}

// ── Create button ───────────────────────────────────────────────

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
          color: Colors.white.withOpacity(0.06),
          border: Border.all(color: Colors.white.withOpacity(0.08)),
        ),
        child: Icon(icon,
            size: 20,
            color: enabled
                ? Colors.white.withOpacity(0.7)
                : Colors.white.withOpacity(0.15)),
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

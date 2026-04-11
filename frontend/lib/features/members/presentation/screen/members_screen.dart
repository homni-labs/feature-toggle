import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:feature_toggle_app/app/di/injection.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/core/domain/value_objects/project_role.dart';
import 'package:feature_toggle_app/core/domain/failure.dart';
import 'package:feature_toggle_app/core/presentation/widgets/app_snackbar.dart';
import 'package:feature_toggle_app/core/presentation/widgets/comic_button.dart';
import 'package:feature_toggle_app/core/presentation/widgets/forbidden_page.dart';
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
      buildWhen: (previous, current) =>
          current is! MembersError || previous is! MembersLoaded,
      builder: (context, state) => switch (state) {
        MembersInitial() || MembersLoading() => _buildLoading(),
        MembersError(:final failure) => _buildError(context, failure),
        MembersLoaded() => _buildLoaded(context, state as MembersLoaded),
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

  Widget _buildLoaded(BuildContext context, MembersLoaded state) {
    final authState =
        context.read<AuthCubit>().state as AuthAuthenticated;
    final canManage =
        authState.canManageMembers && !authState.isProjectArchived;

    final currentUserId = authState.currentUser?.id;
    final all = state.members
        .where((m) => m.userId != currentUserId)
        .toList();

    // Group by role
    final admins =
        all.where((m) => m.role == ProjectRole.admin).toList();
    final editors =
        all.where((m) => m.role == ProjectRole.editor).toList();
    final readers =
        all.where((m) => m.role == ProjectRole.reader).toList();

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                'Members',
                style: GoogleFonts.fredoka(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: AppColors.navy,
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
          const SizedBox(height: 2),
          Text(
            '${state.totalElements} members',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.navy.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 12),

          Expanded(
            child: all.isEmpty
                ? _buildEmptyState()
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 740),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (admins.isNotEmpty)
                            _buildGroup(
                              context: context,
                              title: 'Admins',
                              count: admins.length,
                              color: AppColors.coral,
                              members: admins,
                              canManage: canManage,
                            ),
                          if (editors.isNotEmpty)
                            _buildGroup(
                              context: context,
                              title: 'Editors',
                              count: editors.length,
                              color: AppColors.teal,
                              members: editors,
                              canManage: canManage,
                            ),
                          if (readers.isNotEmpty)
                            _buildGroup(
                              context: context,
                              title: 'Readers',
                              count: readers.length,
                              color: AppColors.purple,
                              members: readers,
                              canManage: canManage,
                            ),
                          if (state.totalPages > 1) ...[
                            const SizedBox(height: 20),
                            _buildPagination(context, state),
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

  Widget _buildGroup({
    required BuildContext context,
    required String title,
    required int count,
    required Color color,
    required List<ProjectMembership> members,
    required bool canManage,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.only(bottom: 8, top: 4),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: color, width: 2),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: color,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  title,
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const Spacer(),
                Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.navy.withOpacity(0.3),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          // Member cards
          ...members.map((member) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: MemberCard(
                  key: ValueKey(member.id.value),
                  membership: member,
                  onRoleChange: canManage
                      ? (newRole) =>
                          _onRoleChange(context, member, newRole)
                      : null,
                  onDelete: canManage
                      ? () => _onDelete(context, member)
                      : null,
                ),
              )),
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
              size: 64, color: AppColors.navy.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text('No members yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.navy.withOpacity(0.4))),
          const SizedBox(height: 8),
          Text('Add the first member to this project',
              style: TextStyle(
                  fontSize: 14, color: AppColors.navy.withOpacity(0.25))),
        ],
      ),
    );
  }

  Widget _buildPagination(BuildContext context, MembersLoaded state) {
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

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feature_toggle_app/app/di/injection.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';
import 'package:feature_toggle_app/core/presentation/widgets/app_snackbar.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_cubit.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_state.dart';
import 'package:feature_toggle_app/features/auth/domain/model/user.dart';
import 'package:feature_toggle_app/features/users/application/bloc/users_cubit.dart';
import 'package:feature_toggle_app/features/users/application/bloc/users_state.dart';
import 'package:feature_toggle_app/features/users/presentation/widget/user_card.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<UsersCubit>();
        _load(context.read<AuthCubit>(), cubit);
        return cubit;
      },
      child: const _UsersView(),
    );
  }

  static Future<void> _load(
    AuthCubit auth,
    UsersCubit cubit, {
    int page = 0,
  }) async {
    final token = await auth.getValidAccessToken();
    if (token == null) return;
    await cubit.load(accessToken: token, page: page);
  }
}

class _UsersView extends StatelessWidget {
  const _UsersView();

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UsersCubit, UsersState>(
      listener: (context, state) {
        if (state is UsersError) {
          showAppSnackBar(context, state.failure);
        }
      },
      builder: (context, state) => switch (state) {
        UsersInitial() || UsersLoading() => _buildLoading(),
        UsersError(:final failure) => _buildError(context, failure.message),
        UsersLoaded() => _buildLoaded(context, state as UsersLoaded),
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

  Widget _buildLoaded(BuildContext context, UsersLoaded state) {
    final authState =
        context.read<AuthCubit>().state as AuthAuthenticated;
    final currentUserId = authState.currentUser?.id;
    final filteredUsers = state.users
        .where((u) => u.id != currentUserId)
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
                'Users',
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const Spacer(),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 16),

          // Count
          Text(
            '${state.totalElements} user(s)',
            style: TextStyle(
              fontSize: 13,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 16),

          // List
          Expanded(
            child: filteredUsers.isEmpty
                ? _buildEmptyState()
                : Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 700),
                      child: ListView.builder(
                        itemCount: filteredUsers.length,
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return UserCard(
                            key: ValueKey(user.id.value),
                            user: user,
                            onToggleRole: () =>
                                _onToggleRole(context, user),
                            onToggleActive: () =>
                                _onToggleActive(context, user),
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
          Text('No users yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withOpacity(0.4))),
          const SizedBox(height: 8),
          Text('Users will appear after they sign in',
              style: TextStyle(
                  fontSize: 14, color: Colors.white.withOpacity(0.25))),
        ],
      ),
    );
  }

  Widget _buildPagination(BuildContext context, UsersLoaded state) {
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
    final cubit = context.read<UsersCubit>();
    await UsersPage._load(authCubit, cubit);
  }

  Future<void> _goToPage(BuildContext context, int page) async {
    final authCubit = context.read<AuthCubit>();
    final cubit = context.read<UsersCubit>();
    await UsersPage._load(authCubit, cubit, page: page);
  }

  Future<void> _onToggleRole(BuildContext context, User user) async {
    final token = await context.read<AuthCubit>().getValidAccessToken();
    if (token == null) return;
    if (!context.mounted) return;

    final newRole = user.isPlatformAdmin ? 'USER' : 'PLATFORM_ADMIN';
    await context.read<UsersCubit>().toggleRole(
          accessToken: token,
          userId: user.id,
          newRole: newRole,
        );
  }

  Future<void> _onToggleActive(BuildContext context, User user) async {
    final token = await context.read<AuthCubit>().getValidAccessToken();
    if (token == null) return;
    if (!context.mounted) return;

    await context.read<UsersCubit>().toggleActive(
          accessToken: token,
          userId: user.id,
          active: !user.active,
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

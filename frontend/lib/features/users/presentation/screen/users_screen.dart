import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:togli_app/app/di/injection.dart';
import 'package:togli_app/app/theme/app_colors.dart';
import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/core/domain/failure.dart';
import 'package:togli_app/core/presentation/widgets/app_snackbar.dart';
import 'package:togli_app/core/presentation/widgets/forbidden_page.dart';
import 'package:togli_app/features/auth/application/bloc/auth_cubit.dart';
import 'package:togli_app/features/auth/application/bloc/auth_state.dart';
import 'package:togli_app/features/auth/domain/model/user.dart';
import 'package:togli_app/features/users/application/bloc/users_cubit.dart';
import 'package:togli_app/features/users/application/bloc/users_state.dart';
import 'package:togli_app/features/users/presentation/widget/user_card.dart';

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

// ── Colors ─────────────────────────────────────────────────────────
const _creamDark = Color(0xFFDDD8CC);

class _UsersView extends StatefulWidget {
  const _UsersView();

  @override
  State<_UsersView> createState() => _UsersViewState();
}

class _UsersViewState extends State<_UsersView> {
  final _searchController = TextEditingController();
  final _searchFocus = FocusNode();
  bool _searchFocused = false;

  @override
  void initState() {
    super.initState();
    _searchFocus.addListener(() {
      setState(() => _searchFocused = _searchFocus.hasFocus);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchFocus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<UsersCubit, UsersState>(
      listener: (context, state) {
        if (state is UsersError) {
          showAppSnackBar(context, state.failure);
        }
      },
      buildWhen: (previous, current) =>
          current is! UsersError || previous is! UsersLoaded,
      builder: (context, state) => switch (state) {
        UsersInitial() || UsersLoading() => _buildLoading(),
        UsersError(:final failure) => _buildError(context, failure),
        UsersLoaded() => _buildLoaded(context, state as UsersLoaded),
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
              size: 48, color: AppColors.navy.withOpacity(0.25)),
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

  Widget _buildLoaded(BuildContext context, UsersLoaded state) {
    final authState =
        context.read<AuthCubit>().state as AuthAuthenticated;
    final currentUserId = authState.currentUser?.id;
    final allUsers = state.users;

    // Filter by search query
    final query = _searchController.text.toLowerCase();
    final filteredUsers = query.isEmpty
        ? allUsers
        : allUsers.where((u) {
            final email = u.email.value.toLowerCase();
            final name = (u.name ?? '').toLowerCase();
            return email.contains(query) || name.contains(query);
          }).toList();

    // Group users into 3 sections
    final platformAdmins = filteredUsers
        .where((u) => u.isPlatformAdmin && u.active)
        .toList();
    final regularUsers = filteredUsers
        .where((u) => !u.isPlatformAdmin && u.active)
        .toList();
    final inactive = filteredUsers
        .where((u) => !u.active)
        .toList();

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Users',
            style: GoogleFonts.fredoka(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 2),

          // Subtitle
          Text(
            '${state.totalElements} users',
            style: GoogleFonts.fredoka(
              fontSize: 13,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),

          // Search bar
          _buildSearchBar(),
          const SizedBox(height: 8),

          // Scrollable body with grouped sections + pagination
          Expanded(
            child: filteredUsers.isEmpty
                ? _buildEmptyState()
                : ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 740),
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                            // Platform Admins section
                            if (platformAdmins.isNotEmpty)
                              _buildGroupSection(
                                context: context,
                                title: 'Platform Admins',
                                count: platformAdmins.length,
                                borderColor: AppColors.yellow,
                                users: platformAdmins,
                                currentUserId: currentUserId,
                              ),

                            // Users section
                            if (regularUsers.isNotEmpty)
                              _buildGroupSection(
                                context: context,
                                title: 'Users',
                                count: regularUsers.length,
                                borderColor: AppColors.teal,
                                users: regularUsers,
                                currentUserId: currentUserId,
                              ),

                            // Inactive section
                            if (inactive.isNotEmpty)
                              _buildGroupSection(
                                context: context,
                                title: 'Inactive',
                                count: inactive.length,
                                borderColor: _creamDark,
                                users: inactive,
                                currentUserId: currentUserId,
                              ),

                            // Pagination inside scroll view
                            if (state.totalPages > 1) ...[
                              const SizedBox(height: 24),
                              _buildPagination(context, state),
                              const SizedBox(height: 16),
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

  Widget _buildSearchBar() {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 740),
      child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: _searchFocused ? AppColors.coral : _creamDark,
              width: 3,
            ),
          ),
          child: TextField(
            controller: _searchController,
            focusNode: _searchFocus,
            onChanged: (_) => setState(() {}),
            style: GoogleFonts.fredoka(fontSize: 13, color: AppColors.navy),
            decoration: InputDecoration(
              hintText: 'Search by name or email...',
              hintStyle: GoogleFonts.fredoka(
                fontSize: 13,
                color: Colors.grey.shade400,
              ),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 18,
                color: _searchFocused ? AppColors.coral : Colors.grey.shade400,
              ),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ),
      );
  }

  Widget _buildGroupSection({
    required BuildContext context,
    required String title,
    required int count,
    required Color borderColor,
    required List<User> users,
    UserId? currentUserId,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          Container(
            padding: const EdgeInsets.only(bottom: 8),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor, width: 2),
              ),
            ),
            child: Row(
              children: [
                Text(
                  title,
                  style: GoogleFonts.fredoka(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: AppColors.navy,
                  ),
                ),
                const Spacer(),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: borderColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.fredoka(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: borderColor == _creamDark
                          ? AppColors.navy.withOpacity(0.5)
                          : borderColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // User cards
          ...users.map((user) {
            final bool isSelf = currentUserId != null &&
                user.id == currentUserId;
            return UserCard(
              key: ValueKey(user.id.value),
              user: user,
              isCurrentUser: isSelf,
              onToggleRole: isSelf
                  ? null
                  : () => _onToggleRole(context, user),
              onToggleActive: isSelf
                  ? null
                  : () => _onToggleActive(context, user),
            );
          }),
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
          Text('No users yet',
              style: GoogleFonts.fredoka(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.navy.withOpacity(0.4))),
          const SizedBox(height: 8),
          Text('Users will appear after they sign in',
              style: GoogleFonts.fredoka(
                  fontSize: 14,
                  color: AppColors.navy.withOpacity(0.25))),
        ],
      ),
    );
  }

  Widget _buildPagination(BuildContext context, UsersLoaded state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Previous arrow
        _PaginationButton(
          label: '\u00AB',
          enabled: state.page > 0,
          isActive: false,
          onTap: () => _goToPage(context, state.page - 1),
        ),
        const SizedBox(width: 6),
        // Page numbers
        ...List.generate(state.totalPages, (i) {
          final isActive = i == state.page;
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: _PaginationButton(
              label: '${i + 1}',
              enabled: true,
              isActive: isActive,
              onTap: () => _goToPage(context, i),
            ),
          );
        }),
        const SizedBox(width: 6),
        // Next arrow
        _PaginationButton(
          label: '\u00BB',
          enabled: state.page < state.totalPages - 1,
          isActive: false,
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

// ── Pagination button ──────────────────────────────────────────────

class _PaginationButton extends StatefulWidget {
  final String label;
  final bool enabled;
  final bool isActive;
  final VoidCallback onTap;

  const _PaginationButton({
    required this.label,
    required this.enabled,
    required this.isActive,
    required this.onTap,
  });

  @override
  State<_PaginationButton> createState() => _PaginationButtonState();
}

class _PaginationButtonState extends State<_PaginationButton> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      cursor: widget.enabled
          ? SystemMouseCursors.click
          : SystemMouseCursors.basic,
      child: GestureDetector(
        onTap: widget.enabled ? widget.onTap : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34,
          height: 34,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            color: widget.isActive
                ? AppColors.coral.withOpacity(0.10)
                : (_hovering
                    ? _creamDark.withOpacity(0.15)
                    : Colors.transparent),
            border: Border.all(
              color: widget.isActive ? AppColors.coral : _creamDark,
              width: 2,
            ),
          ),
          child: Text(
            widget.label,
            style: GoogleFonts.fredoka(
              fontSize: 13,
              fontWeight:
                  widget.isActive ? FontWeight.w600 : FontWeight.w400,
              color: widget.isActive
                  ? AppColors.coral
                  : (widget.enabled
                      ? AppColors.navy.withOpacity(0.6)
                      : AppColors.navy.withOpacity(0.2)),
            ),
          ),
        ),
      ),
    );
  }
}

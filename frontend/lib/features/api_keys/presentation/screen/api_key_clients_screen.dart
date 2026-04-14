import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:togli_app/app/di/injection.dart';
import 'package:togli_app/app/router/app_router.dart';
import 'package:togli_app/app/theme/app_colors.dart';
import 'package:togli_app/core/domain/failure.dart';
import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/core/presentation/widgets/app_snackbar.dart';
import 'package:togli_app/core/presentation/widgets/forbidden_page.dart';
import 'package:togli_app/features/auth/application/bloc/auth_cubit.dart';
import 'package:togli_app/features/auth/application/bloc/auth_state.dart';
import 'package:togli_app/features/api_keys/application/bloc/api_key_clients_cubit.dart';
import 'package:togli_app/features/api_keys/application/bloc/api_key_clients_state.dart';
import 'package:togli_app/features/api_keys/domain/model/api_key_client.dart';
import 'package:togli_app/features/api_keys/presentation/widget/api_key_client_card.dart';

class ApiKeyClientsPage extends StatelessWidget {
  final String apiKeyId;
  final String apiKeyName;
  final String maskedToken;

  const ApiKeyClientsPage({
    super.key,
    required this.apiKeyId,
    required this.apiKeyName,
    required this.maskedToken,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) {
        final cubit = sl<ApiKeyClientsCubit>();
        _load(context.read<AuthCubit>(), cubit);
        return cubit;
      },
      child: _ApiKeyClientsView(
        apiKeyId: apiKeyId,
        apiKeyName: apiKeyName,
        maskedToken: maskedToken,
      ),
    );
  }

  Future<void> _load(AuthCubit auth, ApiKeyClientsCubit cubit) async {
    final token = await auth.getValidAccessToken();
    if (token == null) return;
    final authState = auth.state as AuthAuthenticated;
    await cubit.load(
      token,
      authState.currentProject!.id,
      ApiKeyId(apiKeyId),
    );
  }
}

class _ApiKeyClientsView extends StatelessWidget {
  final String apiKeyId;
  final String apiKeyName;
  final String maskedToken;

  const _ApiKeyClientsView({
    required this.apiKeyId,
    required this.apiKeyName,
    required this.maskedToken,
  });

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ApiKeyClientsCubit, ApiKeyClientsState>(
      listener: (context, state) {
        if (state is ApiKeyClientsError) {
          showAppSnackBar(context, state.failure);
        }
      },
      builder: (context, state) => switch (state) {
        ApiKeyClientsInitial() || ApiKeyClientsLoading() => _buildLoading(),
        ApiKeyClientsError(:final failure) => _buildError(context, failure),
        ApiKeyClientsLoaded() =>
          _buildLoaded(context, state as ApiKeyClientsLoaded),
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

  Widget _buildLoaded(BuildContext context, ApiKeyClientsLoaded state) {
    final authState =
        context.read<AuthCubit>().state as AuthAuthenticated;
    final slug = authState.currentProject!.slug.value;

    final totalRequests = state.clients.fold<int>(
      0,
      (sum, c) => sum + c.requestCount,
    );

    DateTime? lastActivity;
    for (final c in state.clients) {
      if (lastActivity == null || c.lastSeenAt.isAfter(lastActivity)) {
        lastActivity = c.lastSeenAt;
      }
    }

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Breadcrumb
          Row(
            children: [
              _BreadcrumbLink(
                label: 'API Keys',
                onTap: () => context.go(AppRoutes.projectApiKeys(slug)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  '/',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.navy.withOpacity(0.3),
                  ),
                ),
              ),
              Text(
                apiKeyName,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.navy.withOpacity(0.6),
                ),
              ),
            ],
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 12),

          // Header
          Text(
            apiKeyName,
            style: GoogleFonts.fredoka(
              fontSize: 26,
              fontWeight: FontWeight.w700,
              color: AppColors.navy,
            ),
          ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 4),
          Text(
            maskedToken,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'monospace',
              color: AppColors.navy.withOpacity(0.3),
            ),
          ),
          const SizedBox(height: 20),

          // Stats row
          Row(
            children: [
              _StatCard(
                label: 'Services',
                value: '${state.clients.length}',
                icon: Icons.dns_outlined,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Total Requests',
                value: _formatCount(totalRequests),
                icon: Icons.swap_horiz_rounded,
              ),
              const SizedBox(width: 12),
              _StatCard(
                label: 'Last Activity',
                value: lastActivity != null
                    ? _formatTimeAgo(lastActivity)
                    : 'Never',
                icon: Icons.schedule_rounded,
              ),
            ],
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 16),

          // Legend
          Row(
            children: [
              _LegendDot(color: AppColors.green, label: 'Active (<10 min)'),
              const SizedBox(width: 16),
              _LegendDot(color: AppColors.yellow, label: 'Recent (<1 hr)'),
              const SizedBox(width: 16),
              _LegendDot(
                  color: const Color(0xFFBBBBBB), label: 'Stale'),
            ],
          ),
          const SizedBox(height: 20),

          // Client sections
          Expanded(
            child: state.clients.isEmpty
                ? _buildEmptyState()
                : SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (state.sdkClients.isNotEmpty) ...[
                          _SectionHeader(
                            label: 'SDK Clients',
                            color: AppColors.teal,
                          ),
                          const SizedBox(height: 12),
                          _ClientGrid(clients: state.sdkClients),
                          const SizedBox(height: 24),
                        ],
                        if (state.restClients.isNotEmpty) ...[
                          _SectionHeader(
                            label: 'REST Clients',
                            color: AppColors.purple,
                          ),
                          const SizedBox(height: 12),
                          _ClientGrid(clients: state.restClients),
                        ],
                      ],
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
          Icon(Icons.devices_other_rounded,
              size: 64, color: AppColors.navy.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text('No clients yet',
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: AppColors.navy.withOpacity(0.4))),
          const SizedBox(height: 8),
          Text('Clients will appear once this API key is used',
              style: TextStyle(
                  fontSize: 14, color: AppColors.navy.withOpacity(0.25))),
        ],
      ),
    );
  }

  Future<void> _reload(BuildContext context) async {
    final authCubit = context.read<AuthCubit>();
    final cubit = context.read<ApiKeyClientsCubit>();
    final token = await authCubit.getValidAccessToken();
    if (token == null) return;
    final authState = authCubit.state as AuthAuthenticated;
    await cubit.load(
      token,
      authState.currentProject!.id,
      ApiKeyId(apiKeyId),
    );
  }

  static String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} hours ago';
    return '${diff.inDays} days ago';
  }

  static String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    }
    if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return '$count';
  }
}

// ── Breadcrumb link ──────────────────────────────────────────────

class _BreadcrumbLink extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  const _BreadcrumbLink({required this.label, required this.onTap});

  @override
  State<_BreadcrumbLink> createState() => _BreadcrumbLinkState();
}

class _BreadcrumbLinkState extends State<_BreadcrumbLink> {
  bool _hovering = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hovering = true),
      onExit: (_) => setState(() => _hovering = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Text(
          widget.label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: _hovering
                ? AppColors.coral
                : AppColors.navy.withOpacity(0.4),
            decoration:
                _hovering ? TextDecoration.underline : TextDecoration.none,
            decorationColor: AppColors.coral,
          ),
        ),
      ),
    );
  }
}

// ── Stat card ────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          border: Border.all(color: AppColors.navy, width: 3),
          boxShadow: const [
            BoxShadow(
              color: Color(0xFFDDD8CC),
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, size: 20, color: AppColors.coral.withOpacity(0.6)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 10,
                      color: AppColors.navy.withOpacity(0.45),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    value,
                    style: GoogleFonts.fredoka(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: AppColors.navy,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Legend dot ────────────────────────────────────────────────────

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color,
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: AppColors.navy.withOpacity(0.5),
          ),
        ),
      ],
    );
  }
}

// ── Section header ───────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  final Color color;
  const _SectionHeader({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 20,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(2),
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: GoogleFonts.fredoka(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ── Client grid ──────────────────────────────────────────────────

class _ClientGrid extends StatelessWidget {
  final List<ApiKeyClient> clients;
  const _ClientGrid({required this.clients});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double minCard = 340;
        const double gap = 14;
        final int columns =
            (constraints.maxWidth / (minCard + gap)).floor().clamp(1, 3);
        final double cardWidth = columns == 1
            ? constraints.maxWidth
            : (constraints.maxWidth - gap * (columns - 1)) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final client in clients)
              SizedBox(
                width: cardWidth,
                child: ApiKeyClientCard(
                  key: ValueKey(client.id),
                  client: client,
                ),
              ),
          ],
        );
      },
    );
  }
}

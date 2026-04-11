import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:feature_toggle_app/app/di/injection.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';
import 'package:feature_toggle_app/core/domain/failure.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/core/presentation/widgets/app_snackbar.dart';
import 'package:feature_toggle_app/core/presentation/widgets/comic_button.dart';
import 'package:feature_toggle_app/core/presentation/widgets/forbidden_page.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_cubit.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_state.dart';
import 'package:feature_toggle_app/features/environments/application/bloc/environments_cubit.dart';
import 'package:feature_toggle_app/features/environments/application/bloc/environments_state.dart';
import 'package:feature_toggle_app/features/toggles/application/bloc/toggles_cubit.dart';
import 'package:feature_toggle_app/features/toggles/application/bloc/toggles_state.dart';
import 'package:feature_toggle_app/features/toggles/domain/model/feature_toggle.dart';
import 'package:feature_toggle_app/features/toggles/presentation/widget/toggle_card.dart';
import 'package:feature_toggle_app/features/toggles/presentation/widget/toggle_dialog.dart'
    show ToggleDialog, ToggleDialogResult;

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final AuthCubit authCubit = context.read<AuthCubit>();
    final AuthState authState = authCubit.state;

    final ProjectId? projectId = authState is AuthAuthenticated
        ? authState.currentProject?.id
        : null;

    return MultiBlocProvider(
      providers: [
        BlocProvider<TogglesCubit>(
          create: (_) {
            final TogglesCubit cubit = sl<TogglesCubit>();
            if (projectId != null) {
              _loadToggles(authCubit, cubit, projectId);
            }
            return cubit;
          },
        ),
        BlocProvider<EnvironmentsCubit>(
          create: (_) {
            final EnvironmentsCubit cubit = sl<EnvironmentsCubit>();
            if (projectId != null) {
              _loadEnvironments(authCubit, cubit, projectId);
            }
            return cubit;
          },
        ),
      ],
      child: const _TogglesView(),
    );
  }

  static Future<void> _loadToggles(
    AuthCubit auth,
    TogglesCubit cubit,
    ProjectId projectId,
  ) async {
    final String? token = await auth.getValidAccessToken();
    if (token != null) {
      await cubit.load(accessToken: token, projectId: projectId);
    }
  }

  static Future<void> _loadEnvironments(
    AuthCubit auth,
    EnvironmentsCubit cubit,
    ProjectId projectId,
  ) async {
    final String? token = await auth.getValidAccessToken();
    if (token != null) {
      await cubit.load(accessToken: token, projectId: projectId);
    }
  }
}

// ── Main view ──────────────────────────────────────────────────

class _TogglesView extends StatelessWidget {
  const _TogglesView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<TogglesCubit, TogglesState>(
      listener: (BuildContext context, TogglesState state) {
        if (state is TogglesError) {
          showAppSnackBar(
            context,
            state.failure,
            isWarning: state.failure is ConflictFailure ||
                state.failure is NotFoundFailure,
          );
        }
      },
      child: BlocBuilder<TogglesCubit, TogglesState>(
        buildWhen: (previous, current) =>
            current is! TogglesError || previous is! TogglesLoaded,
        builder: (BuildContext context, TogglesState state) {
          return switch (state) {
            TogglesInitial() ||
            TogglesLoading() =>
              const Center(
                child: CircularProgressIndicator(color: AppColors.coral),
              ),
            TogglesError(:final Failure failure) =>
              _ErrorBody(failure: failure),
            TogglesLoaded() => _LoadedBody(state: state),
          };
        },
      ),
    );
  }
}

// ── Error body ─────────────────────────────────────────────────

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({required this.failure});
  final Failure failure;

  @override
  Widget build(BuildContext context) {
    if (failure is ForbiddenFailure) {
      return const ForbiddenPage();
    }
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 48, color: AppColors.navy.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            failure.message,
            style: TextStyle(
              fontSize: 16,
              color: AppColors.navy.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _retry(context),
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

  Future<void> _retry(BuildContext context) async {
    final AuthCubit authCubit = context.read<AuthCubit>();
    final AuthState authState = authCubit.state;
    if (authState is! AuthAuthenticated) return;

    final ProjectId? projectId = authState.currentProject?.id;
    if (projectId == null) return;

    final String? token = await authCubit.getValidAccessToken();
    if (token == null || !context.mounted) return;

    await context.read<TogglesCubit>().load(
          accessToken: token,
          projectId: projectId,
        );
  }
}

// ── Loaded body ────────────────────────────────────────────────

class _LoadedBody extends StatelessWidget {
  const _LoadedBody({required this.state});
  final TogglesLoaded state;

  @override
  Widget build(BuildContext context) {
    final AuthState authState = context.watch<AuthCubit>().state;
    final bool canWrite = authState is AuthAuthenticated &&
        authState.canWriteToggles &&
        !authState.isProjectArchived;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title row
          Row(
            children: [
              Text(
                'Toggles',
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
          Text(
            '${state.totalElements} toggles',
            style: TextStyle(
              fontSize: 13,
              color: AppColors.navy.withOpacity(0.35),
            ),
          ),
          const SizedBox(height: 16),

          // Search
          _SearchBar(),
          const SizedBox(height: 20),

          // Toggle grid
          Expanded(
            child: state.toggles.isEmpty
                ? const _EmptyState()
                : _ToggleGrid(
                    state: state,
                    canWrite: canWrite,
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _onCreate(BuildContext context) async {
    final EnvironmentsCubit envCubit = context.read<EnvironmentsCubit>();
    final List<String> availableEnvs = envCubit.environmentNames;

    final ToggleDialogResult? result = await showDialog<ToggleDialogResult>(
      context: context,
      builder: (_) => ToggleDialog(availableEnvironments: availableEnvs),
    );
    if (result == null || !context.mounted) return;

    final AuthCubit authCubit = context.read<AuthCubit>();
    final AuthState authState = authCubit.state;
    if (authState is! AuthAuthenticated) return;

    final ProjectId? projectId = authState.currentProject?.id;
    if (projectId == null) return;

    final String? token = await authCubit.getValidAccessToken();
    if (token == null || !context.mounted) return;

    await context.read<TogglesCubit>().create(
          accessToken: token,
          projectId: projectId,
          name: result.name,
          description: result.description,
          environments: result.environments,
        );
  }
}

// ── Toggle grid ───────────────────────────────────────────────

class _ToggleGrid extends StatelessWidget {
  const _ToggleGrid({
    required this.state,
    required this.canWrite,
  });

  final TogglesLoaded state;
  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const double minCard = 340;
        const double gap = 16;
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
                  for (final toggle in state.toggles)
                    SizedBox(
                      width: cardWidth,
                      child: ToggleCard(
                        key: ValueKey(toggle.id),
                        toggle: toggle,
                        onEnvironmentToggle: canWrite
                            ? (envName, value) =>
                                _onEnvSwitch(context, toggle, envName, value)
                            : null,
                        onEdit: canWrite
                            ? () => _onEdit(context, toggle)
                            : null,
                        onDelete: canWrite
                            ? () => _onDelete(context, toggle)
                            : null,
                      ),
                    ),
                ],
              ),
              if (state.totalPages > 1) ...[
                const SizedBox(height: 20),
                _Pagination(
                  page: state.page,
                  totalPages: state.totalPages,
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Future<void> _onEnvSwitch(
    BuildContext context,
    FeatureToggle toggle,
    String envName,
    bool value,
  ) async {
    final AuthCubit authCubit = context.read<AuthCubit>();
    final AuthState authState = authCubit.state;
    if (authState is! AuthAuthenticated) return;

    final ProjectId? projectId = authState.currentProject?.id;
    if (projectId == null) return;

    final String? token = await authCubit.getValidAccessToken();
    if (token == null || !context.mounted) return;

    await context.read<TogglesCubit>().setEnvironmentState(
          accessToken: token,
          projectId: projectId,
          toggleId: toggle.id,
          environmentName: envName,
          enabled: value,
        );
  }

  Future<void> _onEdit(
    BuildContext context,
    FeatureToggle toggle,
  ) async {
    final EnvironmentsCubit envCubit = context.read<EnvironmentsCubit>();
    final List<String> availableEnvs = envCubit.environmentNames;

    final ToggleDialogResult? result = await showDialog<ToggleDialogResult>(
      context: context,
      builder: (_) => ToggleDialog(
        isEdit: true,
        initialName: toggle.name,
        initialDescription: toggle.description,
        initialEnvironments: toggle.environmentNames,
        availableEnvironments: availableEnvs,
      ),
    );
    if (result == null || !context.mounted) return;

    final AuthCubit authCubit = context.read<AuthCubit>();
    final AuthState authState = authCubit.state;
    if (authState is! AuthAuthenticated) return;

    final ProjectId? projectId = authState.currentProject?.id;
    if (projectId == null) return;

    final String? token = await authCubit.getValidAccessToken();
    if (token == null || !context.mounted) return;

    await context.read<TogglesCubit>().update(
          accessToken: token,
          projectId: projectId,
          toggleId: toggle.id,
          name: result.name,
          description: result.description,
          environments: result.environments,
        );
  }

  Future<void> _onDelete(
    BuildContext context,
    FeatureToggle toggle,
  ) async {
    final bool? confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => _DeleteConfirmDialog(name: toggle.name),
    );
    if (confirmed != true || !context.mounted) return;

    final AuthCubit authCubit = context.read<AuthCubit>();
    final AuthState authState = authCubit.state;
    if (authState is! AuthAuthenticated) return;

    final ProjectId? projectId = authState.currentProject?.id;
    if (projectId == null) return;

    final String? token = await authCubit.getValidAccessToken();
    if (token == null || !context.mounted) return;

    await context.read<TogglesCubit>().delete(
          accessToken: token,
          projectId: projectId,
          toggleId: toggle.id,
        );
  }
}

// ── Empty state ────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.toggle_off_outlined,
              size: 64, color: AppColors.navy.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            'No toggles yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: AppColors.navy.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first feature toggle',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.navy.withOpacity(0.25),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Search bar ────────────────────────────────────────────────

class _SearchBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(width: 3, color: const Color(0xFFDDD8CC)),
        color: Colors.white,
      ),
      child: Row(
        children: [
          Icon(Icons.search_rounded,
              size: 16, color: AppColors.navy.withOpacity(0.4)),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              decoration: InputDecoration.collapsed(
                hintText: 'Search toggles...',
                hintStyle: TextStyle(
                  fontSize: 14,
                  color: AppColors.navy.withOpacity(0.3),
                ),
              ),
              style: const TextStyle(fontSize: 14, color: AppColors.navy),
              onChanged: (_) {
                // Client-side search — not connected to API yet
                // Will filter displayed toggles in future iteration
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filters row (kept for reference but not used in new design) ──

class _FiltersRow extends StatelessWidget {
  const _FiltersRow({
    required this.filterEnabled,
    required this.filterEnvironment,
  });

  final bool? filterEnabled;
  final String? filterEnvironment;

  static Color _envFilterColor(String env) {
    switch (env) {
      case 'DEV':
        return AppColors.teal;
      case 'TEST':
        return AppColors.yellow;
      case 'PROD':
        return AppColors.coral;
      default:
        return AppColors.purple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasFilters =
        filterEnabled != null || filterEnvironment != null;
    final String statusLabel = filterEnabled == null
        ? 'Status'
        : filterEnabled! ? 'Enabled' : 'Disabled';
    final String envLabel = filterEnvironment ?? 'Environment';

    // Get available environments from cubit
    final EnvironmentsState envState =
        context.watch<EnvironmentsCubit>().state;
    final List<String> availableEnvs = envState is EnvironmentsLoaded
        ? envState.environments.map((e) => e.name).toList()
        : <String>[];

    return Row(
      children: [
        // Status dropdown
        _FilterDropdown(
          label: statusLabel,
          icon: Icons.power_settings_new_rounded,
          active: filterEnabled != null,
          color: filterEnabled == null
              ? AppColors.purple
              : filterEnabled! ? AppColors.green : AppColors.coral,
          items: const ['All', 'Enabled', 'Disabled'],
          itemColors: const [
            AppColors.purple,
            AppColors.green,
            AppColors.coral,
          ],
          onSelected: (String value) =>
              _applyStatusFilter(context, value),
        ),
        const SizedBox(width: 10),

        // Environment dropdown
        _FilterDropdown(
          label: envLabel,
          icon: Icons.cloud_outlined,
          active: filterEnvironment != null,
          color: filterEnvironment == null
              ? AppColors.teal
              : _envFilterColor(filterEnvironment!),
          items: ['All', ...availableEnvs],
          itemColors: [
            AppColors.teal,
            ...availableEnvs.map(_envFilterColor),
          ],
          onSelected: (String value) => _applyEnvFilter(context, value),
        ),

        // Clear
        if (hasFilters) ...[
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => _clearFilters(context),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: AppColors.navy.withOpacity(0.06),
              ),
              child: Icon(Icons.filter_alt_off_rounded,
                  size: 16, color: AppColors.navy.withOpacity(0.4)),
            ),
          ),
        ],
      ],
    );
  }

  void _applyStatusFilter(BuildContext context, String value) {
    bool? enabled;
    switch (value) {
      case 'Enabled':
        enabled = true;
        break;
      case 'Disabled':
        enabled = false;
        break;
    }
    _reload(context, enabled: enabled, environment: filterEnvironment);
  }

  void _applyEnvFilter(BuildContext context, String value) {
    final String? environment = value == 'All' ? null : value;
    _reload(context, enabled: filterEnabled, environment: environment);
  }

  void _clearFilters(BuildContext context) {
    _reload(context);
  }

  Future<void> _reload(
    BuildContext context, {
    bool? enabled,
    String? environment,
  }) async {
    final AuthCubit authCubit = context.read<AuthCubit>();
    final AuthState authState = authCubit.state;
    if (authState is! AuthAuthenticated) return;

    final ProjectId? projectId = authState.currentProject?.id;
    if (projectId == null) return;

    final String? token = await authCubit.getValidAccessToken();
    if (token == null || !context.mounted) return;

    await context.read<TogglesCubit>().load(
          accessToken: token,
          projectId: projectId,
          page: 0,
          enabled: enabled,
          environment: environment,
        );
  }
}

// ── Pagination (mockup style) ──────────────────────────────────

class _Pagination extends StatelessWidget {
  const _Pagination({
    required this.page,
    required this.totalPages,
  });

  final int page;
  final int totalPages;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _PagerBtn(
          text: '\u00AB',
          enabled: page > 0,
          active: false,
          onTap: () => _goToPage(context, page - 1),
        ),
        ...List.generate(totalPages, (int i) {
          return _PagerBtn(
            text: '${i + 1}',
            enabled: true,
            active: i == page,
            onTap: () => _goToPage(context, i),
          );
        }),
        _PagerBtn(
          text: '\u00BB',
          enabled: page < totalPages - 1,
          active: false,
          onTap: () => _goToPage(context, page + 1),
        ),
      ],
    );
  }

  Future<void> _goToPage(BuildContext context, int targetPage) async {
    final AuthCubit authCubit = context.read<AuthCubit>();
    final AuthState authState = authCubit.state;
    if (authState is! AuthAuthenticated) return;

    final ProjectId? projectId = authState.currentProject?.id;
    if (projectId == null) return;

    final String? token = await authCubit.getValidAccessToken();
    if (token == null || !context.mounted) return;

    await context.read<TogglesCubit>().load(
          accessToken: token,
          projectId: projectId,
          page: targetPage,
        );
  }
}

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

// ── Create button (cartoon style) ─────────────────────────────

class _CreateButton extends StatelessWidget {
  final VoidCallback onPressed;
  const _CreateButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ComicButton(
      label: 'New Toggle',
      icon: Icons.add_rounded,
      onPressed: onPressed,
    );
  }
}

// ── Filter dropdown ─────────────────────────────────────────────

class _FilterDropdown extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool active;
  final Color color;
  final List<String> items;
  final List<Color> itemColors;
  final ValueChanged<String> onSelected;

  const _FilterDropdown({
    required this.label,
    required this.icon,
    required this.active,
    required this.color,
    required this.items,
    required this.itemColors,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<String>(
      onSelected: onSelected,
      offset: const Offset(0, 44),
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: const BorderSide(color: AppColors.navy, width: 2),
      ),
      itemBuilder: (_) => List.generate(items.length, (int i) {
        return PopupMenuItem<String>(
          value: items[i],
          height: 40,
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: itemColors[i],
                ),
              ),
              const SizedBox(width: 10),
              Text(
                items[i],
                style: TextStyle(
                  fontSize: 13,
                  color: AppColors.navy.withOpacity(0.8),
                ),
              ),
            ],
          ),
        );
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: active
              ? color.withOpacity(0.15)
              : AppColors.navy.withOpacity(0.06),
          border: Border.all(
            color: active
                ? color.withOpacity(0.3)
                : AppColors.navy.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: active ? color : AppColors.navy.withOpacity(0.4)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? color : AppColors.navy.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: active ? color : AppColors.navy.withOpacity(0.3)),
          ],
        ),
      ),
    );
  }
}

// ── Delete confirmation dialog ─────────────────────────────────

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
          color: const Color(0xFFFFFFFF),
          border: Border.all(color: AppColors.navy.withOpacity(0.12)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.warning_amber_rounded,
                color: AppColors.coral, size: 40),
            const SizedBox(height: 16),
            const Text('Delete Toggle',
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

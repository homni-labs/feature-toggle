import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feature_toggle_app/app/di/injection.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';
import 'package:feature_toggle_app/core/domain/failure.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/core/presentation/widgets/app_snackbar.dart';
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
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 48, color: Colors.white.withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            failure.message,
            style: TextStyle(
              fontSize: 16,
              color: Colors.white.withOpacity(0.5),
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

          // Filters
          _FiltersRow(
            filterEnabled: state.filterEnabled,
            filterEnvironment: state.filterEnvironment,
          ),
          const SizedBox(height: 16),

          // Toggle list
          Expanded(
            child: state.toggles.isEmpty
                ? const _EmptyState()
                : _ToggleList(
                    toggles: state.toggles,
                    canWrite: canWrite,
                  ),
          ),

          // Pagination
          if (state.totalPages > 1) ...[
            const SizedBox(height: 16),
            _Pagination(
              page: state.page,
              totalPages: state.totalPages,
            ),
          ],
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

// ── Toggle list ────────────────────────────────────────────────

class _ToggleList extends StatelessWidget {
  const _ToggleList({
    required this.toggles,
    required this.canWrite,
  });

  final List<FeatureToggle> toggles;
  final bool canWrite;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 700),
        child: ListView.builder(
          itemCount: toggles.length,
          itemBuilder: (BuildContext context, int index) {
            final FeatureToggle toggle = toggles[index];
            return ToggleCard(
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
            );
          },
        ),
      ),
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
              size: 64, color: Colors.white.withOpacity(0.15)),
          const SizedBox(height: 16),
          Text(
            'No toggles yet',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Create your first feature toggle',
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.25),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Filters row ────────────────────────────────────────────────

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
                color: Colors.white.withOpacity(0.06),
              ),
              child: Icon(Icons.filter_alt_off_rounded,
                  size: 16, color: Colors.white.withOpacity(0.4)),
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

// ── Pagination ─────────────────────────────────────────────────

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
        _PaginationArrow(
          icon: Icons.chevron_left_rounded,
          enabled: page > 0,
          onTap: () => _goToPage(context, page - 1),
        ),
        const SizedBox(width: 8),
        ...List.generate(totalPages, (int i) {
          final bool isActive = i == page;
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
                child: Text(
                  '${i + 1}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? AppColors.coral
                        : Colors.white.withOpacity(0.5),
                  ),
                ),
              ),
            ),
          );
        }),
        const SizedBox(width: 8),
        _PaginationArrow(
          icon: Icons.chevron_right_rounded,
          enabled: page < totalPages - 1,
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

    // Preserve current filters from cubit state
    final TogglesState togglesState = context.read<TogglesCubit>().state;
    bool? filterEnabled;
    String? filterEnvironment;
    if (togglesState is TogglesLoaded) {
      filterEnabled = togglesState.filterEnabled;
      filterEnvironment = togglesState.filterEnvironment;
    }

    final String? token = await authCubit.getValidAccessToken();
    if (token == null || !context.mounted) return;

    await context.read<TogglesCubit>().load(
          accessToken: token,
          projectId: projectId,
          page: targetPage,
          enabled: filterEnabled,
          environment: filterEnvironment,
        );
  }
}

// ── Create button ──────────────────────────────────────────────

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
              Text('New Toggle',
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

// ── Pagination arrow ───────────────────────────────────────────

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
      color: const Color(0xFF252848),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                  color: Colors.white.withOpacity(0.8),
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
              : Colors.white.withOpacity(0.06),
          border: Border.all(
            color: active
                ? color.withOpacity(0.3)
                : Colors.white.withOpacity(0.08),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 15,
                color: active ? color : Colors.white.withOpacity(0.4)),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w400,
                color: active ? color : Colors.white.withOpacity(0.5),
              ),
            ),
            const SizedBox(width: 6),
            Icon(Icons.keyboard_arrow_down_rounded,
                size: 16,
                color: active ? color : Colors.white.withOpacity(0.3)),
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
          color: const Color(0xFF1E2040),
          border: Border.all(color: Colors.white.withOpacity(0.12)),
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
                    color: Colors.white)),
            const SizedBox(height: 8),
            Text('Are you sure you want to delete "$name"?',
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

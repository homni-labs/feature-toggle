import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/toggles/application/bloc/toggles_state.dart';
import 'package:feature_toggle_app/features/toggles/application/usecase/create_toggle_usecase.dart';
import 'package:feature_toggle_app/features/toggles/application/usecase/delete_toggle_usecase.dart';
import 'package:feature_toggle_app/features/toggles/application/usecase/load_toggles_usecase.dart';
import 'package:feature_toggle_app/features/toggles/application/usecase/update_toggle_usecase.dart';
import 'package:feature_toggle_app/features/toggles/domain/model/feature_toggle.dart';

class TogglesCubit extends Cubit<TogglesState> {
  final LoadTogglesUseCase _loadToggles;
  final CreateToggleUseCase _createToggle;
  final UpdateToggleUseCase _updateToggle;
  final DeleteToggleUseCase _deleteToggle;

  static const _pageSize = 9;

  TogglesCubit({
    required LoadTogglesUseCase loadToggles,
    required CreateToggleUseCase createToggle,
    required UpdateToggleUseCase updateToggle,
    required DeleteToggleUseCase deleteToggle,
  })  : _loadToggles = loadToggles,
        _createToggle = createToggle,
        _updateToggle = updateToggle,
        _deleteToggle = deleteToggle,
        super(const TogglesInitial());

  Future<void> load({
    required String accessToken,
    required ProjectId projectId,
    int page = 0,
    bool? enabled,
    String? environment,
  }) async {
    emit(const TogglesLoading());
    final result = await _loadToggles(
      accessToken: accessToken,
      projectId: projectId,
      page: page,
      size: _pageSize,
      enabled: enabled,
      environment: environment,
    );
    result.fold(
      (f) => emit(TogglesError(f)),
      (paged) => emit(TogglesLoaded(
        toggles: paged.items,
        totalElements: paged.totalElements,
        page: paged.page,
        totalPages: paged.totalPages,
        filterEnabled: enabled,
        filterEnvironment: environment,
      )),
    );
  }

  Future<void> create({
    required String accessToken,
    required ProjectId projectId,
    required String name,
    String? description,
    required List<String> environments,
  }) async {
    final result = await _createToggle(
      accessToken: accessToken,
      projectId: projectId,
      name: name,
      description: description,
      environments: environments,
    );
    result.fold(
      (f) => emit(TogglesError(f)),
      (created) {
        final current = state;
        if (current is TogglesLoaded) {
          final list = [created, ...current.toggles];
          if (list.length > _pageSize) list.removeLast();
          emit(current.copyWith(
            toggles: list,
            totalElements: current.totalElements + 1,
            totalPages: ((current.totalElements + 1) / _pageSize).ceil(),
          ));
        }
      },
    );
  }

  Future<void> update({
    required String accessToken,
    required ProjectId projectId,
    required ToggleId toggleId,
    String? name,
    String? description,
    List<String>? environments,
    Map<String, bool>? environmentStates,
  }) async {
    final result = await _updateToggle(
      accessToken: accessToken,
      projectId: projectId,
      toggleId: toggleId,
      name: name,
      description: description,
      environments: environments,
      environmentStates: environmentStates,
    );
    result.fold(
      (f) => emit(TogglesError(f)),
      (updated) {
        final current = state;
        if (current is TogglesLoaded) {
          final list = current.toggles
              .map((t) => t.id == updated.id ? updated : t)
              .toList();
          emit(current.copyWith(toggles: list));
        }
      },
    );
  }

  /// Inline switch click on a single env. Optimistically flips the local
  /// state immediately so the UI feels instant, then sends the PATCH. On
  /// error, rolls back the local state and surfaces the failure.
  Future<void> setEnvironmentState({
    required String accessToken,
    required ProjectId projectId,
    required ToggleId toggleId,
    required String environmentName,
    required bool enabled,
  }) async {
    final current = state;
    if (current is! TogglesLoaded) return;

    // Snapshot the previous toggle so we can roll back on failure.
    FeatureToggle? previous;
    final optimistic = current.toggles.map((t) {
      if (t.id == toggleId) {
        previous = t;
        return t.withEnvState(environmentName, enabled);
      }
      return t;
    }).toList();
    if (previous == null) return;

    emit(current.copyWith(toggles: optimistic));

    final result = await _updateToggle(
      accessToken: accessToken,
      projectId: projectId,
      toggleId: toggleId,
      environmentStates: {environmentName: enabled},
    );
    result.fold(
      (f) {
        // Roll back: replace the optimistic version with the previous one,
        // then surface the error so the screen can snackbar.
        final rolledBack = (state is TogglesLoaded
                ? (state as TogglesLoaded).toggles
                : optimistic)
            .map((t) => t.id == toggleId ? previous! : t)
            .toList();
        if (state is TogglesLoaded) {
          emit((state as TogglesLoaded).copyWith(toggles: rolledBack));
        }
        emit(TogglesError(f));
      },
      (updated) {
        if (state is TogglesLoaded) {
          final list = (state as TogglesLoaded)
              .toggles
              .map((t) => t.id == updated.id ? updated : t)
              .toList();
          emit((state as TogglesLoaded).copyWith(toggles: list));
        }
      },
    );
  }

  Future<void> delete({
    required String accessToken,
    required ProjectId projectId,
    required ToggleId toggleId,
  }) async {
    final result = await _deleteToggle(
      accessToken: accessToken,
      projectId: projectId,
      toggleId: toggleId,
    );
    result.fold(
      (f) => emit(TogglesError(f)),
      (_) {
        final current = state;
        if (current is TogglesLoaded) {
          final list = current.toggles
              .where((t) => t.id != toggleId)
              .toList();
          emit(current.copyWith(
            toggles: list,
            totalElements: current.totalElements - 1,
            totalPages: (current.totalElements - 1) > 0
                ? ((current.totalElements - 1) / _pageSize).ceil()
                : 0,
          ));
        }
      },
    );
  }
}

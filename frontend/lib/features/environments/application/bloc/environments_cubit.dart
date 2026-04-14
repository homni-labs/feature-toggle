import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/features/environments/application/bloc/environments_state.dart';
import 'package:togli_app/features/environments/application/usecase/create_environment_usecase.dart';
import 'package:togli_app/features/environments/application/usecase/delete_environment_usecase.dart';
import 'package:togli_app/features/environments/application/usecase/load_environments_usecase.dart';

class EnvironmentsCubit extends Cubit<EnvironmentsState> {
  final LoadEnvironmentsUseCase _loadEnvironments;
  final CreateEnvironmentUseCase _createEnvironment;
  final DeleteEnvironmentUseCase _deleteEnvironment;

  static const _pageSize = 20;

  EnvironmentsCubit({
    required LoadEnvironmentsUseCase loadEnvironments,
    required CreateEnvironmentUseCase createEnvironment,
    required DeleteEnvironmentUseCase deleteEnvironment,
  })  : _loadEnvironments = loadEnvironments,
        _createEnvironment = createEnvironment,
        _deleteEnvironment = deleteEnvironment,
        super(const EnvironmentsInitial());

  Future<void> load({
    required String accessToken,
    required ProjectId projectId,
    int page = 0,
  }) async {
    emit(const EnvironmentsLoading());
    final result = await _loadEnvironments(
      accessToken: accessToken,
      projectId: projectId,
      page: page,
      size: _pageSize,
    );
    result.fold(
      (f) => emit(EnvironmentsError(f)),
      (paged) => emit(EnvironmentsLoaded(
        environments: paged.items,
        totalElements: paged.totalElements,
        page: paged.page,
        totalPages: paged.totalPages,
      )),
    );
  }

  Future<void> create({
    required String accessToken,
    required ProjectId projectId,
    required String name,
  }) async {
    final result = await _createEnvironment(
      accessToken: accessToken,
      projectId: projectId,
      name: name,
    );
    result.fold(
      (f) => emit(EnvironmentsError(f)),
      (created) {
        final current = state;
        if (current is EnvironmentsLoaded) {
          final list = [...current.environments, created]
            ..sort((a, b) => a.name.compareTo(b.name));
          if (list.length > _pageSize) list.removeLast();
          emit(current.copyWith(
            environments: list,
            totalElements: current.totalElements + 1,
            totalPages: ((current.totalElements + 1) / _pageSize).ceil(),
          ));
        }
      },
    );
  }

  Future<void> delete({
    required String accessToken,
    required ProjectId projectId,
    required EnvironmentId environmentId,
  }) async {
    final result = await _deleteEnvironment(
      accessToken: accessToken,
      projectId: projectId,
      environmentId: environmentId,
    );
    result.fold(
      (f) => emit(EnvironmentsError(f)),
      (_) {
        final current = state;
        if (current is EnvironmentsLoaded) {
          final list = current.environments
              .where((e) => e.id != environmentId)
              .toList();
          emit(current.copyWith(
            environments: list,
            totalElements: current.totalElements - 1,
            totalPages: (current.totalElements - 1) > 0
                ? ((current.totalElements - 1) / _pageSize).ceil()
                : 0,
          ));
        }
      },
    );
  }

  List<String> get environmentNames {
    final current = state;
    if (current is EnvironmentsLoaded) {
      return current.environments.map((e) => e.name).toList();
    }
    return [];
  }
}

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feature_toggle_app/features/projects/application/bloc/projects_state.dart';
import 'package:feature_toggle_app/features/projects/application/usecase/create_project_usecase.dart';
import 'package:feature_toggle_app/features/projects/application/usecase/load_projects_usecase.dart';
import 'package:feature_toggle_app/features/projects/application/usecase/update_project_usecase.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';

class ProjectsCubit extends Cubit<ProjectsState> {
  final LoadProjectsUseCase _loadProjects;
  final CreateProjectUseCase _createProject;
  final UpdateProjectUseCase _updateProject;

  ProjectsCubit({
    required LoadProjectsUseCase loadProjects,
    required CreateProjectUseCase createProject,
    required UpdateProjectUseCase updateProject,
  })  : _loadProjects = loadProjects,
        _createProject = createProject,
        _updateProject = updateProject,
        super(const ProjectsInitial());

  Future<void> load({required String accessToken}) async {
    emit(const ProjectsLoading());
    final result = await _loadProjects(accessToken: accessToken);
    result.fold(
      (f) => emit(ProjectsError(f)),
      (projects) => emit(ProjectsLoaded(projects)),
    );
  }

  Future<void> create({
    required String accessToken,
    required String slug,
    required String name,
    String? description,
  }) async {
    final result = await _createProject(
      accessToken: accessToken,
      slug: slug,
      name: name,
      description: description,
    );
    result.fold(
      (f) => emit(ProjectsError(f)),
      (created) {
        final current = state;
        if (current is ProjectsLoaded) {
          emit(ProjectsLoaded([created, ...current.projects]));
        }
      },
    );
  }

  Future<void> updateProject({
    required String accessToken,
    required ProjectId projectId,
    String? name,
    String? description,
    bool? archived,
  }) async {
    final result = await _updateProject(
      accessToken: accessToken,
      projectId: projectId,
      name: name,
      description: description,
      archived: archived,
    );
    result.fold(
      (f) => emit(ProjectsError(f)),
      (updated) {
        final current = state;
        if (current is ProjectsLoaded) {
          final list = current.projects
              .map((p) => p.id == updated.id ? updated : p)
              .toList();
          emit(ProjectsLoaded(list));
        }
      },
    );
  }
}

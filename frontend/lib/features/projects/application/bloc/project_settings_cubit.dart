import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feature_toggle_app/features/projects/application/bloc/project_settings_state.dart';
import 'package:feature_toggle_app/features/projects/application/usecase/update_project_usecase.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';

class ProjectSettingsCubit extends Cubit<ProjectSettingsState> {
  final UpdateProjectUseCase _updateProject;

  ProjectSettingsCubit({required UpdateProjectUseCase updateProject})
      : _updateProject = updateProject,
        super(const ProjectSettingsIdle());

  Future<void> save({
    required String accessToken,
    required ProjectId projectId,
    String? name,
    String? description,
  }) async {
    emit(const ProjectSettingsSaving());
    final result = await _updateProject(
      accessToken: accessToken,
      projectId: projectId,
      name: name,
      description: description,
    );
    result.fold(
      (f) => emit(ProjectSettingsError(f)),
      (project) => emit(ProjectSettingsSaved(project)),
    );
  }

  Future<void> toggleArchive({
    required String accessToken,
    required ProjectId projectId,
    required bool archived,
  }) async {
    emit(const ProjectSettingsSaving());
    final result = await _updateProject(
      accessToken: accessToken,
      projectId: projectId,
      archived: archived,
    );
    result.fold(
      (f) => emit(ProjectSettingsError(f)),
      (project) => emit(ProjectSettingsSaved(project)),
    );
  }
}

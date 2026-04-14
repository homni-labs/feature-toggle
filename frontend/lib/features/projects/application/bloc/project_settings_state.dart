import 'package:togli_app/core/domain/failure.dart';
import 'package:togli_app/features/projects/domain/model/project.dart';

sealed class ProjectSettingsState {
  const ProjectSettingsState();
}

class ProjectSettingsIdle extends ProjectSettingsState {
  const ProjectSettingsIdle();
}

class ProjectSettingsSaving extends ProjectSettingsState {
  const ProjectSettingsSaving();
}

class ProjectSettingsSaved extends ProjectSettingsState {
  final Project project;
  const ProjectSettingsSaved(this.project);
}

class ProjectSettingsError extends ProjectSettingsState {
  final Failure failure;
  const ProjectSettingsError(this.failure);
}

import 'package:feature_toggle_app/core/domain/failure.dart';
import 'package:feature_toggle_app/features/projects/domain/model/project.dart';

sealed class ProjectsState {
  const ProjectsState();
}

class ProjectsInitial extends ProjectsState {
  const ProjectsInitial();
}

class ProjectsLoading extends ProjectsState {
  const ProjectsLoading();
}

class ProjectsLoaded extends ProjectsState {
  final List<Project> projects;
  const ProjectsLoaded(this.projects);
}

class ProjectsError extends ProjectsState {
  final Failure failure;
  const ProjectsError(this.failure);
}

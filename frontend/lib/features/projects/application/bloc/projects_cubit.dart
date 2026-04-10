import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/projects/application/bloc/projects_state.dart';
import 'package:feature_toggle_app/features/projects/application/usecase/create_project_usecase.dart';
import 'package:feature_toggle_app/features/projects/application/usecase/load_projects_usecase.dart';
import 'package:feature_toggle_app/features/projects/application/usecase/update_project_usecase.dart';
import 'package:feature_toggle_app/features/projects/domain/model/project.dart';

class ProjectsCubit extends Cubit<ProjectsState> {
  final LoadProjectsUseCase _loadProjects;
  final CreateProjectUseCase _createProject;
  final UpdateProjectUseCase _updateProject;

  static const _pageSize = 6;

  ProjectsCubit({
    required LoadProjectsUseCase loadProjects,
    required CreateProjectUseCase createProject,
    required UpdateProjectUseCase updateProject,
  })  : _loadProjects = loadProjects,
        _createProject = createProject,
        _updateProject = updateProject,
        super(const ProjectsInitial());

  /// Loads a page of projects with the given filters. The cubit always emits
  /// [ProjectsLoading] before delegating to the repository so the screen can
  /// show a spinner; on success it lands on [ProjectsLoaded] carrying the
  /// active filters so subsequent pagination clicks can preserve them.
  Future<void> load({
    required String accessToken,
    int page = 0,
    String? searchText,
    bool? archived,
  }) async {
    emit(const ProjectsLoading());
    final result = await _loadProjects(
      accessToken: accessToken,
      page: page,
      size: _pageSize,
      searchText: searchText,
      archived: archived,
    );
    result.fold(
      (f) => emit(ProjectsError(f)),
      (ProjectsPage paged) => emit(ProjectsLoaded(
        projects: paged.items,
        totalElements: paged.totalElements,
        page: paged.page,
        totalPages: paged.totalPages,
        totalCount: paged.totalCount,
        archivedCount: paged.archivedCount,
        searchText: searchText,
        archivedFilter: archived,
      )),
    );
  }

  /// Updates the search text and reloads from page 0 with the new filter.
  /// Pass `null` (or empty) to clear the search.
  Future<void> setSearch({
    required String accessToken,
    String? searchText,
  }) async {
    final current = state;
    final bool? archived =
        current is ProjectsLoaded ? current.archivedFilter : null;
    await load(
      accessToken: accessToken,
      page: 0,
      searchText: searchText,
      archived: archived,
    );
  }

  /// Switches the archived filter (null = both, true = only archived, false =
  /// only active) and reloads from page 0.
  Future<void> setArchivedFilter({
    required String accessToken,
    required bool? archived,
  }) async {
    final current = state;
    final String? searchText =
        current is ProjectsLoaded ? current.searchText : null;
    await load(
      accessToken: accessToken,
      page: 0,
      searchText: searchText,
      archived: archived,
    );
  }

  /// Navigates to a specific page while preserving the current filters.
  Future<void> goToPage({
    required String accessToken,
    required int page,
  }) async {
    final current = state;
    if (current is! ProjectsLoaded) return;
    await load(
      accessToken: accessToken,
      page: page,
      searchText: current.searchText,
      archived: current.archivedFilter,
    );
  }

  Future<void> create({
    required String accessToken,
    required String slug,
    required String name,
    String? description,
    List<String>? environments,
  }) async {
    final result = await _createProject(
      accessToken: accessToken,
      slug: slug,
      name: name,
      description: description,
      environments: environments,
    );
    result.fold(
      (f) => emit(ProjectsError(f)),
      (_) {
        // Reload from page 0 so the new project appears with real
        // server-computed counts (togglesCount, environmentsCount,
        // membersCount). The single-project POST response doesn't
        // carry aggregates, so an optimistic local insert would show
        // all counts as 0 — which is confusing ("envs not saved").
        final current = state;
        load(
          accessToken: accessToken,
          page: 0,
          searchText: current is ProjectsLoaded ? current.searchText : null,
          archived: current is ProjectsLoaded ? current.archivedFilter : null,
        );
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
          // Archive flips affect the workspace-wide archived count.
          int newArchivedCount = current.archivedCount;
          if (archived == true) newArchivedCount++;
          if (archived == false) newArchivedCount--;
          emit(current.copyWith(
            projects: list,
            archivedCount: newArchivedCount,
          ));
        }
      },
    );
  }
}

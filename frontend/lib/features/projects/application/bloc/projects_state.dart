import 'package:togli_app/core/domain/failure.dart';
import 'package:togli_app/features/projects/domain/model/project.dart';

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

  /// Number of items matching the active filters (drives pagination).
  final int totalElements;
  final int page;
  final int totalPages;

  /// Workspace-wide visible totals (independent of active filters), used by
  /// the page header subtitle.
  final int totalCount;
  final int archivedCount;

  /// Active filter state — kept here so pagination clicks and refreshes
  /// preserve the user's selection.
  final String? searchText;
  final bool? archivedFilter;

  const ProjectsLoaded({
    required this.projects,
    required this.totalElements,
    required this.page,
    required this.totalPages,
    required this.totalCount,
    required this.archivedCount,
    this.searchText,
    this.archivedFilter,
  });

  ProjectsLoaded copyWith({
    List<Project>? projects,
    int? totalElements,
    int? page,
    int? totalPages,
    int? totalCount,
    int? archivedCount,
    String? searchText,
    bool? archivedFilter,
    bool clearSearch = false,
    bool clearArchivedFilter = false,
  }) {
    return ProjectsLoaded(
      projects: projects ?? this.projects,
      totalElements: totalElements ?? this.totalElements,
      page: page ?? this.page,
      totalPages: totalPages ?? this.totalPages,
      totalCount: totalCount ?? this.totalCount,
      archivedCount: archivedCount ?? this.archivedCount,
      searchText: clearSearch ? null : (searchText ?? this.searchText),
      archivedFilter:
          clearArchivedFilter ? null : (archivedFilter ?? this.archivedFilter),
    );
  }
}

class ProjectsError extends ProjectsState {
  final Failure failure;
  const ProjectsError(this.failure);
}

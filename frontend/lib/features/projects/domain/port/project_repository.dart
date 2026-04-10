import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/projects/domain/model/project.dart';

abstract class ProjectRepository {
  /// Returns a page of projects visible to the caller. Filters compose:
  /// - [searchText] case-insensitive substring against name and slug
  /// - [archived] tri-state — null (both), true (only archived), false (only active)
  /// - [page] / [size] zero-based pagination
  ///
  /// The returned [ProjectsPage] also carries workspace-wide subtitle counters
  /// ([ProjectsPage.totalCount] / [ProjectsPage.archivedCount]) that ignore
  /// the active filters and let the page header stay stable when the user
  /// searches or switches between All / Archived.
  FutureEither<ProjectsPage> getAll({
    required String accessToken,
    String? searchText,
    bool? archived,
    int page = 0,
    int size = 6,
  });

  /// Creates a project. The optional [environments] parameter selects which
  /// platform-default environments to bootstrap inside the new project:
  /// `null` means "use all configured defaults" (backward compat),
  /// an empty list means "create no environments at all" (explicit opt-out),
  /// and a non-empty list bootstraps exactly the listed names (each must be
  /// in the platform's configured defaults — otherwise the backend rejects).
  FutureEither<Project> create({
    required String accessToken,
    required String slug,
    required String name,
    String? description,
    List<String>? environments,
  });

  FutureEither<Project> update({
    required String accessToken,
    required ProjectId projectId,
    String? name,
    String? description,
    bool? archived,
  });
}

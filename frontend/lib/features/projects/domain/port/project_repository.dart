import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/projects/domain/model/project.dart';

abstract class ProjectRepository {
  FutureEither<List<Project>> getAll({required String accessToken});

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

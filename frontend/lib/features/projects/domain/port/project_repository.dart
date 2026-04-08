import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/projects/domain/model/project.dart';

abstract class ProjectRepository {
  FutureEither<List<Project>> getAll({required String accessToken});

  FutureEither<Project> create({
    required String accessToken,
    required String slug,
    required String name,
    String? description,
  });

  FutureEither<Project> update({
    required String accessToken,
    required ProjectId projectId,
    String? name,
    String? description,
    bool? archived,
  });
}

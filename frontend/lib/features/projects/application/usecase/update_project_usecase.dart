import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/projects/domain/model/project.dart';
import 'package:feature_toggle_app/features/projects/domain/port/project_repository.dart';

class UpdateProjectUseCase {
  final ProjectRepository _repo;
  const UpdateProjectUseCase(this._repo);

  FutureEither<Project> call({
    required String accessToken,
    required ProjectId projectId,
    String? name,
    String? description,
    bool? archived,
  }) {
    return _repo.update(
      accessToken: accessToken,
      projectId: projectId,
      name: name,
      description: description,
      archived: archived,
    );
  }
}

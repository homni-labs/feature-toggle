import 'package:togli_app/core/domain/typedefs.dart';
import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/features/environments/domain/port/environment_repository.dart';

class DeleteEnvironmentUseCase {
  final EnvironmentRepository _repo;
  const DeleteEnvironmentUseCase(this._repo);

  FutureEither<void> call({
    required String accessToken,
    required ProjectId projectId,
    required EnvironmentId environmentId,
  }) {
    return _repo.delete(
      accessToken: accessToken,
      projectId: projectId,
      environmentId: environmentId,
    );
  }
}

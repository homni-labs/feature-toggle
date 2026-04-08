import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/environments/domain/model/environment.dart';
import 'package:feature_toggle_app/features/environments/domain/port/environment_repository.dart';

class CreateEnvironmentUseCase {
  final EnvironmentRepository _repo;
  const CreateEnvironmentUseCase(this._repo);

  FutureEither<Environment> call({
    required String accessToken,
    required ProjectId projectId,
    required String name,
  }) {
    return _repo.create(
      accessToken: accessToken,
      projectId: projectId,
      name: name,
    );
  }
}

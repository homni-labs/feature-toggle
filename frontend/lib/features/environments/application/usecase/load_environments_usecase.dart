import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/environments/domain/model/environment.dart';
import 'package:feature_toggle_app/features/environments/domain/port/environment_repository.dart';

class LoadEnvironmentsUseCase {
  final EnvironmentRepository _repo;
  const LoadEnvironmentsUseCase(this._repo);

  FutureEither<List<Environment>> call({
    required String accessToken,
    required ProjectId projectId,
  }) {
    return _repo.getAll(accessToken: accessToken, projectId: projectId);
  }
}

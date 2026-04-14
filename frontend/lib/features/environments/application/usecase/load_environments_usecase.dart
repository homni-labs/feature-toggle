import 'package:togli_app/core/domain/typedefs.dart';
import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/features/environments/domain/port/environment_repository.dart';

class LoadEnvironmentsUseCase {
  final EnvironmentRepository _repo;
  const LoadEnvironmentsUseCase(this._repo);

  FutureEither<PagedEnvironments> call({
    required String accessToken,
    required ProjectId projectId,
    int page = 0,
    int size = 20,
  }) {
    return _repo.getAll(
      accessToken: accessToken,
      projectId: projectId,
      page: page,
      size: size,
    );
  }
}

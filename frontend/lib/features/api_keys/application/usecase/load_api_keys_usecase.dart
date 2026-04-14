import 'package:togli_app/core/domain/typedefs.dart';
import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/features/api_keys/domain/port/api_key_repository.dart';

class LoadApiKeysUseCase {
  final ApiKeyRepository _repo;
  const LoadApiKeysUseCase(this._repo);

  FutureEither<PagedApiKeys> call({
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

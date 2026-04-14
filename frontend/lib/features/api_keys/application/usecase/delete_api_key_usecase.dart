import 'package:togli_app/core/domain/typedefs.dart';
import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/features/api_keys/domain/port/api_key_repository.dart';

class DeleteApiKeyUseCase {
  final ApiKeyRepository _repo;
  const DeleteApiKeyUseCase(this._repo);

  FutureEither<void> call({
    required String accessToken,
    required ProjectId projectId,
    required ApiKeyId apiKeyId,
  }) {
    return _repo.delete(
      accessToken: accessToken,
      projectId: projectId,
      apiKeyId: apiKeyId,
    );
  }
}

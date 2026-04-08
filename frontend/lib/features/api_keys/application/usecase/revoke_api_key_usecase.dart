import 'package:feature_toggle_app/core/domain/typedefs.dart';
import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/api_keys/domain/port/api_key_repository.dart';

class RevokeApiKeyUseCase {
  final ApiKeyRepository _repo;
  const RevokeApiKeyUseCase(this._repo);

  FutureEither<void> call({
    required String accessToken,
    required ProjectId projectId,
    required ApiKeyId apiKeyId,
  }) {
    return _repo.revoke(
      accessToken: accessToken,
      projectId: projectId,
      apiKeyId: apiKeyId,
    );
  }
}

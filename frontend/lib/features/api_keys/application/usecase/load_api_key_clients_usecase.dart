import 'package:togli_app/core/domain/typedefs.dart';
import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/features/api_keys/domain/model/api_key_client.dart';
import 'package:togli_app/features/api_keys/domain/port/api_key_repository.dart';

class LoadApiKeyClientsUseCase {
  final ApiKeyRepository _repository;

  const LoadApiKeyClientsUseCase(this._repository);

  FutureEither<List<ApiKeyClient>> call({
    required String accessToken,
    required ProjectId projectId,
    required ApiKeyId apiKeyId,
  }) {
    return _repository.getClients(
      accessToken: accessToken,
      projectId: projectId,
      apiKeyId: apiKeyId,
    );
  }
}

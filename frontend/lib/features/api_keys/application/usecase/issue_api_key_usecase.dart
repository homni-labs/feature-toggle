import 'package:togli_app/core/domain/typedefs.dart';
import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/features/api_keys/domain/model/api_key.dart';
import 'package:togli_app/features/api_keys/domain/port/api_key_repository.dart';

class IssueApiKeyUseCase {
  final ApiKeyRepository _repo;
  const IssueApiKeyUseCase(this._repo);

  FutureEither<ApiKeyCreated> call({
    required String accessToken,
    required ProjectId projectId,
    required String name,
    String? expiresAt,
  }) {
    return _repo.issue(
      accessToken: accessToken,
      projectId: projectId,
      name: name,
      expiresAt: expiresAt,
    );
  }
}

import 'package:togli_app/core/domain/typedefs.dart';
import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/features/api_keys/domain/model/api_key.dart';
import 'package:togli_app/features/api_keys/domain/model/api_key_client.dart';

class PagedApiKeys {
  final List<ApiKey> items;
  final int totalElements;
  final int page;
  final int size;
  final int totalPages;

  const PagedApiKeys({
    required this.items,
    required this.totalElements,
    required this.page,
    required this.size,
    required this.totalPages,
  });
}

abstract class ApiKeyRepository {
  FutureEither<PagedApiKeys> getAll({
    required String accessToken,
    required ProjectId projectId,
    int page = 0,
    int size = 20,
  });

  FutureEither<ApiKeyCreated> issue({
    required String accessToken,
    required ProjectId projectId,
    required String name,
    String? expiresAt,
  });

  FutureEither<void> revoke({
    required String accessToken,
    required ProjectId projectId,
    required ApiKeyId apiKeyId,
  });

  FutureEither<void> delete({
    required String accessToken,
    required ProjectId projectId,
    required ApiKeyId apiKeyId,
  });

  FutureEither<List<ApiKeyClient>> getClients({
    required String accessToken,
    required ProjectId projectId,
    required ApiKeyId apiKeyId,
  });
}

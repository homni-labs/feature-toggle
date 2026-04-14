import 'package:togli_app/features/api_keys/domain/model/api_key_client.dart';
import 'package:togli_app/features/api_keys/infrastructure/dto/api_key_client_dto.dart';

class ApiKeyClientMapper {
  static ApiKeyClient toDomain(ApiKeyClientDto dto) {
    return ApiKeyClient(
      id: dto.id,
      apiKeyId: dto.apiKeyId,
      clientType: dto.clientType == 'SDK' ? ClientType.sdk : ClientType.rest,
      sdkName: dto.sdkName,
      serviceName: dto.serviceName,
      namespace: dto.namespace,
      firstSeenAt: DateTime.parse(dto.firstSeenAt),
      lastSeenAt: DateTime.parse(dto.lastSeenAt),
      requestCount: dto.requestCount,
    );
  }
}

import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/core/domain/value_objects/project_role.dart';
import 'package:togli_app/features/api_keys/domain/model/api_key.dart';
import 'package:togli_app/features/api_keys/infrastructure/dto/api_key_dto.dart';

class ApiKeyMapper {
  ApiKey toDomain(ApiKeyDto dto) {
    return ApiKey(
      id: ApiKeyId(dto.id),
      projectId: ProjectId(dto.projectId),
      projectName: dto.projectName,
      name: dto.name,
      role: ProjectRole.from(dto.role),
      maskedToken: dto.maskedToken,
      active: dto.active,
      createdAt: DateTime.parse(dto.createdAt),
      expiresAt: dto.expiresAt != null ? DateTime.parse(dto.expiresAt!) : null,
    );
  }

  ApiKeyCreated createdToDomain(ApiKeyCreatedDto dto) {
    return ApiKeyCreated(
      id: ApiKeyId(dto.id),
      name: dto.name,
      projectName: dto.projectName,
      rawToken: dto.rawToken,
      createdAt: DateTime.parse(dto.createdAt),
      expiresAt: dto.expiresAt != null ? DateTime.parse(dto.expiresAt!) : null,
    );
  }
}

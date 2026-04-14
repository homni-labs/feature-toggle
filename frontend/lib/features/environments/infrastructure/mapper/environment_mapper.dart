import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/features/environments/domain/model/environment.dart';
import 'package:togli_app/features/environments/infrastructure/dto/environment_dto.dart';

class EnvironmentMapper {
  Environment toDomain(EnvironmentDto dto) {
    return Environment(
      id: EnvironmentId(dto.id),
      projectId: ProjectId(dto.projectId),
      name: dto.name,
      createdAt: DateTime.parse(dto.createdAt),
    );
  }
}

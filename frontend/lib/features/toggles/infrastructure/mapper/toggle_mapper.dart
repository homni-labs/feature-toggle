import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/toggles/domain/model/feature_toggle.dart';
import 'package:feature_toggle_app/features/toggles/infrastructure/dto/feature_toggle_dto.dart';

class ToggleMapper {
  FeatureToggle toDomain(FeatureToggleDto dto) {
    return FeatureToggle(
      id: ToggleId(dto.id),
      projectId: ProjectId(dto.projectId),
      name: dto.name,
      description: dto.description,
      enabled: dto.enabled,
      environments: List.unmodifiable(dto.environments),
      createdAt: DateTime.parse(dto.createdAt),
      updatedAt: dto.updatedAt != null ? DateTime.parse(dto.updatedAt!) : null,
    );
  }
}

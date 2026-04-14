import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/features/toggles/domain/model/feature_toggle.dart';
import 'package:togli_app/features/toggles/domain/model/toggle_environment.dart';
import 'package:togli_app/features/toggles/infrastructure/dto/feature_toggle_dto.dart';

class ToggleMapper {
  FeatureToggle toDomain(FeatureToggleDto dto) {
    return FeatureToggle(
      id: ToggleId(dto.id),
      projectId: ProjectId(dto.projectId),
      name: dto.name,
      description: dto.description,
      environments: List.unmodifiable(
        dto.environments.map(
          (e) => ToggleEnvironment(name: e.name, enabled: e.enabled),
        ),
      ),
      createdAt: DateTime.parse(dto.createdAt),
      updatedAt: dto.updatedAt != null ? DateTime.parse(dto.updatedAt!) : null,
    );
  }
}

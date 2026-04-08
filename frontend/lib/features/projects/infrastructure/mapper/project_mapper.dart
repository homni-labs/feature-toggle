import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/core/domain/value_objects/project_role.dart';
import 'package:feature_toggle_app/core/domain/value_objects/slug.dart';
import 'package:feature_toggle_app/features/projects/domain/model/project.dart';
import 'package:feature_toggle_app/features/projects/infrastructure/dto/project_dto.dart';

class ProjectMapper {
  Project toDomain(ProjectDto dto) {
    return Project(
      id: ProjectId(dto.id),
      slug: Slug(dto.slug),
      name: dto.name,
      description: dto.description,
      archived: dto.archived,
      createdAt: DateTime.parse(dto.createdAt),
      updatedAt: dto.updatedAt != null ? DateTime.parse(dto.updatedAt!) : null,
      myRole: dto.myRole != null ? ProjectRole.from(dto.myRole!) : null,
    );
  }
}

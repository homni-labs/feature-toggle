import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/core/domain/value_objects/project_role.dart';
import 'package:togli_app/features/members/domain/model/project_membership.dart';
import 'package:togli_app/features/members/infrastructure/dto/project_membership_dto.dart';

class MembershipMapper {
  ProjectMembership toDomain(ProjectMembershipDto dto) {
    return ProjectMembership(
      id: MembershipId(dto.id),
      projectId: ProjectId(dto.projectId),
      userId: UserId(dto.userId),
      role: ProjectRole.from(dto.role),
      email: dto.email,
      name: dto.name,
      grantedAt: DateTime.parse(dto.grantedAt),
      updatedAt: dto.updatedAt != null ? DateTime.parse(dto.updatedAt!) : null,
    );
  }
}

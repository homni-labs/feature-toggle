import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/core/domain/value_objects/project_role.dart';

class ProjectMembership {
  final MembershipId id;
  final ProjectId projectId;
  final UserId userId;
  final ProjectRole role;
  final String? email;
  final String? name;
  final DateTime grantedAt;
  final DateTime? updatedAt;

  const ProjectMembership({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.role,
    this.email,
    this.name,
    required this.grantedAt,
    this.updatedAt,
  });

  String get displayName => name ?? email ?? userId.value;
  String get roleLabel => role.label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ProjectMembership && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

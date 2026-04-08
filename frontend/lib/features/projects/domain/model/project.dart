import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/core/domain/value_objects/slug.dart';
import 'package:feature_toggle_app/core/domain/value_objects/project_role.dart';

class Project {
  final ProjectId id;
  final Slug slug;
  final String name;
  final String? description;
  final bool archived;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final ProjectRole? myRole;

  const Project({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    required this.archived,
    required this.createdAt,
    this.updatedAt,
    this.myRole,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Project && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

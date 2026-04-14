import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/core/domain/value_objects/project_role.dart';
import 'package:togli_app/core/domain/value_objects/slug.dart';

class Project {
  final ProjectId id;
  final Slug slug;
  final String name;
  final String? description;
  final bool archived;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final ProjectRole? myRole;
  final int togglesCount;
  final int environmentsCount;
  final int membersCount;

  const Project({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    required this.archived,
    required this.createdAt,
    this.updatedAt,
    this.myRole,
    this.togglesCount = 0,
    this.environmentsCount = 0,
    this.membersCount = 0,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Project && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Result of a paged projects query: the matching items together with the
/// pagination envelope and the workspace-wide subtitle counters that are
/// independent of the active filters.
class ProjectsPage {
  final List<Project> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final int totalCount;
  final int archivedCount;

  const ProjectsPage({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.totalCount,
    required this.archivedCount,
  });
}

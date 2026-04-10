class ProjectDto {
  final String id;
  final String slug;
  final String name;
  final String? description;
  final bool archived;
  final String createdAt;
  final String? updatedAt;
  final String? myRole;
  final int togglesCount;
  final int environmentsCount;
  final int membersCount;

  const ProjectDto({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    required this.archived,
    required this.createdAt,
    this.updatedAt,
    this.myRole,
    required this.togglesCount,
    required this.environmentsCount,
    required this.membersCount,
  });

  factory ProjectDto.fromJson(Map<String, dynamic> json) {
    return ProjectDto(
      id: json['id'] as String,
      slug: json['slug'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      archived: json['archived'] as bool,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String?,
      myRole: json['myRole'] as String?,
      togglesCount: (json['togglesCount'] as num).toInt(),
      environmentsCount: (json['environmentsCount'] as num).toInt(),
      membersCount: (json['membersCount'] as num).toInt(),
    );
  }
}

/// Wraps the GET /projects response: paginated list of projects together with
/// the workspace-wide subtitle counts (totalCount / archivedCount) that are
/// independent of the active filters.
class ProjectsPageDto {
  final List<ProjectDto> items;
  final int page;
  final int size;
  final int totalElements;
  final int totalPages;
  final int totalCount;
  final int archivedCount;

  const ProjectsPageDto({
    required this.items,
    required this.page,
    required this.size,
    required this.totalElements,
    required this.totalPages,
    required this.totalCount,
    required this.archivedCount,
  });

  factory ProjectsPageDto.fromJson(Map<String, dynamic> json) {
    final payload = json['payload'] as List<dynamic>;
    final pagination = json['pagination'] as Map<String, dynamic>;
    return ProjectsPageDto(
      items: payload
          .map((e) => ProjectDto.fromJson(e as Map<String, dynamic>))
          .toList(),
      page: pagination['page'] as int,
      size: pagination['size'] as int,
      totalElements: (pagination['totalElements'] as num).toInt(),
      totalPages: pagination['totalPages'] as int,
      totalCount: (json['totalCount'] as num).toInt(),
      archivedCount: (json['archivedCount'] as num).toInt(),
    );
  }
}

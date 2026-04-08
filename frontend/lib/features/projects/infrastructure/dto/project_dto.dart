class ProjectDto {
  final String id;
  final String slug;
  final String name;
  final String? description;
  final bool archived;
  final String createdAt;
  final String? updatedAt;
  final String? myRole;

  const ProjectDto({
    required this.id,
    required this.slug,
    required this.name,
    this.description,
    required this.archived,
    required this.createdAt,
    this.updatedAt,
    this.myRole,
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
    );
  }
}

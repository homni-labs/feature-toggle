class ProjectMembershipDto {
  final String id;
  final String projectId;
  final String userId;
  final String role;
  final String? email;
  final String? name;
  final String grantedAt;
  final String? updatedAt;

  const ProjectMembershipDto({
    required this.id,
    required this.projectId,
    required this.userId,
    required this.role,
    this.email,
    this.name,
    required this.grantedAt,
    this.updatedAt,
  });

  factory ProjectMembershipDto.fromJson(Map<String, dynamic> json) {
    return ProjectMembershipDto(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      userId: json['userId'] as String,
      role: json['role'] as String,
      email: json['email'] as String?,
      name: json['name'] as String?,
      grantedAt: json['grantedAt'] as String,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

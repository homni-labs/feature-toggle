class EnvironmentDto {
  final String id;
  final String projectId;
  final String name;
  final String createdAt;

  const EnvironmentDto({
    required this.id,
    required this.projectId,
    required this.name,
    required this.createdAt,
  });

  factory EnvironmentDto.fromJson(Map<String, dynamic> json) {
    return EnvironmentDto(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      createdAt: json['createdAt'] as String,
    );
  }
}

class FeatureToggleDto {
  final String id;
  final String projectId;
  final String name;
  final String description;
  final bool enabled;
  final List<String> environments;
  final String createdAt;
  final String? updatedAt;

  const FeatureToggleDto({
    required this.id,
    required this.projectId,
    required this.name,
    this.description = '',
    required this.enabled,
    this.environments = const [],
    required this.createdAt,
    this.updatedAt,
  });

  factory FeatureToggleDto.fromJson(Map<String, dynamic> json) {
    return FeatureToggleDto(
      id: json['id'] as String,
      projectId: json['projectId'] as String,
      name: json['name'] as String,
      description: json['description'] as String? ?? '',
      enabled: json['enabled'] as bool,
      environments: (json['environments'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

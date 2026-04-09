class ToggleEnvironmentDto {
  final String name;
  final bool enabled;

  const ToggleEnvironmentDto({required this.name, required this.enabled});

  factory ToggleEnvironmentDto.fromJson(Map<String, dynamic> json) {
    return ToggleEnvironmentDto(
      name: json['name'] as String,
      enabled: json['enabled'] as bool,
    );
  }
}

class FeatureToggleDto {
  final String id;
  final String projectId;
  final String name;
  final String description;
  final List<ToggleEnvironmentDto> environments;
  final String createdAt;
  final String? updatedAt;

  const FeatureToggleDto({
    required this.id,
    required this.projectId,
    required this.name,
    this.description = '',
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
      environments: (json['environments'] as List<dynamic>?)
              ?.map((e) =>
                  ToggleEnvironmentDto.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

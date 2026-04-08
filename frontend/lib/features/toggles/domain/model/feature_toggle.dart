import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';

class FeatureToggle {
  final ToggleId id;
  final ProjectId projectId;
  final String name;
  final String description;
  final bool enabled;
  final List<String> environments;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FeatureToggle({
    required this.id,
    required this.projectId,
    required this.name,
    this.description = '',
    this.enabled = false,
    this.environments = const [],
    required this.createdAt,
    this.updatedAt,
  });

  FeatureToggle copyWith({
    String? name,
    String? description,
    bool? enabled,
    List<String>? environments,
    DateTime? updatedAt,
  }) {
    return FeatureToggle(
      id: id,
      projectId: projectId,
      name: name ?? this.name,
      description: description ?? this.description,
      enabled: enabled ?? this.enabled,
      environments: environments ?? this.environments,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is FeatureToggle && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

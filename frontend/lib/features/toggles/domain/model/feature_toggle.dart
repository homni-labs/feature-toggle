import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/features/toggles/domain/model/toggle_environment.dart';

class FeatureToggle {
  final ToggleId id;
  final ProjectId projectId;
  final String name;
  final String description;
  final List<ToggleEnvironment> environments;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const FeatureToggle({
    required this.id,
    required this.projectId,
    required this.name,
    this.description = '',
    this.environments = const [],
    required this.createdAt,
    this.updatedAt,
  });

  /// Convenience: env names without the state, useful for the dialog selector
  /// and for the existing flutter UI bits that just need a list of strings.
  List<String> get environmentNames =>
      environments.map((e) => e.name).toList(growable: false);

  /// Whether the toggle is enabled in the given env. Returns `false` for envs
  /// the toggle is not assigned to (matches backend semantics).
  bool isEnabledIn(String envName) {
    for (final env in environments) {
      if (env.name == envName) return env.enabled;
    }
    return false;
  }

  /// Replaces the state of a single env without touching the others. Used by
  /// the cubit for optimistic updates.
  FeatureToggle withEnvState(String envName, bool enabled) {
    final updated = environments
        .map((e) => e.name == envName ? e.copyWith(enabled: enabled) : e)
        .toList(growable: false);
    return copyWith(environments: updated);
  }

  FeatureToggle copyWith({
    String? name,
    String? description,
    List<ToggleEnvironment>? environments,
    DateTime? updatedAt,
  }) {
    return FeatureToggle(
      id: id,
      projectId: projectId,
      name: name ?? this.name,
      description: description ?? this.description,
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

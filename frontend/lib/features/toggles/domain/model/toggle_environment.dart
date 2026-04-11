/// Per-environment state of a feature toggle: the env name plus the
/// independent enabled flag for that env.
class ToggleEnvironment {
  final String name;
  final bool enabled;

  const ToggleEnvironment({
    required this.name,
    required this.enabled,
  });

  ToggleEnvironment copyWith({bool? enabled}) {
    return ToggleEnvironment(
      name: name,
      enabled: enabled ?? this.enabled,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ToggleEnvironment &&
          name == other.name &&
          enabled == other.enabled;

  @override
  int get hashCode => Object.hash(name, enabled);
}

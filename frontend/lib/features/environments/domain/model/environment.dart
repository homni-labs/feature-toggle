import 'package:togli_app/core/domain/value_objects/entity_id.dart';

class Environment {
  final EnvironmentId id;
  final ProjectId projectId;
  final String name;
  final DateTime createdAt;

  const Environment({
    required this.id,
    required this.projectId,
    required this.name,
    required this.createdAt,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is Environment && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

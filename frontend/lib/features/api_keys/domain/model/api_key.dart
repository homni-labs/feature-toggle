import 'package:togli_app/core/domain/value_objects/entity_id.dart';
import 'package:togli_app/core/domain/value_objects/project_role.dart';

class ApiKey {
  final ApiKeyId id;
  final ProjectId projectId;
  final String? projectName;
  final String name;
  final ProjectRole role;
  final String maskedToken;
  final bool active;
  final DateTime createdAt;
  final DateTime? expiresAt;
  final DateTime? lastUsedAt;
  final int? clientCount;

  const ApiKey({
    required this.id,
    required this.projectId,
    this.projectName,
    required this.name,
    required this.role,
    required this.maskedToken,
    required this.active,
    required this.createdAt,
    this.expiresAt,
    this.lastUsedAt,
    this.clientCount,
  });

  String get roleLabel => role.label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is ApiKey && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

class ApiKeyCreated {
  final ApiKeyId id;
  final String name;
  final String? projectName;
  final String rawToken;
  final DateTime createdAt;
  final DateTime? expiresAt;

  const ApiKeyCreated({
    required this.id,
    required this.name,
    this.projectName,
    required this.rawToken,
    required this.createdAt,
    this.expiresAt,
  });
}

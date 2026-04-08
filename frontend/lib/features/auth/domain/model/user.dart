import 'package:feature_toggle_app/core/domain/value_objects/entity_id.dart';
import 'package:feature_toggle_app/core/domain/value_objects/email.dart';
import 'package:feature_toggle_app/core/domain/value_objects/platform_role.dart';

class User {
  final UserId id;
  final String? oidcSubject;
  final Email email;
  final String? name;
  final PlatformRole platformRole;
  final bool active;
  final DateTime createdAt;
  final DateTime? updatedAt;

  const User({
    required this.id,
    this.oidcSubject,
    required this.email,
    this.name,
    required this.platformRole,
    required this.active,
    required this.createdAt,
    this.updatedAt,
  });

  bool get isPlatformAdmin => platformRole.isAdmin;
  String get displayName => name ?? email.value;
  String get roleLabel => platformRole.label;

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is User && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

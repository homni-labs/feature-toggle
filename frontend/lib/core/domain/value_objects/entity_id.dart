class EntityId {
  final String value;

  const EntityId(this.value) : assert(value != '');

  EntityId.validated(String raw) : value = raw {
    if (raw.isEmpty) {
      throw ArgumentError('ID must not be empty');
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) || other is EntityId && value == other.value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

class UserId extends EntityId {
  const UserId(super.value);
}

class ProjectId extends EntityId {
  const ProjectId(super.value);
}

class ToggleId extends EntityId {
  const ToggleId(super.value);
}

class EnvironmentId extends EntityId {
  const EnvironmentId(super.value);
}

class MembershipId extends EntityId {
  const MembershipId(super.value);
}

class ApiKeyId extends EntityId {
  const ApiKeyId(super.value);
}

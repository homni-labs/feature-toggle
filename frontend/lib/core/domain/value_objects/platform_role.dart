enum PlatformRole {
  platformAdmin('PLATFORM_ADMIN'),
  user('USER');

  const PlatformRole(this.value);
  final String value;

  static PlatformRole from(String raw) {
    return PlatformRole.values.firstWhere(
      (r) => r.value == raw,
      orElse: () => throw ArgumentError('Unknown platform role: $raw'),
    );
  }

  String get label {
    switch (this) {
      case PlatformRole.platformAdmin:
        return 'Platform Admin';
      case PlatformRole.user:
        return 'User';
    }
  }

  bool get isAdmin => this == PlatformRole.platformAdmin;
}

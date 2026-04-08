enum ProjectRole {
  admin('ADMIN'),
  editor('EDITOR'),
  reader('READER');

  const ProjectRole(this.value);
  final String value;

  static ProjectRole from(String raw) {
    return ProjectRole.values.firstWhere(
      (r) => r.value == raw,
      orElse: () => throw ArgumentError('Unknown project role: $raw'),
    );
  }

  String get label {
    switch (this) {
      case ProjectRole.admin:
        return 'Admin';
      case ProjectRole.editor:
        return 'Editor';
      case ProjectRole.reader:
        return 'Reader';
    }
  }

  bool get canWrite => this == ProjectRole.admin || this == ProjectRole.editor;
  bool get canManage => this == ProjectRole.admin;
}

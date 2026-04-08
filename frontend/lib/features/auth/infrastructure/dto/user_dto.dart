class UserDto {
  final String id;
  final String? oidcSubject;
  final String email;
  final String? name;
  final String platformRole;
  final bool active;
  final String createdAt;
  final String? updatedAt;

  const UserDto({
    required this.id,
    this.oidcSubject,
    required this.email,
    this.name,
    required this.platformRole,
    required this.active,
    required this.createdAt,
    this.updatedAt,
  });

  factory UserDto.fromJson(Map<String, dynamic> json) {
    return UserDto(
      id: json['id'] as String,
      oidcSubject: json['oidcSubject'] as String?,
      email: json['email'] as String,
      name: json['name'] as String?,
      platformRole: (json['platformRole'] ?? json['role']) as String,
      active: json['active'] as bool,
      createdAt: json['createdAt'] as String,
      updatedAt: json['updatedAt'] as String?,
    );
  }
}

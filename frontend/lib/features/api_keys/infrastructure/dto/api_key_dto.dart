class ApiKeyDto {
  final String id;
  final String projectId;
  final String? projectName;
  final String name;
  final String role;
  final String maskedToken;
  final bool active;
  final String createdAt;
  final String? expiresAt;

  const ApiKeyDto({
    required this.id,
    required this.projectId,
    this.projectName,
    required this.name,
    required this.role,
    required this.maskedToken,
    required this.active,
    required this.createdAt,
    this.expiresAt,
  });

  factory ApiKeyDto.fromJson(Map<String, dynamic> json) {
    return ApiKeyDto(
      id: json['id'] as String,
      projectId: (json['projectId'] ?? '') as String,
      projectName: json['projectName'] as String?,
      name: json['name'] as String,
      role: (json['role'] ?? 'READER') as String,
      maskedToken: json['maskedToken'] as String,
      active: json['active'] as bool,
      createdAt: json['createdAt'] as String,
      expiresAt: json['expiresAt'] as String?,
    );
  }
}

class ApiKeyCreatedDto {
  final String id;
  final String name;
  final String? projectName;
  final String rawToken;
  final String createdAt;
  final String? expiresAt;

  const ApiKeyCreatedDto({
    required this.id,
    required this.name,
    this.projectName,
    required this.rawToken,
    required this.createdAt,
    this.expiresAt,
  });

  factory ApiKeyCreatedDto.fromJson(Map<String, dynamic> json) {
    return ApiKeyCreatedDto(
      id: json['id'] as String,
      name: json['name'] as String,
      projectName: json['projectName'] as String?,
      rawToken: json['rawToken'] as String,
      createdAt: json['createdAt'] as String,
      expiresAt: json['expiresAt'] as String?,
    );
  }
}

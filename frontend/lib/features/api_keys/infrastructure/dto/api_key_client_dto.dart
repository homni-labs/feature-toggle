class ApiKeyClientDto {
  final String id;
  final String apiKeyId;
  final String clientType;
  final String? sdkName;
  final String serviceName;
  final String? namespace;
  final String firstSeenAt;
  final String lastSeenAt;
  final int requestCount;

  ApiKeyClientDto.fromJson(Map<String, dynamic> json)
      : id = json['id'] as String,
        apiKeyId = json['apiKeyId'] as String,
        clientType = json['clientType'] as String,
        sdkName = json['sdkName'] as String?,
        serviceName = json['serviceName'] as String,
        namespace = json['namespace'] as String?,
        firstSeenAt = json['firstSeenAt'] as String,
        lastSeenAt = json['lastSeenAt'] as String,
        requestCount = json['requestCount'] as int;
}

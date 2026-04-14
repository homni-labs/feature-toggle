enum ClientType { sdk, rest }

class ApiKeyClient {
  final String id;
  final String apiKeyId;
  final ClientType clientType;
  final String? sdkName;
  final String serviceName;
  final String? namespace;
  final DateTime firstSeenAt;
  final DateTime lastSeenAt;
  final int requestCount;

  const ApiKeyClient({
    required this.id,
    required this.apiKeyId,
    required this.clientType,
    this.sdkName,
    required this.serviceName,
    this.namespace,
    required this.firstSeenAt,
    required this.lastSeenAt,
    required this.requestCount,
  });

  /// Returns true if last seen less than 10 minutes ago.
  bool get isActive =>
      DateTime.now().difference(lastSeenAt).inMinutes < 10;

  /// Returns true if last seen less than 1 hour ago.
  bool get isRecent =>
      DateTime.now().difference(lastSeenAt).inMinutes < 60;
}

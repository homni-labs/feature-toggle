import 'dart:convert';
import 'package:http/http.dart' as http;

class RuntimeConfig {
  static late String apiBaseUrl;
  static late String oidcIssuer;
  static late String oidcClientId;
  static late String oidcRedirectUri;
  static late String oidcPostLogoutRedirectUri;

  static Future<void> load() async {
    final response = await http.get(Uri.parse('/config.json'));
    if (response.statusCode != 200) {
      throw Exception('Failed to load config.json: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;
    apiBaseUrl = json['apiBaseUrl'] as String;
    oidcIssuer = json['oidcIssuer'] as String;
    oidcClientId = json['oidcClientId'] as String;
    oidcRedirectUri = json['oidcRedirectUri'] as String;
    oidcPostLogoutRedirectUri = json['oidcPostLogoutRedirectUri'] as String;
  }
}
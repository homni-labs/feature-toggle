import 'package:togli_app/app/config/runtime_config.dart';

class OidcConfig {
  static String get issuer => RuntimeConfig.oidcIssuer;
  static String get clientId => RuntimeConfig.oidcClientId;
  static String get redirectUri => RuntimeConfig.oidcRedirectUri;
  static String get postLogoutRedirectUri => RuntimeConfig.oidcPostLogoutRedirectUri;
  static const List<String> scopes = ['openid', 'profile', 'email'];
}
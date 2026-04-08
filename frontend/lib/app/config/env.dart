class OidcConfig {
  static const String issuer = String.fromEnvironment(
    'OIDC_ISSUER',
    defaultValue: 'http://localhost:8180/realms/feature-toggle',
  );

  static const String clientId = String.fromEnvironment(
    'OIDC_CLIENT_ID',
    defaultValue: 'feature-toggle-frontend',
  );

  static const String redirectUri = String.fromEnvironment(
    'OIDC_REDIRECT_URI',
    defaultValue: 'http://localhost:3000/callback',
  );

  static const String postLogoutRedirectUri = String.fromEnvironment(
    'OIDC_POST_LOGOUT_REDIRECT_URI',
    defaultValue: 'http://localhost:3000/',
  );

  static const List<String> scopes = ['openid', 'profile', 'email'];
}

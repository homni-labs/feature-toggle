// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:togli_app/features/auth/domain/port/auth_repository.dart'
    as port;

/// Stores OAuth tokens in browser sessionStorage.
/// Tokens are cleared when the tab is closed.
class WebTokenStorage implements port.TokenStorage {
  static const _accessTokenKey = 'ft_access_token';
  static const _refreshTokenKey = 'ft_refresh_token';
  static const _idTokenKey = 'ft_id_token';
  static const _expiresAtKey = 'ft_expires_at';

  @override
  void saveTokens({
    required String accessToken,
    required String idToken,
    String? refreshToken,
    required int expiresIn,
  }) {
    final expiresAt = DateTime.now()
        .add(Duration(seconds: expiresIn))
        .millisecondsSinceEpoch
        .toString();
    _set(_accessTokenKey, accessToken);
    _set(_idTokenKey, idToken);
    _set(_expiresAtKey, expiresAt);
    if (refreshToken != null) {
      _set(_refreshTokenKey, refreshToken);
    }
  }

  @override
  String? get accessToken => _get(_accessTokenKey);
  @override
  String? get refreshToken => _get(_refreshTokenKey);
  @override
  String? get idToken => _get(_idTokenKey);

  @override
  bool get isAccessTokenExpired {
    final raw = _get(_expiresAtKey);
    if (raw == null) return true;
    return DateTime.now().millisecondsSinceEpoch >= int.parse(raw);
  }

  @override
  void clear() {
    for (final key in [
      _accessTokenKey,
      _refreshTokenKey,
      _idTokenKey,
      _expiresAtKey,
    ]) {
      html.window.sessionStorage.remove(key);
    }
  }

  // ── helpers ──────────────────────────────────────────────────────
  String? _get(String key) => html.window.sessionStorage[key];
  void _set(String key, String value) =>
      html.window.sessionStorage[key] = value;
}

import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:fpdart/fpdart.dart';
import 'package:http/http.dart' as http;

import 'package:togli_app/app/config/env.dart';
import 'package:togli_app/core/domain/failure.dart';
import 'package:togli_app/features/auth/domain/port/auth_repository.dart';

/// Endpoints parsed from the OIDC discovery document.
class OidcEndpoints {
  final String authorizationEndpoint;
  final String tokenEndpoint;
  final String userinfoEndpoint;
  final String endSessionEndpoint;

  OidcEndpoints({
    required this.authorizationEndpoint,
    required this.tokenEndpoint,
    required this.userinfoEndpoint,
    required this.endSessionEndpoint,
  });

  factory OidcEndpoints.fromJson(Map<String, dynamic> json) {
    T require<T>(String key) {
      final value = json[key];
      if (value == null) {
        throw FormatException('Missing required field "$key" in discovery');
      }
      return value as T;
    }

    return OidcEndpoints(
      authorizationEndpoint: require<String>('authorization_endpoint'),
      tokenEndpoint: require<String>('token_endpoint'),
      userinfoEndpoint: require<String>('userinfo_endpoint'),
      endSessionEndpoint: require<String>('end_session_endpoint'),
    );
  }
}

/// Pure OIDC / OAuth 2.1 service.
/// Uses Authorization Code + PKCE (S256). No provider-specific logic.
class OidcAuthRepository implements AuthRepository {
  OidcEndpoints? _endpoints;

  static const _httpTimeout = Duration(seconds: 15);

  // ── Discovery ────────────────────────────────────────────────────

  @override
  Future<void> discover() async {
    if (_endpoints != null) return;
    final url = Uri.parse(
      '${OidcConfig.issuer}/.well-known/openid-configuration',
    );
    final response = await http.get(url).timeout(_httpTimeout);
    if (response.statusCode != 200) {
      throw Exception('OIDC discovery failed: ${response.statusCode}');
    }
    final json = jsonDecode(response.body) as Map<String, dynamic>;

    // RFC: validate issuer matches what we configured
    final discoveredIssuer = json['issuer'] as String?;
    if (discoveredIssuer != OidcConfig.issuer) {
      throw Exception(
        'Issuer mismatch: expected ${OidcConfig.issuer}, '
        'got $discoveredIssuer',
      );
    }

    _endpoints = OidcEndpoints.fromJson(json);
  }

  // ── PKCE ─────────────────────────────────────────────────────────

  /// RFC 7636 — random 32-byte code verifier, base64url-encoded.
  @override
  String generateCodeVerifier() {
    final random = Random.secure();
    final bytes = List<int>.generate(32, (_) => random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  /// S256 code challenge = BASE64URL(SHA256(verifier)).
  @override
  String generateCodeChallenge(String verifier) {
    final digest = sha256.convert(utf8.encode(verifier));
    return base64UrlEncode(digest.bytes).replaceAll('=', '');
  }

  /// Cryptographically random nonce for ID token replay protection.
  @override
  String generateNonce() => generateCodeVerifier();

  // ── Authorization ────────────────────────────────────────────────

  @override
  Uri buildAuthorizationUrl({
    required String codeChallenge,
    required String state,
    required String nonce,
  }) {
    _ensureDiscovered();
    return Uri.parse(_endpoints!.authorizationEndpoint).replace(
      queryParameters: {
        'response_type': 'code',
        'client_id': OidcConfig.clientId,
        'redirect_uri': OidcConfig.redirectUri,
        'scope': OidcConfig.scopes.join(' '),
        'code_challenge': codeChallenge,
        'code_challenge_method': 'S256',
        'state': state,
        'nonce': nonce,
      },
    );
  }

  // ── Token exchange ───────────────────────────────────────────────

  @override
  Future<Either<Failure, Map<String, String>>> exchangeCode({
    required String code,
    required String codeVerifier,
  }) async {
    try {
      _ensureDiscovered();
      final response = await http
          .post(
            Uri.parse(_endpoints!.tokenEndpoint),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'grant_type': 'authorization_code',
              'client_id': OidcConfig.clientId,
              'code': code,
              'redirect_uri': OidcConfig.redirectUri,
              'code_verifier': codeVerifier,
            },
          )
          .timeout(_httpTimeout);
      if (response.statusCode != 200) {
        return Left(AuthFailure('Token exchange failed: ${response.statusCode}'));
      }
      final tokens = jsonDecode(response.body) as Map<String, dynamic>;
      return Right(tokens.map((k, v) => MapEntry(k, v.toString())));
    } on Exception catch (e) {
      return Left(AuthFailure('Token exchange error: $e'));
    }
  }

  // ── Refresh ──────────────────────────────────────────────────────

  @override
  Future<Either<Failure, Map<String, String>>> refreshAccessToken(
    String refreshToken,
  ) async {
    try {
      if (_endpoints == null) await discover();
      final response = await http
          .post(
            Uri.parse(_endpoints!.tokenEndpoint),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: {
              'grant_type': 'refresh_token',
              'client_id': OidcConfig.clientId,
              'refresh_token': refreshToken,
            },
          )
          .timeout(_httpTimeout);
      if (response.statusCode != 200) {
        return Left(AuthFailure('Token refresh failed: ${response.statusCode}'));
      }
      final tokens = jsonDecode(response.body) as Map<String, dynamic>;
      return Right(tokens.map((k, v) => MapEntry(k, v.toString())));
    } on Exception catch (e) {
      return Left(AuthFailure('Token refresh error: $e'));
    }
  }

  // ── ID Token validation ──────────────────────────────────────────

  /// Validates ID token claims per OIDC Core §3.1.3.7.
  /// Note: Signature verification requires JWKS and is not done here —
  /// the token was received directly from the token endpoint over TLS,
  /// which is acceptable per the spec for confidential channel exchange.
  @override
  void validateIdToken(String idToken, {required String expectedNonce}) {
    final parts = idToken.split('.');
    if (parts.length != 3) {
      throw FormatException('Invalid JWT structure');
    }

    final payload = _decodeJwtPayload(parts[1]);

    // iss — must match our configured issuer
    if (payload['iss'] != OidcConfig.issuer) {
      throw Exception(
        'ID token issuer mismatch: '
        'expected ${OidcConfig.issuer}, got ${payload['iss']}',
      );
    }

    // aud — must contain our client_id
    final aud = payload['aud'];
    final audiences = aud is List ? aud.cast<String>() : [aud as String];
    if (!audiences.contains(OidcConfig.clientId)) {
      throw Exception('ID token audience does not contain ${OidcConfig.clientId}');
    }

    // exp — must not be expired
    final exp = payload['exp'] as int?;
    if (exp == null ||
        DateTime.fromMillisecondsSinceEpoch(exp * 1000)
            .isBefore(DateTime.now())) {
      throw Exception('ID token is expired');
    }

    // nonce — must match the one we sent
    if (payload['nonce'] != expectedNonce) {
      throw Exception('ID token nonce mismatch');
    }
  }

  Map<String, dynamic> _decodeJwtPayload(String payload) {
    // Add padding if needed
    String normalized = payload.replaceAll('-', '+').replaceAll('_', '/');
    switch (normalized.length % 4) {
      case 2:
        normalized += '==';
        break;
      case 3:
        normalized += '=';
        break;
    }
    final decoded = utf8.decode(base64Decode(normalized));
    return jsonDecode(decoded) as Map<String, dynamic>;
  }

  // ── Logout ───────────────────────────────────────────────────────

  @override
  Uri buildLogoutUrl({required String idToken}) {
    _ensureDiscovered();
    return Uri.parse(_endpoints!.endSessionEndpoint).replace(
      queryParameters: {
        'id_token_hint': idToken,
        'post_logout_redirect_uri': OidcConfig.postLogoutRedirectUri,
      },
    );
  }

  // ── Internal ─────────────────────────────────────────────────────

  void _ensureDiscovered() {
    if (_endpoints == null) {
      throw StateError('Call discover() before using auth endpoints');
    }
  }
}

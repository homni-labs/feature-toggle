import 'package:togli_app/core/domain/typedefs.dart';
import 'package:togli_app/features/auth/domain/model/user.dart';

abstract class AuthRepository {
  Future<void> discover();
  String generateCodeVerifier();
  String generateCodeChallenge(String verifier);
  String generateNonce();
  Uri buildAuthorizationUrl({
    required String codeChallenge,
    required String state,
    required String nonce,
  });
  FutureEither<Map<String, String>> exchangeCode({
    required String code,
    required String codeVerifier,
  });
  FutureEither<Map<String, String>> refreshAccessToken(String refreshToken);
  void validateIdToken(String idToken, {required String expectedNonce});
  Uri buildLogoutUrl({required String idToken});
}

abstract class UserProfileRepository {
  FutureEither<User> getCurrentUser(String accessToken);
}

abstract class TokenStorage {
  void saveTokens({
    required String accessToken,
    required String idToken,
    String? refreshToken,
    required int expiresIn,
  });

  String? get accessToken;
  String? get refreshToken;
  String? get idToken;
  bool get isAccessTokenExpired;

  void clear();
}

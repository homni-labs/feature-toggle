// ignore_for_file: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:togli_app/core/domain/value_objects/project_role.dart';
import 'package:togli_app/features/auth/application/bloc/auth_state.dart';
import 'package:togli_app/features/auth/domain/port/auth_repository.dart';
import 'package:togli_app/features/projects/domain/model/project.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _authRepo;
  final UserProfileRepository _profileRepo;
  final TokenStorage _tokenStorage;

  bool _loginInProgress = false;
  Future<void>? _refreshFuture;

  AuthCubit({
    required AuthRepository authRepo,
    required UserProfileRepository profileRepo,
    required TokenStorage tokenStorage,
  })  : _authRepo = authRepo,
        _profileRepo = profileRepo,
        _tokenStorage = tokenStorage,
        super(const AuthInitial());

  // ── Initialization ───────────────────────────────────────────────

  Future<void> initialize() async {
    try {
      await _authRepo.discover();
    } catch (_) {
      emit(const AuthUnauthenticated());
      return;
    }

    final uri = Uri.parse(html.window.location.href);

    if (uri.path == '/callback') {
      if (uri.queryParameters.containsKey('code')) {
        await _handleCallback(uri);
      } else {
        _cleanupPkce();
        html.window.history.replaceState(null, '', '/');
        emit(const AuthUnauthenticated());
      }
      return;
    }

    if (_tokenStorage.accessToken != null) {
      if (_tokenStorage.isAccessTokenExpired) {
        await _tryRefresh();
      } else {
        emit(const AuthAuthenticated());
        await _fetchCurrentUser();
      }
      return;
    }

    emit(const AuthUnauthenticated());
  }

  // ── Login ────────────────────────────────────────────────────────

  Future<void> login() async {
    if (_loginInProgress) return;
    _loginInProgress = true;

    try {
      await _authRepo.discover();

      final codeVerifier = _authRepo.generateCodeVerifier();
      final authState = _authRepo.generateCodeVerifier();
      final nonce = _authRepo.generateNonce();

      _setSession('ft_code_verifier', codeVerifier);
      _setSession('ft_state', authState);
      _setSession('ft_nonce', nonce);

      final codeChallenge = _authRepo.generateCodeChallenge(codeVerifier);
      final authUrl = _authRepo.buildAuthorizationUrl(
        codeChallenge: codeChallenge,
        state: authState,
        nonce: nonce,
      );

      html.window.location.assign(authUrl.toString());
    } finally {
      _loginInProgress = false;
    }
  }

  // ── Callback ─────────────────────────────────────────────────────

  Future<void> _handleCallback(Uri uri) async {
    final code = uri.queryParameters['code'];
    final returnedState = uri.queryParameters['state'];
    final storedState = _getSession('ft_state');
    final storedVerifier = _getSession('ft_code_verifier');
    final storedNonce = _getSession('ft_nonce');

    if (code == null ||
        storedVerifier == null ||
        storedNonce == null ||
        returnedState != storedState) {
      _cleanupPkce();
      html.window.history.replaceState(null, '', '/');
      emit(const AuthUnauthenticated());
      return;
    }

    try {
      final result = await _authRepo.exchangeCode(
        code: code,
        codeVerifier: storedVerifier,
      );

      result.fold(
        (_) => emit(const AuthUnauthenticated()),
        (tokens) {
          _authRepo.validateIdToken(
            tokens['id_token']!,
            expectedNonce: storedNonce,
          );
          _saveTokens(tokens);
          html.window.history.replaceState(null, '', '/');
          emit(const AuthAuthenticated());
          _fetchCurrentUser();
        },
      );
    } catch (_) {
      emit(const AuthUnauthenticated());
    } finally {
      _cleanupPkce();
    }
  }

  // ── Token refresh ────────────────────────────────────────────────

  Future<String?> getValidAccessToken() async {
    if (_tokenStorage.isAccessTokenExpired) {
      await _tryRefresh();
    }
    return _tokenStorage.accessToken;
  }

  Future<void> _tryRefresh() async {
    if (_refreshFuture != null) {
      await _refreshFuture;
      return;
    }
    _refreshFuture = _doRefresh();
    try {
      await _refreshFuture;
    } finally {
      _refreshFuture = null;
    }
  }

  Future<void> _doRefresh() async {
    final refreshToken = _tokenStorage.refreshToken;
    if (refreshToken == null) {
      _tokenStorage.clear();
      emit(const AuthUnauthenticated());
      return;
    }
    try {
      final result = await _authRepo.refreshAccessToken(refreshToken);
      result.fold(
        (_) {
          _tokenStorage.clear();
          emit(const AuthUnauthenticated());
        },
        (tokens) {
          _saveTokens(tokens);
          final current = state;
          if (current is! AuthAuthenticated) {
            emit(const AuthAuthenticated());
          }
          if (current is AuthAuthenticated && current.currentUser == null) {
            _fetchCurrentUser();
          }
        },
      );
    } catch (_) {
      _tokenStorage.clear();
      emit(const AuthUnauthenticated());
    }
  }

  // ── Logout ───────────────────────────────────────────────────────

  Future<void> logout() async {
    final idToken = _tokenStorage.idToken;
    _tokenStorage.clear();
    emit(const AuthUnauthenticated());

    if (idToken != null) {
      try {
        await _authRepo.discover();
        final logoutUrl = _authRepo.buildLogoutUrl(idToken: idToken);
        html.window.location.assign(logoutUrl.toString());
      } catch (_) {
        // Local logout already done.
      }
    }
  }

  // ── Project context ──────────────────────────────────────────────

  void selectProject(Project project, ProjectRole? role) {
    final current = state;
    if (current is AuthAuthenticated) {
      emit(current.copyWith(
        currentProject: project,
        currentProjectRole: role,
      ));
    }
  }

  void clearProject() {
    final current = state;
    if (current is AuthAuthenticated) {
      emit(current.copyWith(clearProject: true));
    }
  }

  // ── Fetch user profile ───────────────────────────────────────────

  Future<void> _fetchCurrentUser() async {
    final token = await getValidAccessToken();
    if (token == null) return;

    final result = await _profileRepo.getCurrentUser(token);
    final current = state;
    if (current is! AuthAuthenticated) return;

    result.fold(
      (failure) => emit(AuthError(failure.message)),
      (user) => emit(current.copyWith(currentUser: user, clearError: true)),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────

  void _saveTokens(Map<String, String> tokens) {
    _tokenStorage.saveTokens(
      accessToken: tokens['access_token']!,
      idToken: tokens['id_token']!,
      refreshToken: tokens['refresh_token'],
      expiresIn: int.parse(tokens['expires_in'] ?? '3600'),
    );
  }

  void _cleanupPkce() {
    for (final key in ['ft_code_verifier', 'ft_state', 'ft_nonce']) {
      html.window.sessionStorage.remove(key);
    }
  }

  String? _getSession(String key) => html.window.sessionStorage[key];
  void _setSession(String key, String value) =>
      html.window.sessionStorage[key] = value;
}

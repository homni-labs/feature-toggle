import 'package:feature_toggle_app/core/domain/value_objects/project_role.dart';
import 'package:feature_toggle_app/features/auth/domain/model/user.dart';
import 'package:feature_toggle_app/features/projects/domain/model/project.dart';

sealed class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {
  const AuthInitial();
}

class AuthLoading extends AuthState {
  const AuthLoading();
}

class AuthUnauthenticated extends AuthState {
  const AuthUnauthenticated();
}

class AuthAuthenticated extends AuthState {
  final User? currentUser;
  final String? error;
  final Project? currentProject;
  final ProjectRole? currentProjectRole;

  const AuthAuthenticated({
    this.currentUser,
    this.error,
    this.currentProject,
    this.currentProjectRole,
  });

  bool get isInProject => currentProject != null;

  bool get canWriteToggles =>
      currentUser?.isPlatformAdmin == true ||
      currentProjectRole?.canWrite == true;

  bool get canManageMembers =>
      currentUser?.isPlatformAdmin == true ||
      currentProjectRole?.canManage == true;

  bool get canReadToggles =>
      currentUser?.isPlatformAdmin == true || currentProjectRole != null;

  bool get isProjectArchived => currentProject?.archived == true;

  AuthAuthenticated copyWith({
    User? currentUser,
    String? error,
    Project? currentProject,
    ProjectRole? currentProjectRole,
    bool clearProject = false,
    bool clearError = false,
  }) {
    return AuthAuthenticated(
      currentUser: currentUser ?? this.currentUser,
      error: clearError ? null : (error ?? this.error),
      currentProject:
          clearProject ? null : (currentProject ?? this.currentProject),
      currentProjectRole:
          clearProject ? null : (currentProjectRole ?? this.currentProjectRole),
    );
  }
}

class AuthError extends AuthState {
  final String message;
  const AuthError(this.message);
}

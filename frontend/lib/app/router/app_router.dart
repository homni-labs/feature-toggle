import 'dart:async';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'package:togli_app/app/di/injection.dart';
import 'package:togli_app/app/router/app_shell.dart';
import 'package:togli_app/app/router/shell_page.dart';
import 'package:togli_app/features/auth/application/bloc/auth_cubit.dart';
import 'package:togli_app/features/auth/application/bloc/auth_state.dart';
import 'package:togli_app/features/projects/presentation/screen/projects_screen.dart';
import 'package:togli_app/features/users/presentation/screen/users_screen.dart';
import 'package:togli_app/features/toggles/presentation/screen/toggles_screen.dart';
import 'package:togli_app/features/environments/presentation/screen/environments_screen.dart';
import 'package:togli_app/features/members/presentation/screen/members_screen.dart';
import 'package:togli_app/features/api_keys/presentation/screen/api_keys_screen.dart';
import 'package:togli_app/features/projects/presentation/screen/project_settings_screen.dart';

abstract final class AppRoutes {
  static const projects = '/projects';
  static const users = '/users';

  static String projectToggles(String slug) => '/projects/$slug/toggles';
  static String projectEnvironments(String slug) =>
      '/projects/$slug/environments';
  static String projectMembers(String slug) => '/projects/$slug/members';
  static String projectApiKeys(String slug) => '/projects/$slug/api-keys';
  static String projectSettings(String slug) => '/projects/$slug/settings';
}

GoRouter createAppRouter() {
  final authCubit = sl<AuthCubit>();

  return GoRouter(
    initialLocation: AppRoutes.projects,
    refreshListenable: _AuthNotifier(authCubit),
    redirect: (context, state) {
      final auth = authCubit.state;
      final location = state.matchedLocation;

      if (auth is! AuthAuthenticated) return null;

      if (location == '/') return AppRoutes.projects;

      return null;
    },
    routes: [
      GoRoute(path: '/', redirect: (_, __) => AppRoutes.projects),
      GoRoute(path: '/callback', redirect: (_, __) => AppRoutes.projects),

      // Platform-level shell
      ShellRoute(
        builder: (context, state, child) => AppShell(
          currentPath: state.uri.path,
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/projects',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: ProjectsPage()),
          ),
          GoRoute(
            path: '/users',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: UsersPage()),
          ),
        ],
      ),

      // Project-level shell
      ShellRoute(
        builder: (context, state, child) {
          final segments = state.uri.pathSegments;
          final slugIdx = segments.indexOf('projects') + 1;
          final slug =
              slugIdx > 0 && slugIdx < segments.length ? segments[slugIdx] : '';
          return ShellPage(
            slug: slug,
            currentPath: state.uri.path,
            child: child,
          );
        },
        routes: [
          GoRoute(
            path: '/projects/:slug/toggles',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: HomePage()),
          ),
          GoRoute(
            path: '/projects/:slug/environments',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: EnvironmentsPage()),
          ),
          GoRoute(
            path: '/projects/:slug/members',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: MembersPage()),
          ),
          GoRoute(
            path: '/projects/:slug/api-keys',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: ApiKeysPage()),
          ),
          GoRoute(
            path: '/projects/:slug/settings',
            pageBuilder: (_, __) =>
                const NoTransitionPage(child: ProjectSettingsPage()),
          ),
        ],
      ),
    ],
  );
}

class _AuthNotifier extends ChangeNotifier {
  late final StreamSubscription<AuthState> _sub;

  _AuthNotifier(AuthCubit cubit) {
    _sub = cubit.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}

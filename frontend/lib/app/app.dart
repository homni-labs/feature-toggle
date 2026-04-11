import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'package:feature_toggle_app/app/di/injection.dart';
import 'package:feature_toggle_app/app/theme/app_colors.dart';
import 'package:feature_toggle_app/app/theme/app_theme.dart';
import 'package:feature_toggle_app/core/presentation/widgets/animated_background.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_cubit.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_state.dart';

class FeatureToggleApp extends StatelessWidget {
  const FeatureToggleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: sl<AuthCubit>(),
      child: MaterialApp.router(
        title: 'Feature Toggle',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light(),
        routerConfig: sl<GoRouter>(),
        builder: (context, child) {
          return BlocBuilder<AuthCubit, AuthState>(
            builder: (context, state) => switch (state) {
              AuthInitial() || AuthLoading() => const Scaffold(
                  backgroundColor: AppTheme.scaffoldBackground,
                  body: Center(
                    child: CircularProgressIndicator(color: AppColors.coral),
                  ),
                ),
              AuthUnauthenticated() => _LoginRedirect(),
              AuthError(:final message) => _ErrorPage(
                  message: message,
                  onRetry: () => context.read<AuthCubit>().initialize(),
                ),
              AuthAuthenticated(:final currentUser) => () {
                  if (currentUser != null && !currentUser.active) {
                    return _InactiveUserPage(
                      onLogout: () => context.read<AuthCubit>().logout(),
                    );
                  }
                  return child!;
                }(),
            },
          );
        },
      ),
    );
  }
}

class _LoginRedirect extends StatefulWidget {
  @override
  State<_LoginRedirect> createState() => _LoginRedirectState();
}

class _LoginRedirectState extends State<_LoginRedirect> {
  @override
  void initState() {
    super.initState();
    context.read<AuthCubit>().login();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Center(
        child: CircularProgressIndicator(color: AppColors.coral),
      ),
    );
  }
}

class _ErrorPage extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorPage({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.error_outline_rounded,
                  size: 72,
                  color: AppColors.coral.withOpacity(0.7),
                ),
                const SizedBox(height: 24),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 32),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Try Again'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.coral,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 28, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InactiveUserPage extends StatelessWidget {
  final VoidCallback onLogout;

  const _InactiveUserPage({required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.scaffoldBackground,
      body: Stack(
        children: [
          const Positioned.fill(child: AnimatedBackground()),
          Center(
            child: Container(
              width: 420,
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: AppTheme.cardBackground,
                border: Border.all(color: AppTheme.borderDefault),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.yellow.withOpacity(0.15),
                    ),
                    child: const Icon(
                      Icons.person_off_rounded,
                      size: 32,
                      color: AppColors.yellow,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'Account Inactive',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Your account has been deactivated. Please contact your administrator to restore access.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      color: AppTheme.textTertiary,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: onLogout,
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: const Text('Sign out'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.coral,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

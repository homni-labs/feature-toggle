import 'package:togli_app/app/theme/app_colors.dart';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_web_plugins/url_strategy.dart';
import 'package:go_router/go_router.dart';

import 'package:togli_app/app/app.dart';
import 'package:togli_app/app/config/runtime_config.dart';
import 'package:togli_app/app/di/injection.dart';
import 'package:togli_app/app/router/app_router.dart';
import 'package:togli_app/features/auth/application/bloc/auth_cubit.dart';

void main() {
  usePathUrlStrategy();

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      FlutterError.onError = (FlutterErrorDetails details) {
        FlutterError.presentError(details);
        if (kReleaseMode) {
          // TODO(CRASH-1): send to Sentry/Crashlytics
        }
      };

      ErrorWidget.builder = (FlutterErrorDetails details) {
        return ColoredBox(
          color: const Color(0xFFF5F2EB),
          child: Center(
            child: Text(
              'Something went wrong',
              style: TextStyle(color: AppColors.navy.withOpacity(0.7), fontSize: 16),
            ),
          ),
        );
      };

      await RuntimeConfig.load();

      configureDependencies();

      final authCubit = sl<AuthCubit>();
      await authCubit.initialize();

      sl.registerLazySingleton<GoRouter>(() => createAppRouter());

      runApp(const TogliApp());
    },
    (error, stack) {
      if (kDebugMode) {
        debugPrint('Uncaught: $error\n$stack');
      }
      // TODO(CRASH-1): send to Sentry/Crashlytics
    },
  );
}

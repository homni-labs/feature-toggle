import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:feature_toggle_app/app/app.dart';
import 'package:feature_toggle_app/app/di/injection.dart';
import 'package:feature_toggle_app/features/auth/application/bloc/auth_cubit.dart';

void main() {
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
        return const ColoredBox(
          color: Color(0xFF151530),
          child: Center(
            child: Text(
              'Something went wrong',
              style: TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        );
      };

      configureDependencies();

      final authCubit = sl<AuthCubit>();
      await authCubit.initialize();

      runApp(const FeatureToggleApp());
    },
    (error, stack) {
      if (kDebugMode) {
        debugPrint('Uncaught: $error\n$stack');
      }
      // TODO(CRASH-1): send to Sentry/Crashlytics
    },
  );
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import 'core/ui/error_view.dart';
import 'core/config/app_config.dart';
import 'core/logging/app_logger.dart';
import 'core/logging/sentry_redaction.dart';
import 'firebase_options.dart';
import './Routers/routes.dart';

void main() async {
  final dsn = AppConfig.sentryDsn;
  if (dsn.isNotEmpty) {
    // Sentry path: SentryFlutter.init establishes its own zone; no second runZonedGuarded
    await SentryFlutter.init(
      (options) {
        options.dsn = dsn;
        options.sendDefaultPii = false;
        options.beforeSend = SentryRedaction.beforeSend;
      },
      appRunner: () async {
        WidgetsFlutterBinding.ensureInitialized();

        FlutterError.onError = (FlutterErrorDetails details) {
          FlutterError.presentError(details);
          AppLogger.error('FlutterError', details.exception, details.stack);
        };

        await initializeApp();
      },
    );
  } else {
    // Standalone path: standard runZonedGuarded without Sentry
    await runZonedGuarded(
      () async {
        WidgetsFlutterBinding.ensureInitialized();

        FlutterError.onError = (FlutterErrorDetails details) {
          FlutterError.presentError(details);
          AppLogger.error('FlutterError', details.exception, details.stack);
        };

        await initializeApp();
      },
      (error, stack) {
        AppLogger.error('Uncaught exception', error, stack);
      },
    );
  }
}

@visibleForTesting
Future<void> initializeApp({Future<void> Function()? initializeFirebase}) async {
  try {
    AppConfig.validate();
    if (initializeFirebase != null) {
      await initializeFirebase();
    } else {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    runApp(const ProviderScope(child: MyApp()));
  } catch (e, stack) {
    AppLogger.error('Initialization failed', e, stack);
    runApp(ProviderScope(child: ErrorBoundaryApp(error: e)));
  }
}

class ErrorBoundaryApp extends StatelessWidget {
  final Object error;
  final bool isDebug;

  const ErrorBoundaryApp({
    super.key,
    required this.error,
    this.isDebug = kDebugMode,
  });

  @override
  Widget build(BuildContext context) {
    final String message;
    if (isDebug) {
      if (error is FormatException) {
        message = (error as FormatException).message;
      } else {
        message = error.toString();
      }
    } else {
      message = safeErrorText(error);
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: ErrorView(
          message: message,
          onRetry: () => initializeApp(),
        ),
      ),
    );
  }
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      title: 'Stardy AI',
    );
  }
}

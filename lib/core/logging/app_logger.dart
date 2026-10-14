import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'sentry_redaction.dart';

enum LogLevel { debug, info, warn, error }

class AppLogger {
  @visibleForTesting
  static void Function(
    String, {
    int level,
    String name,
    Object? error,
    StackTrace? stackTrace,
    DateTime? time,
    int? sequenceNumber,
    Zone? zone,
  })
  logFunction = developer.log;
  @visibleForTesting
  static bool overrideReleaseModeForTesting = false;

  static void debug(String message) => _log(LogLevel.debug, message);
  static void info(String message) => _log(LogLevel.info, message);
  static void warn(String message) => _log(LogLevel.warn, message);
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    _log(LogLevel.error, message, error: error, stackTrace: stackTrace);
  }

  static void _log(
    LogLevel level,
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) {
    final bool isRelease = overrideReleaseModeForTesting || kReleaseMode;
    if (isRelease && (level == LogLevel.debug || level == LogLevel.info)) {
      return;
    }
    String redacted = redact(message);
    if (error != null) {
      redacted += ' | Error: ${redact(error.toString())}';
    }

    logFunction(redacted, name: level.name.toUpperCase());

    if (stackTrace != null && !isRelease) {
      logFunction(stackTrace.toString(), name: level.name.toUpperCase());
    }

    // Release error sink: only warn and error go to Sentry if Sentry is enabled
    if (Sentry.isEnabled && (level == LogLevel.warn || level == LogLevel.error)) {
      if (level == LogLevel.warn) {
        Sentry.captureMessage(redacted, level: SentryLevel.warning);
      } else {
        if (error != null) {
          Sentry.captureException(
            error,
            stackTrace: stackTrace,
            hint: Hint.withMap({'log_message': redacted}),
          );
        } else {
          Sentry.captureMessage(redacted, level: SentryLevel.error);
        }
      }
    }
  }

  @visibleForTesting
  static String redact(String input) => SentryRedaction.redact(input);
}

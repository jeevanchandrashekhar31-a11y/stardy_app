import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/core/logging/app_logger.dart';

void main() {
  group('AppLogger redact', () {
    test('redacts emails', () {
      expect(
        AppLogger.redact('Contact us at support@example.com for help'),
        equals('Contact us at [EMAIL_REDACTED] for help'),
      );
    });

    test('redacts Bearer tokens', () {
      expect(
        AppLogger.redact('Header Authorization: Bearer abc123XYZ...=='),
        equals('Header Authorization: Bearer [REDACTED]'),
      );
    });

    test('redacts JWT-shaped strings', () {
      expect(
        AppLogger.redact(
          'Token: eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiaWF0IjoxNTE2MjM5MDIyfQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c',
        ),
        equals('Token: [JWT_REDACTED]'),
      );
    });
  });

  group('AppLogger levels', () {
    List<String> printLogs = [];

    setUp(() {
      printLogs.clear();
      AppLogger.overrideReleaseModeForTesting = false;
    });

    test('emits debug and info in non-release mode', () {
      AppLogger.logFunction =
          (
            String msg, {
            int level = 0,
            String name = '',
            Object? error,
            StackTrace? stackTrace,
            DateTime? time,
            int? sequenceNumber,
            Zone? zone,
          }) {
            printLogs.add('[$name] $msg');
          };

      AppLogger.debug('test debug');
      AppLogger.info('test info');

      expect(printLogs.length, 2);
      expect(printLogs[0], contains('[DEBUG] test debug'));
      expect(printLogs[1], contains('[INFO] test info'));
    });

    test('suppresses debug and info in release mode', () {
      AppLogger.overrideReleaseModeForTesting = true;
      AppLogger.logFunction =
          (
            String msg, {
            int level = 0,
            String name = '',
            Object? error,
            StackTrace? stackTrace,
            DateTime? time,
            int? sequenceNumber,
            Zone? zone,
          }) {
            printLogs.add('[$name] $msg');
          };

      AppLogger.debug('test debug');
      AppLogger.info('test info');
      AppLogger.warn('test warn');

      expect(printLogs.length, 1);
      expect(printLogs[0], contains('[WARN] test warn'));
    });
  });
}

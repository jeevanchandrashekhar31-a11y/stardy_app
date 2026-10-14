import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/core/config/app_config.dart';

void main() {
  group('AppConfig validation', () {
    test('accepts valid dev config with or without /api/v1', () {
      expect(
        () => AppConfig.validateConfig('dev', 'http://localhost:3000'),
        returnsNormally,
      );
      expect(
        () => AppConfig.validateConfig('dev', 'http://10.0.2.2:3000/api/v1'),
        returnsNormally,
      );
    });

    test('accepts valid staging config ending in /api/v1', () {
      expect(
        () => AppConfig.validateConfig(
          'staging',
          'https://staging.api.example.com/api/v1',
        ),
        returnsNormally,
      );
    });

    test('accepts valid prod config ending in /api/v1', () {
      expect(
        () => AppConfig.validateConfig('prod', 'https://api.example.com/api/v1'),
        returnsNormally,
      );
    });

    test('accepts valid staging and prod url with trailing slash after /api/v1', () {
      expect(
        () => AppConfig.validateConfig('prod', 'https://api.example.com/api/v1/'),
        returnsNormally,
      );
      expect(
        () => AppConfig.validateConfig('staging', 'https://staging.api.example.com/api/v1/'),
        returnsNormally,
      );
    });

    test('accepts valid staging and prod url without trailing slash', () {
      expect(
        () => AppConfig.validateConfig('prod', 'https://api.example.com/api/v1'),
        returnsNormally,
      );
      expect(
        () => AppConfig.validateConfig('staging', 'https://staging.api.example.com/api/v1'),
        returnsNormally,
      );
    });

    test('rejects missing /api/v1 path in staging and prod', () {
      expect(
        () => AppConfig.validateConfig('staging', 'https://staging.api.example.com'),
        throwsFormatException,
      );
      expect(
        () => AppConfig.validateConfig('staging', 'https://staging.api.example.com/'),
        throwsFormatException,
      );
      expect(
        () => AppConfig.validateConfig('prod', 'https://api.example.com'),
        throwsFormatException,
      );
      expect(
        () => AppConfig.validateConfig('prod', 'https://api.example.com/'),
        throwsFormatException,
      );
      expect(
        () => AppConfig.validateConfig('prod', 'https://api.example.com/v1'),
        throwsFormatException,
      );
    });

    test('rejects missing or empty APP_ENV', () {
      expect(
        () => AppConfig.validateConfig('', 'https://api.example.com/api/v1'),
        throwsFormatException,
      );
    });

    test('rejects invalid APP_ENV', () {
      expect(
        () => AppConfig.validateConfig('production', 'https://api.example.com/api/v1'),
        throwsFormatException,
      );
    });

    test('rejects missing or empty API_BASE_URL', () {
      expect(() => AppConfig.validateConfig('dev', ''), throwsFormatException);
    });

    test('rejects http in staging', () {
      expect(
        () => AppConfig.validateConfig(
          'staging',
          'http://staging.api.example.com/api/v1',
        ),
        throwsFormatException,
      );
    });

    test('rejects http in prod', () {
      expect(
        () => AppConfig.validateConfig('prod', 'http://api.example.com/api/v1'),
        throwsFormatException,
      );
    });

    test('rejects https:// without host', () {
      expect(
        () => AppConfig.validateConfig('prod', 'https://'),
        throwsFormatException,
      );
    });

    test('rejects https://  with space', () {
      expect(
        () => AppConfig.validateConfig('prod', 'https:// '),
        throwsFormatException,
      );
    });

    test('rejects URL with user info', () {
      expect(
        () => AppConfig.validateConfig('prod', 'https://user:pw@host.com/api/v1'),
        throwsFormatException,
      );
    });

    test('accepts HTTPS://host.com/api/v1 (case insensitive scheme)', () {
      expect(
        () => AppConfig.validateConfig('prod', 'HTTPS://host.com/api/v1'),
        returnsNormally,
      );
    });
  });
}

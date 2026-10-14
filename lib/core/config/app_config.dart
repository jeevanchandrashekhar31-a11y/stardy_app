import 'package:flutter/foundation.dart';

class AppConfig {
  static const String appEnv = String.fromEnvironment('APP_ENV');
  static const String apiBaseUrl = String.fromEnvironment('API_BASE_URL');
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  static String get normalizedBaseUrl {
    if (apiBaseUrl.endsWith('/')) {
      return apiBaseUrl.substring(0, apiBaseUrl.length - 1);
    }
    return apiBaseUrl;
  }

  static void validate() {
    validateConfig(appEnv, apiBaseUrl);
  }

  @visibleForTesting
  static void validateConfig(String env, String url) {
    if (env.isEmpty) {
      throw const FormatException('APP_ENV is missing or empty.');
    }
    if (env != 'dev' && env != 'staging' && env != 'prod') {
      throw FormatException(
        'Invalid APP_ENV: $env. Must be dev, staging, or prod.',
      );
    }
    if (url.isEmpty) {
      throw const FormatException('API_BASE_URL is missing or empty.');
    }
    if (url.contains(' ')) {
      throw const FormatException('API_BASE_URL must not contain spaces.');
    }
    final uri = Uri.tryParse(url);
    if (uri == null) {
      throw const FormatException('API_BASE_URL is not a valid URI.');
    }
    if (env == 'staging' || env == 'prod') {
      if (uri.scheme != 'https') {
        throw const FormatException(
          'API_BASE_URL must use https in staging and prod environments.',
        );
      }
      if (uri.host.isEmpty) {
        throw const FormatException('API_BASE_URL must have a non-empty host.');
      }
      if (uri.userInfo.isNotEmpty) {
        throw const FormatException('API_BASE_URL must not contain user info.');
      }
      final normalizedPath = uri.path.endsWith('/') && uri.path.length > 1
          ? uri.path.substring(0, uri.path.length - 1)
          : uri.path;
      if (!normalizedPath.endsWith('/api/v1')) {
        throw const FormatException(
          'API_BASE_URL path must end with /api/v1 in staging and prod environments.',
        );
      }
    }
  }
}

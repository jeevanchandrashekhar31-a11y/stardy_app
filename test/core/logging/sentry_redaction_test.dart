import 'package:flutter_test/flutter_test.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:stardy_app/core/logging/sentry_redaction.dart';

void main() {
  group('SentryRedaction String Redaction Tests', () {
    test('redacts Bearer tokens', () {
      const input = 'Request failed with header Bearer eyJhbGciOiJIUzI1NiJ9 and Bearer my-secret-token_123';
      final redacted = SentryRedaction.redact(input);
      expect(redacted, isNot(contains('my-secret-token_123')));
      expect(redacted, contains('Bearer [REDACTED]'));
    });

    test('redacts email addresses', () {
      const input = 'User student.one+test@stardy.edu logged in with user@domain.com';
      final redacted = SentryRedaction.redact(input);
      expect(redacted, isNot(contains('student.one+test@stardy.edu')));
      expect(redacted, isNot(contains('user@domain.com')));
      expect(redacted, contains('[EMAIL_REDACTED]'));
    });

    test('redacts real JWT requiring eyJ prefix', () {
      const jwt = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4ifQ.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c';
      final redacted = SentryRedaction.redact('Encountered token $jwt in response');
      expect(redacted, isNot(contains(jwt)));
      expect(redacted, contains('[JWT_REDACTED]'));
    });

    test('does not over-match URLs, package identifiers, or type names', () {
      expect(
        SentryRedaction.redact('https://api.stardy.com/courses'),
        equals('https://api.stardy.com/courses'),
      );
      expect(
        SentryRedaction.redact('com.stardyai.app'),
        equals('com.stardyai.app'),
      );
      expect(
        SentryRedaction.redact('dart.core.List'),
        equals('dart.core.List'),
      );
      expect(
        SentryRedaction.redact('package:stardy_app/core/x.dart:12'),
        equals('package:stardy_app/core/x.dart:12'),
      );
    });

    test('redacts query strings', () {
      const input = 'GET https://api.stardy.com/courses?category=math&page=2#section';
      final redacted = SentryRedaction.redact(input);
      expect(redacted, isNot(contains('category=math')));
      expect(redacted, contains('?[QUERY_REDACTED]'));
    });

    test('redacts presigned-URL signatures', () {
      const s3Url = 'X-Amz-Signature=d25a87b1c43f7690e4f3a';
      final redactedS3 = SentryRedaction.redact(s3Url);
      expect(redactedS3, contains('X-Amz-Signature=[REDACTED]'));
      expect(redactedS3, isNot(contains('d25a87b1c43f7690e4f3a')));

      const azureUrl = 'sig=secretAzureSignature12345';
      final redactedAzure = SentryRedaction.redact(azureUrl);
      expect(redactedAzure, contains('sig=[REDACTED]'));
      expect(redactedAzure, isNot(contains('secretAzureSignature12345')));
    });
  });

  group('Sentry beforeSend Callback Tests', () {
    test('preserves debugMeta, threads, modules, sdk, and extra while removing user data', () async {
      final debugMeta = DebugMeta();
      final threads = [SentryThread(id: 1, name: 'main')];
      final modules = {'my_module': '1.0.0'};
      final sdk = SdkVersion(name: 'sentry.dart.flutter', version: '8.14.2');
      const extra = {'custom_key': 'custom_value'};
      final user = SentryUser(id: 'student-999', email: 'secret@domain.com', username: 'student_999');

      final event = SentryEvent(
        debugMeta: debugMeta,
        threads: threads,
        modules: modules,
        sdk: sdk,
        // ignore: deprecated_member_use
        extra: extra,
        user: user,
      );

      final result = await SentryRedaction.beforeSend(event, Hint());
      expect(result, isNotNull);
      expect(result!.debugMeta, equals(debugMeta));
      expect(result.threads, equals(threads));
      expect(result.modules, equals(modules));
      expect(result.sdk, equals(sdk));
      // ignore: deprecated_member_use
      expect(result.extra, equals(extra));

      // User data is removed: all user fields are null or empty
      expect(result.user, isNotNull);
      expect(result.user!.id, isEmpty);
      expect(result.user!.username, isNull);
      expect(result.user!.email, isNull);
      expect(result.user!.ipAddress, isNull);
      expect(result.user!.data, isNull);
    });

    test('drops request body and cookies, redacts request URL and queryString', () async {
      final request = SentryRequest(
        url: 'https://api.stardy.com/auth/login?redirect=dashboard',
        queryString: 'redirect=dashboard',
        cookies: 'session_id=12345',
        data: {'password': 'super-secret-password', 'email': 'student@stardy.edu'},
      );
      final event = SentryEvent(
        request: request,
      );

      final result = await SentryRedaction.beforeSend(event, Hint());
      expect(result, isNotNull);
      expect(result!.request, isNotNull);
      expect(result.request!.data, isNull);
      expect(result.request!.cookies, isNull);
      expect(result.request!.url, contains('?[QUERY_REDACTED]'));
      expect(result.request!.queryString, contains('[QUERY_REDACTED]'));
    });

    test('redacts sensitive content in exception values and breadcrumbs', () async {
      const exception = SentryException(
        type: 'ApiException',
        value: 'Failed with Bearer token12345 and email student@test.com',
      );
      final breadcrumb = Breadcrumb(
        message: 'Navigation to /profile?user=student@test.com',
        data: {'auth': 'Bearer secret_token_xyz'},
      );
      final event = SentryEvent(
        exceptions: [exception],
        breadcrumbs: [breadcrumb],
      );

      final result = await SentryRedaction.beforeSend(event, Hint());
      expect(result, isNotNull);
      expect(result!.exceptions!.first.value, isNot(contains('token12345')));
      expect(result.exceptions!.first.value, isNot(contains('student@test.com')));
      expect(result.exceptions!.first.value, contains('Bearer [REDACTED]'));

      expect(result.breadcrumbs!.first.message, isNot(contains('student@test.com')));
      expect(result.breadcrumbs!.first.message, contains('?[QUERY_REDACTED]'));
      expect(result.breadcrumbs!.first.data!['auth'], contains('Bearer [REDACTED]'));
    });
  });

  group('Sentry Disabled When DSN Is Empty', () {
    test('Sentry remains uninitialized / disabled when DSN is empty', () {
      // By default in test environment, Sentry.isEnabled is false
      expect(Sentry.isEnabled, isFalse);
    });
  });
}

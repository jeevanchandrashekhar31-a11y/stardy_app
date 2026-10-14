import 'dart:async';
import 'package:sentry_flutter/sentry_flutter.dart';

class SentryRedaction {
  // Regex for Bearer tokens
  static final RegExp bearerRegex = RegExp(
    r'Bearer\s+[A-Za-z0-9\-._~+/]+=*',
    caseSensitive: false,
  );

  // Regex for emails
  static final RegExp emailRegex = RegExp(
    r'[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}',
  );

  // Regex for JWT-shaped strings (requires JWT header prefix eyJ)
  static final RegExp jwtRegex = RegExp(
    r'eyJ[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+\.[A-Za-z0-9_-]+',
  );

  // Regex for presigned-URL signatures (AWS S3, Google Cloud Storage, Azure SAS)
  static final RegExp presignedSignatureRegex = RegExp(
    r'(X-Amz-Signature|X-Goog-Signature|Signature|sig)=[A-Za-z0-9%_\-]+',
    caseSensitive: false,
  );

  // Regex for query strings (?key=value...)
  static final RegExp queryStringRegex = RegExp(
    r'\?[^#\s]*',
  );

  /// Redacts sensitive strings according to the security specification.
  static String redact(String input) {
    var output = input;

    // Redact Bearer tokens
    output = output.replaceAllMapped(bearerRegex, (_) => 'Bearer [REDACTED]');

    // Redact emails
    output = output.replaceAllMapped(emailRegex, (_) => '[EMAIL_REDACTED]');

    // Redact presigned signatures before stripping query strings so signature markers are honored
    output = output.replaceAllMapped(
      presignedSignatureRegex,
      (match) => '${match.group(1)}=[REDACTED]',
    );

    // Redact JWT-shaped strings (only matches eyJ-prefixed tokens)
    output = output.replaceAllMapped(jwtRegex, (_) => '[JWT_REDACTED]');

    // Redact query strings
    output = output.replaceAllMapped(queryStringRegex, (_) => '?[QUERY_REDACTED]');

    return output;
  }

  /// Sentry beforeSend callback:
  /// - Preserves all original SentryEvent fields (debugMeta, threads, modules, sdk, extra, etc.) via copyWith.
  /// - Drops request bodies and cookies.
  /// - Redacts request url, headers, query string.
  /// - Redacts event message, exceptions, and breadcrumbs.
  /// - Strips user identifiers by replacing with an empty SentryUser().
  static FutureOr<SentryEvent?> beforeSend(SentryEvent event, Hint hint) {
    // Drop request bodies and sanitize request URLs/query strings
    SentryRequest? sanitizedRequest;
    if (event.request != null) {
      final req = event.request!;
      final rawUrl = req.url;
      final sanitizedUrl = rawUrl != null ? redact(rawUrl) : null;
      final rawQuery = req.queryString;
      final sanitizedQueryString = rawQuery != null && rawQuery.isNotEmpty
          ? (rawQuery.startsWith('?') ? redact(rawQuery) : '[QUERY_REDACTED]')
          : rawQuery;
      sanitizedRequest = SentryRequest(
        url: sanitizedUrl,
        method: req.method,
        queryString: sanitizedQueryString,
        headers: req.headers.map((k, v) => MapEntry(k, redact(v))),
        cookies: null, // Drop cookies
        data: null, // Drop request body
        env: req.env,
      );
    }

    // Sanitize event message
    SentryMessage? sanitizedMessage;
    if (event.message != null) {
      final rawFormatted = event.message!.formatted;
      final rawTemplate = event.message!.template;
      final rawParams = event.message!.params;
      sanitizedMessage = SentryMessage(
        redact(rawFormatted),
        template: rawTemplate != null ? redact(rawTemplate) : null,
        params: rawParams?.map((p) => redact(p.toString())).toList(),
      );
    }

    // Sanitize exceptions
    List<SentryException>? sanitizedExceptions;
    if (event.exceptions != null) {
      sanitizedExceptions = event.exceptions!.map((ex) {
        final rawVal = ex.value;
        return SentryException(
          type: ex.type,
          value: rawVal != null ? redact(rawVal) : null,
          module: ex.module,
          stackTrace: ex.stackTrace,
          mechanism: ex.mechanism,
          threadId: ex.threadId,
        );
      }).toList();
    }

    // Sanitize breadcrumbs
    List<Breadcrumb>? sanitizedBreadcrumbs;
    if (event.breadcrumbs != null) {
      sanitizedBreadcrumbs = event.breadcrumbs!.map((crumb) {
        final rawMsg = crumb.message;
        final rawData = crumb.data;
        return Breadcrumb(
          message: rawMsg != null ? redact(rawMsg) : null,
          type: crumb.type,
          data: rawData?.map((k, v) => MapEntry(k, v is String ? redact(v) : v)),
          category: crumb.category,
          level: crumb.level,
          timestamp: crumb.timestamp,
        );
      }).toList();
    }

    // SentryEvent.copyWith does not clear user when passed null.
    // Setting a sanitized SentryUser with empty id and null attributes strips all user identifiers.
    final sanitizedUser = event.user != null ? SentryUser(id: '') : null;

    return event.copyWith(
      request: sanitizedRequest,
      message: sanitizedMessage,
      exceptions: sanitizedExceptions,
      breadcrumbs: sanitizedBreadcrumbs,
      user: sanitizedUser,
    );
  }
}

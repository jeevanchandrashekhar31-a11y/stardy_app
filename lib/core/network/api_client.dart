import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';

import '../config/app_config.dart';
import '../logging/app_logger.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../state/session_epoch.dart';

final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final tokenProvider = Provider<Future<String?> Function(bool forceRefresh)>((ref) {
  return (bool forceRefresh) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  };
});

final apiClientProvider = Provider<ApiClient>((ref) {
  // Re-create ApiClient (and dependents) when session changes to clear all caches
  ref.watch(sessionEpochProvider);
  final httpClient = ref.watch(httpClientProvider);
  final tokenFn = ref.watch(tokenProvider);
  return ApiClient(httpClient: httpClient, tokenProvider: tokenFn);
});


sealed class ApiFailure {
  final String message;
  const ApiFailure(this.message);
}

class ValidationFailure extends ApiFailure {
  const ValidationFailure(super.message);
}

class UnauthorizedFailure extends ApiFailure {
  const UnauthorizedFailure(super.message);
}

class ForbiddenFailure extends ApiFailure {
  const ForbiddenFailure(super.message);
}

class NotFoundFailure extends ApiFailure {
  const NotFoundFailure(super.message);
}

class ConflictFailure extends ApiFailure {
  const ConflictFailure(super.message);
}

class RateLimitedFailure extends ApiFailure {
  final int? retryAfter;
  const RateLimitedFailure(super.message, {this.retryAfter});
}

class ServerFailure extends ApiFailure {
  const ServerFailure(super.message);
}

class NetworkFailure extends ApiFailure {
  const NetworkFailure(super.message);
}

class TimeoutFailure extends ApiFailure {
  const TimeoutFailure(super.message);
}

class MalformedFailure extends ApiFailure {
  const MalformedFailure(super.message);
}

sealed class Result<T> {}

class Ok<T> extends Result<T> {
  final T data;
  Ok(this.data);
}

class Err<T> extends Result<T> {
  final ApiFailure error;
  Err(this.error);
}

class SessionExpiredEvent {}

class ApiClient {
  final http.Client _httpClient;
  final Uuid _uuid = const Uuid();
  final Future<String?> Function(bool forceRefresh)? tokenProvider;

  // Single-flight refresh token lock
  Future<String?>? _refreshTokenFuture;

  static final StreamController<SessionExpiredEvent> _sessionExpiredController =
      StreamController<SessionExpiredEvent>.broadcast();

  static Stream<SessionExpiredEvent> get onSessionExpired =>
      _sessionExpiredController.stream;

  @visibleForTesting
  static void dispatchSessionExpiredForTest() {
    _sessionExpiredController.add(SessionExpiredEvent());
  }

  ApiClient({http.Client? httpClient, this.tokenProvider})
    : _httpClient = httpClient ?? http.Client();

  Future<Result<T>> get<T>(String path, {int retries = 2, int timeoutSeconds = 20}) async {
    return _request<T>('GET', path, maxRetries: retries, timeoutSeconds: timeoutSeconds);
  }

  Future<Result<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
    int timeoutSeconds = 20,
  }) async {
    return _request<T>(
      'POST',
      path,
      body: body,
      idempotencyKey: idempotencyKey,
      maxRetries: 0,
      timeoutSeconds: timeoutSeconds,
    );
  }

  Future<Result<T>> put<T>(String path, {Map<String, dynamic>? body, int timeoutSeconds = 20}) async {
    return _request<T>('PUT', path, body: body, maxRetries: 0, timeoutSeconds: timeoutSeconds);
  }

  Future<Result<T>> delete<T>(String path, {int timeoutSeconds = 20}) async {
    return _request<T>('DELETE', path, maxRetries: 0, timeoutSeconds: timeoutSeconds);
  }

  String _templatePath(String path) {
    final pathOnly = path.split('?').first;
    // Replace typical IDs (UUIDs, ObjectIds, numeric IDs) with :id
    return pathOnly.replaceAll(RegExp(r'\/[a-zA-Z0-9-]{10,}\b|\/\d+\b'), '/:id');
  }

  Future<Result<T>> _request<T>(
    String method,
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
    int maxRetries = 0,
    int currentRetry = 0,
    bool isRefreshRetry = false,
    int timeoutSeconds = 20,
  }) async {
    final uri = Uri.parse('${AppConfig.normalizedBaseUrl}$path');
    final String requestId = _uuid.v4();
    final stopwatch = Stopwatch()..start();

    try {
      final token = await _getToken(forceRefresh: false);
      final headers = <String, String>{
        'X-Request-Id': requestId,
        'Accept': 'application/json',
      };

      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
      if (idempotencyKey != null) {
        headers['Idempotency-Key'] = idempotencyKey;
      }
      if (body != null) {
        headers['Content-Type'] = 'application/json';
      }

      http.Response response;
      Future<http.Response> reqFuture;

      if (method == 'GET') {
        reqFuture = _httpClient.get(uri, headers: headers);
      } else if (method == 'POST') {
        reqFuture = _httpClient.post(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      } else if (method == 'PUT') {
        reqFuture = _httpClient.put(
          uri,
          headers: headers,
          body: body != null ? jsonEncode(body) : null,
        );
      } else if (method == 'DELETE') {
        reqFuture = _httpClient.delete(uri, headers: headers);
      } else {
        throw UnsupportedError('Method $method not supported');
      }

      // custom total per request
      response = await reqFuture.timeout(Duration(seconds: timeoutSeconds));

      stopwatch.stop();
      AppLogger.info(
        'API $method ${_templatePath(path)} ${response.statusCode} ${stopwatch.elapsedMilliseconds}ms',
      );

      return _handleResponse<T>(
        response: response,
        method: method,
        path: path,
        body: body,
        idempotencyKey: idempotencyKey,
        maxRetries: maxRetries,
        currentRetry: currentRetry,
        isRefreshRetry: isRefreshRetry,
        timeoutSeconds: timeoutSeconds,
      );
    } on TimeoutException {
      stopwatch.stop();
      AppLogger.info(
        'API $method ${_templatePath(path)} TIMEOUT ${stopwatch.elapsedMilliseconds}ms',
      );
      return _handleRetry<T>(
        method: method,
        path: path,
        body: body,
        idempotencyKey: idempotencyKey,
        maxRetries: maxRetries,
        currentRetry: currentRetry,
        failure: const TimeoutFailure('Request timed out. Please try again.'),
        timeoutSeconds: timeoutSeconds,
      );
    } catch (e) {
      stopwatch.stop();
      AppLogger.info(
        'API $method ${_templatePath(path)} NETWORK_ERR ${stopwatch.elapsedMilliseconds}ms',
      );
      return _handleRetry<T>(
        method: method,
        path: path,
        body: body,
        idempotencyKey: idempotencyKey,
        maxRetries: maxRetries,
        currentRetry: currentRetry,
        failure: const NetworkFailure(
          'Network error. Please check your connection.',
        ),
        timeoutSeconds: timeoutSeconds,
      );
    }
  }

  Future<Result<T>> _handleResponse<T>({
    required http.Response response,
    required String method,
    required String path,
    Map<String, dynamic>? body,
    String? idempotencyKey,
    required int maxRetries,
    required int currentRetry,
    required bool isRefreshRetry,
    required int timeoutSeconds,
  }) async {
    if (response.statusCode == 401) {
      if (!isRefreshRetry) {
        await _getToken(forceRefresh: true);
        return _request<T>(
          method,
          path,
          body: body,
          idempotencyKey: idempotencyKey,
          maxRetries: maxRetries,
          currentRetry: currentRetry,
          isRefreshRetry: true,
          timeoutSeconds: timeoutSeconds,
        );
      } else {
        _sessionExpiredController.add(SessionExpiredEvent());
        return Err(
          const UnauthorizedFailure('Session expired. Please log in again.'),
        );
      }
    }

    if (response.statusCode == 429) {
      final retryAfterStr = response.headers['retry-after'];
      int? retryAfter;
      if (retryAfterStr != null) {
        retryAfter = int.tryParse(retryAfterStr);
      }

      if (method == 'GET' &&
          retryAfter != null &&
          retryAfter <= 5 &&
          currentRetry < maxRetries) {
        await Future.delayed(Duration(seconds: retryAfter));
        return _request<T>(
          method,
          path,
          body: body,
          idempotencyKey: idempotencyKey,
          maxRetries: maxRetries,
          currentRetry: currentRetry + 1,
          isRefreshRetry: isRefreshRetry,
          timeoutSeconds: timeoutSeconds,
        );
      }

      return Err(
        RateLimitedFailure(
          'Too many requests. Please try again later.',
          retryAfter: retryAfter,
        ),
      );
    }

    if (response.statusCode == 502 ||
        response.statusCode == 503 ||
        response.statusCode == 504) {
      return _handleRetry<T>(
        method: method,
        path: path,
        body: body,
        idempotencyKey: idempotencyKey,
        maxRetries: maxRetries,
        currentRetry: currentRetry,
        failure: const ServerFailure('Server temporarily unavailable.'),
        timeoutSeconds: timeoutSeconds,
      );
    }

    dynamic jsonBody;
    try {
      jsonBody = jsonDecode(response.body);
    } catch (_) {
      return Err(const MalformedFailure('Invalid response from server.'));
    }

    if (jsonBody is! Map<String, dynamic>) {
      return Err(const MalformedFailure('Invalid response envelope.'));
    }

    final success = jsonBody['success'];
    if (success != true) {
      String errorMessage = 'Something went wrong. Please try again.';
      if (jsonBody['error'] is String) {
        final errStr = jsonBody['error'] as String;
        errorMessage = errStr.length > 200
            ? '${errStr.substring(0, 200)}...'
            : errStr;
      }

      if (response.statusCode == 400) {
        return Err(ValidationFailure(errorMessage));
      } else if (response.statusCode == 403) {
        return Err(ForbiddenFailure(errorMessage));
      } else if (response.statusCode == 404) {
        return Err(NotFoundFailure(errorMessage));
      } else if (response.statusCode == 409) {
        return Err(ConflictFailure(errorMessage));
      } else if (response.statusCode >= 500) {
        return Err(ServerFailure(errorMessage));
      }

      return Err(ValidationFailure(errorMessage));
    }

    if (!jsonBody.containsKey('data')) {
      return Err(const MalformedFailure('Missing data in response envelope.'));
    }

    return Ok(jsonBody['data'] as T);
  }

  Future<Result<T>> _handleRetry<T>({
    required String method,
    required String path,
    Map<String, dynamic>? body,
    String? idempotencyKey,
    required int maxRetries,
    required int currentRetry,
    required ApiFailure failure,
    required int timeoutSeconds,
  }) async {
    if (currentRetry < maxRetries) {
      final backoff = pow(2, currentRetry).toInt() * 1000;
      final jitter = Random().nextInt(500);
      await Future.delayed(Duration(milliseconds: backoff + jitter));

      return _request<T>(
        method,
        path,
        body: body,
        idempotencyKey: idempotencyKey,
        maxRetries: maxRetries,
        currentRetry: currentRetry + 1,
        timeoutSeconds: timeoutSeconds,
      );
    }
    return Err(failure);
  }

  Future<String?> _getToken({required bool forceRefresh}) async {
    if (forceRefresh) {
      if (_refreshTokenFuture != null) {
        return _refreshTokenFuture;
      }
      _refreshTokenFuture = _fetchToken(forceRefresh: true).whenComplete(() {
        _refreshTokenFuture = null;
      });
      return _refreshTokenFuture;
    } else {
      return _fetchToken(forceRefresh: false);
    }
  }

  Future<String?> _fetchToken({required bool forceRefresh}) async {
    if (tokenProvider != null) {
      return tokenProvider!(forceRefresh);
    }
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    return user.getIdToken(forceRefresh);
  }
}

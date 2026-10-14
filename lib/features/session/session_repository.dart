import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/models/user.dart';

final sessionRepositoryProvider = Provider<SessionRepository>((ref) {
  return SessionRepository(ref.watch(apiClientProvider));
});

class AuthSessionResponse {
  final User user;
  final bool onboardingCompleted;

  const AuthSessionResponse({
    required this.user,
    required this.onboardingCompleted,
  });
}

class SessionRepository {
  final ApiClient _apiClient;

  SessionRepository(this._apiClient);

  Future<AuthSessionResponse> authSession({
    String? displayName,
  }) async {
    final body = <String, dynamic>{};
    if (displayName != null) {
      body['displayName'] = displayName;
    }

    final result = await _apiClient.post<Map<String, dynamic>>(
      '/auth/session',
      body: body,
    );

    if (result is Err) {
      throw (result as Err).error;
    }

    final data = (result as Ok<Map<String, dynamic>>).data;

    if (data['user'] is! Map<String, dynamic>) {
      throw const FormatException('user object missing or wrong type');
    }
    if (data['onboardingCompleted'] is! bool) {
      throw const FormatException('onboardingCompleted missing or wrong type');
    }

    return AuthSessionResponse(
      user: User.fromJson(data['user'] as Map<String, dynamic>),
      onboardingCompleted: data['onboardingCompleted'] as bool,
    );
  }

  Future<User> getMe() async {
    final result = await _apiClient.get<Map<String, dynamic>>('/users/me');
    if (result is Err) {
      throw (result as Err).error;
    }
    final data = (result as Ok<Map<String, dynamic>>).data;
    return User.fromJson(data);
  }
}

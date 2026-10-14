import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../dto/user_profile_dto.dart';
import '../../../core/data/ttl_cache.dart';

final profileRepositoryProvider = Provider<ProfileRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return ProfileRepository(apiClient);
});

final meProvider = FutureProvider.autoDispose<UserProfileDto>((ref) async {
  final repo = ref.watch(profileRepositoryProvider);

  ref.cacheFor(const Duration(seconds: 60));

  final result = await repo.getMe();
  if (result is Ok<UserProfileDto>) {
    return result.data;
  } else {
    throw (result as Err).error;
  }
});

class ProfileRepository {
  final ApiClient _apiClient;

  ProfileRepository(this._apiClient);

  Future<Result<UserProfileDto>> getMe() async {
    final res = await _apiClient.get<Map<String, dynamic>>('/users/me');
    if (res is Ok<Map<String, dynamic>>) {
      try {
        final dto = UserProfileDto.fromJson(res.data);
        return Ok(dto);
      } catch (e) {
        return Err(const MalformedFailure('Failed to parse user profile'));
      }
    } else {
      return res as Err<UserProfileDto>;
    }
  }
}

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../dto/home_dto.dart';
import '../../../core/data/ttl_cache.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return DashboardRepository(apiClient);
});

final homeProvider = FutureProvider.autoDispose<HomeData>((ref) async {
  final repo = ref.watch(dashboardRepositoryProvider);

  ref.cacheFor(const Duration(seconds: 30));

  final result = await repo.getHomeData();
  if (result is Ok<HomeData>) {
    return result.data;
  } else {
    throw (result as Err).error;
  }
});

class DashboardRepository {
  final ApiClient _apiClient;

  DashboardRepository(this._apiClient);

  Future<Result<HomeData>> getHomeData() async {
    final res = await _apiClient.get<Map<String, dynamic>>('/dashboard/home');
    if (res is Ok<Map<String, dynamic>>) {
      try {
        final dto = HomeData.fromJson(res.data);
        return Ok(dto);
      } catch (e) {
        return Err(const MalformedFailure('Failed to parse home data'));
      }
    } else {
      return res as Err<HomeData>;
    }
  }
}

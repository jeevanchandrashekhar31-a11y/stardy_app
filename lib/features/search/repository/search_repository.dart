import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/courses/dto/course_dto.dart';
import 'package:stardy_app/features/opportunities/models/opportunity_models.dart';

class SearchResult<T> {
  final List<T> items;
  final String? nextCursor;

  SearchResult({required this.items, this.nextCursor});
}

class SearchRepository {
  final ApiClient _apiClient;

  SearchRepository(this._apiClient);

  Future<Result<SearchResult<CourseSummary>>> searchCourses(
    String query, {
    String? cursor,
    int limit = 10,
  }) async {
    final Map<String, String> queryParams = {
      'q': query,
      'type': 'COURSE',
      'limit': limit.toString(),
    };
    if (cursor != null) queryParams['cursor'] = cursor;

    final queryString = Uri(queryParameters: queryParams).query;
    final path = '/search?$queryString';

    final res = await _apiClient.get<Map<String, dynamic>>(path);
    if (res is Ok<Map<String, dynamic>>) {
      final data = res.data['items'] as List<dynamic>;
      final items = data.map((e) => CourseSummary.fromJson(e)).toList();
      final nextCursor = res.data['nextCursor'] as String?;
      return Ok(SearchResult(items: items, nextCursor: nextCursor));
    }
    return Err((res as Err).error);
  }

  Future<Result<SearchResult<OpportunitySummary>>> searchOpportunities(
    String query, {
    String? cursor,
    int limit = 10,
  }) async {
    final Map<String, String> queryParams = {
      'q': query,
      'type': 'OPPORTUNITY',
      'limit': limit.toString(),
    };
    if (cursor != null) queryParams['cursor'] = cursor;

    final queryString = Uri(queryParameters: queryParams).query;
    final path = '/search?$queryString';

    final res = await _apiClient.get<Map<String, dynamic>>(path);
    if (res is Ok<Map<String, dynamic>>) {
      final data = res.data['items'] as List<dynamic>;
      final items = data.map((e) => OpportunitySummary.fromJson(e)).toList();
      final nextCursor = res.data['nextCursor'] as String?;
      return Ok(SearchResult(items: items, nextCursor: nextCursor));
    }
    return Err((res as Err).error);
  }
}

final searchRepositoryProvider = Provider<SearchRepository>((ref) {
  return SearchRepository(ref.watch(apiClientProvider));
});

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../dto/grades_response.dart';

final gradesRepositoryProvider = Provider<GradesRepository>((ref) {
  return GradesRepository(ref.watch(apiClientProvider));
});

class GradesRepository {
  final ApiClient _apiClient;
  
  // Cache for grades by courseId (null for all).
  final Map<String, _GradesCacheEntry> _cache = {};
  
  static const Duration _cacheTtl = Duration(seconds: 30);

  GradesRepository(this._apiClient);

  void invalidateAfterProgress() {
    _cache.clear();
  }

  Future<Result<GradesResponse>> getGrades({
    String? courseId,
    String? cursor,
    int limit = 20,
  }) async {
    final cacheKey = '${courseId ?? 'all'}_$cursor';
    
    // Check cache
    if (_cache.containsKey(cacheKey)) {
      final entry = _cache[cacheKey]!;
      if (DateTime.now().difference(entry.timestamp) < _cacheTtl) {
        return Ok(entry.data);
      } else {
        _cache.remove(cacheKey);
      }
    }

    final queryParams = <String>[];
    if (courseId != null) queryParams.add('courseId=$courseId');
    if (cursor != null) queryParams.add('cursor=$cursor');
    queryParams.add('limit=$limit');

    final path = '/dashboard/grades?${queryParams.join('&')}';

    final res = await _apiClient.get<Map<String, dynamic>>(path);
    if (res is Ok<Map<String, dynamic>>) {
      try {
        final data = GradesResponse.fromJson(res.data);
        _cache[cacheKey] = _GradesCacheEntry(data, DateTime.now());
        return Ok(data);
      } catch (e) {
        return Err(ServerFailure('Failed to parse grades: $e'));
      }
    }
    
    return Err((res as Err).error);
  }
}

class _GradesCacheEntry {
  final GradesResponse data;
  final DateTime timestamp;

  _GradesCacheEntry(this.data, this.timestamp);
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/career_path_models.dart';

final careerPathsRepositoryProvider = Provider<CareerPathsRepository>((ref) {
  return CareerPathsRepository(ref.watch(apiClientProvider));
});

class CareerPathsRepository {
  final ApiClient _apiClient;
  
  final Map<String, _CacheEntry<CareerPathDetail>> _detailCache = {};
  static const Duration _detailCacheTtl = Duration(minutes: 5);

  CareerPathsRepository(this._apiClient);

  void invalidateCache(String pathId) {
    _detailCache.remove(pathId);
  }

  Future<Result<CareerPathDetail>> getCareerPath(String pathId) async {
    final cached = _detailCache[pathId];
    if (cached != null && DateTime.now().difference(cached.timestamp) < _detailCacheTtl) {
      return Ok(cached.data);
    }

    final res = await _apiClient.get<Map<String, dynamic>>('/career-paths/$pathId');
    if (res is Ok<Map<String, dynamic>>) {
      try {
        final data = CareerPathDetail.fromJson(res.data);
        _detailCache[pathId] = _CacheEntry(data, DateTime.now());
        return Ok(data);
      } catch (e) {
        return Err(ServerFailure('Failed to parse career path: $e'));
      }
    }
    return Err((res as Err).error);
  }

  Future<Result<bool>> enrollCareerPath(String pathId, String idempotencyKey) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/career-paths/$pathId/enroll',
      idempotencyKey: idempotencyKey,
    );
    if (res is Ok<Map<String, dynamic>>) {
      invalidateCache(pathId);
      return Ok(res.data['enrolled'] as bool? ?? true);
    }
    return Err((res as Err).error);
  }

  Future<Result<CareerPathProjectResponse>> getProject(String pathId) async {
    final res = await _apiClient.get<Map<String, dynamic>>('/career-paths/$pathId/project');
    if (res is Ok<Map<String, dynamic>>) {
      try {
        return Ok(CareerPathProjectResponse.fromJson(res.data));
      } catch (e) {
        return Err(ServerFailure('Failed to parse project: $e'));
      }
    }
    return Err((res as Err).error);
  }

  Future<Result<CareerPathProjectResponse>> generateProject(String pathId, String idempotencyKey) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/career-paths/$pathId/project',
      idempotencyKey: idempotencyKey,
      timeoutSeconds: 45,
    );
    if (res is Ok<Map<String, dynamic>>) {
      try {
        return Ok(CareerPathProjectResponse.fromJson(res.data));
      } catch (e) {
        return Err(ServerFailure('Failed to parse project: $e'));
      }
    }
    return Err((res as Err).error);
  }

  Future<Result<Map<String, dynamic>>> submitProject(
    String projectId,
    String idempotencyKey, {
    String? linkUrl,
    String? objectKey,
    String? fileName,
    int? sizeBytes,
  }) async {
    final body = <String, dynamic>{};
    if (linkUrl != null) body['linkUrl'] = linkUrl;
    if (objectKey != null) body['objectKey'] = objectKey;
    if (fileName != null) body['fileName'] = fileName;
    if (sizeBytes != null) body['sizeBytes'] = sizeBytes;

    final res = await _apiClient.post<Map<String, dynamic>>(
      '/projects/$projectId/submission',
      body: body,
      idempotencyKey: idempotencyKey,
    );

    if (res is Ok<Map<String, dynamic>>) {
      return Ok(res.data);
    }
    return Err((res as Err).error);
  }
}

class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  _CacheEntry(this.data, this.timestamp);
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/opportunity_models.dart';

abstract class OpportunityRepository {
  Future<Result<PaginatedResponse<OpportunitySummary>>> getOpportunities({
    String? type,
    String? category,
    String? cursor,
    int limit = 10,
  });

  Future<Result<OpportunityDetail>> getOpportunity(String id);

  Future<Result<OpportunityApplyResponse>> apply(
    String id,
    String idempotencyKey, {
    String? coverNote,
  });
}

class OpportunityRepositoryImpl implements OpportunityRepository {
  final ApiClient _api;
  
  final Map<String, _CacheEntry<PaginatedResponse<OpportunitySummary>>> _listCache = {};
  final Map<String, _CacheEntry<OpportunityDetail>> _detailCache = {};
  static const Duration _cacheTtl = Duration(seconds: 30);
  
  OpportunityRepositoryImpl(this._api);

  @override
  Future<Result<PaginatedResponse<OpportunitySummary>>> getOpportunities({
    String? type,
    String? category,
    String? cursor,
    int limit = 10,
  }) async {
    final query = <String, String>{
      'limit': limit.toString(),
      if (type != null && type.isNotEmpty) 'type': type,
      if (category != null && category.isNotEmpty) 'category': category,
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };
    
    final qs = Uri(queryParameters: query).query;
    final cacheKey = '/opportunities?$qs';
    
    final cached = _listCache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.timestamp) < _cacheTtl) {
      return Ok(cached.data);
    }

    final res = await _api.get(cacheKey);
    
    if (res is Err) return Err(res.error);
    
    final data = (res as Ok).data;
    final items = (data['items'] as List?)
            ?.map((e) => OpportunitySummary.fromJson(e))
            .toList() ??
        [];
    final nextCursor = data['nextCursor'] as String?;
    
    final response = PaginatedResponse(items, nextCursor);
    _listCache[cacheKey] = _CacheEntry(response, DateTime.now());
    
    return Ok(response);
  }

  @override
  Future<Result<OpportunityDetail>> getOpportunity(String id) async {
    final cacheKey = '/opportunities/$id';
    final cached = _detailCache[cacheKey];
    if (cached != null && DateTime.now().difference(cached.timestamp) < _cacheTtl) {
      return Ok(cached.data);
    }

    final res = await _api.get(cacheKey);
    
    if (res is Err) return Err(res.error);
    final detail = OpportunityDetail.fromJson((res as Ok).data);
    _detailCache[cacheKey] = _CacheEntry(detail, DateTime.now());
    return Ok(detail);
  }

  @override
  Future<Result<OpportunityApplyResponse>> apply(
    String id,
    String idempotencyKey, {
    String? coverNote,
  }) async {
    final body = <String, dynamic>{};
    if (coverNote != null && coverNote.isNotEmpty) {
      body['coverNote'] = coverNote;
    }
    
    final res = await _api.post(
      '/opportunities/$id/apply',
      body: body,
      idempotencyKey: idempotencyKey,
    );
    
    if (res is Err) return Err(res.error);
    return Ok(OpportunityApplyResponse.fromJson((res as Ok).data));
  }
}

final opportunityRepositoryProvider = Provider<OpportunityRepository>((ref) {
  return OpportunityRepositoryImpl(ref.watch(apiClientProvider));
});

class PaginatedResponse<T> {
  final List<T> items;
  final String? nextCursor;

  PaginatedResponse(this.items, this.nextCursor);
}

class _CacheEntry<T> {
  final T data;
  final DateTime timestamp;
  _CacheEntry(this.data, this.timestamp);
}

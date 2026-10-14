import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/courses/dto/course_dto.dart';
import 'package:stardy_app/features/opportunities/models/opportunity_models.dart';
import '../repository/search_repository.dart';

class SearchState<T> {
  final bool isIdle;
  final bool isLoading;
  final List<T>? items;
  final String? error;
  final bool isRateLimited;
  final String? nextCursor;

  const SearchState({
    this.isIdle = true,
    this.isLoading = false,
    this.items,
    this.error,
    this.isRateLimited = false,
    this.nextCursor,
  });

  SearchState<T> copyWith({
    bool? isIdle,
    bool? isLoading,
    List<T>? items,
    String? error,
    bool? isRateLimited,
    String? nextCursor,
    bool clearError = false,
  }) {
    return SearchState<T>(
      isIdle: isIdle ?? this.isIdle,
      isLoading: isLoading ?? this.isLoading,
      items: items ?? this.items,
      error: clearError ? null : (error ?? this.error),
      isRateLimited: isRateLimited ?? this.isRateLimited,
      nextCursor: nextCursor ?? this.nextCursor,
    );
  }
}

class SearchNotifier<T> extends StateNotifier<SearchState<T>> {
  final Future<Result<SearchResult<T>>> Function(String query, {String? cursor}) _searchFunc;
  
  int _requestCounter = 0;
  String _lastQuery = '';

  SearchNotifier(this._searchFunc) : super(SearchState<T>());

  void clear() {
    _requestCounter++;
    _lastQuery = '';
    state = SearchState<T>();
  }

  Future<void> search(String query) async {
    final cleaned = query.trim().replaceAll(RegExp(r'\s+'), ' ');
    if (cleaned.length < 2 || cleaned.length > 60) {
      clear();
      return;
    }

    _lastQuery = cleaned;
    _requestCounter++;
    final currentReq = _requestCounter;

    state = state.copyWith(
      isIdle: false,
      isLoading: true,
      error: null,
      clearError: true,
      isRateLimited: false,
    );

    final res = await _searchFunc(cleaned);

    if (currentReq != _requestCounter) {
      return; // Stale request
    }

    if (res is Ok<SearchResult<T>>) {
      state = state.copyWith(
        isLoading: false,
        items: res.data.items,
        nextCursor: res.data.nextCursor,
      );
    } else {
      final err = (res as Err).error;
      if (err is RateLimitedFailure) {
        state = state.copyWith(isLoading: false, isRateLimited: true);
      } else {
        state = state.copyWith(isLoading: false, error: err.message);
      }
    }
  }

  Future<void> retry() async {
    if (_lastQuery.isNotEmpty) {
      await search(_lastQuery);
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.nextCursor == null || _lastQuery.isEmpty) return;

    final currentReq = _requestCounter;
    final res = await _searchFunc(_lastQuery, cursor: state.nextCursor);

    if (currentReq != _requestCounter) return;

    if (res is Ok<SearchResult<T>>) {
      state = state.copyWith(
        items: [...?state.items, ...res.data.items],
        nextCursor: res.data.nextCursor,
      );
    }
  }

  void markOpportunityApplied(String id) {
    if (state.items == null) return;
    
    // Check if T is OpportunitySummary
    if (T == OpportunitySummary) {
      final updated = state.items!.map((e) {
        if (e is OpportunitySummary && e.id == id) {
          final opp = e as OpportunitySummary;
          return opp.copyWith(hasApplied: true) as T;
        }
        return e;
      }).toList();
      state = state.copyWith(items: updated);
    }
  }
}

final courseSearchProvider = StateNotifierProvider.autoDispose<SearchNotifier<CourseSummary>, SearchState<CourseSummary>>((ref) {
  final repo = ref.watch(searchRepositoryProvider);
  return SearchNotifier((q, {cursor}) => repo.searchCourses(q, cursor: cursor));
});

final opportunitySearchProvider = StateNotifierProvider.autoDispose<SearchNotifier<OpportunitySummary>, SearchState<OpportunitySummary>>((ref) {
  final repo = ref.watch(searchRepositoryProvider);
  return SearchNotifier((q, {cursor}) => repo.searchOpportunities(q, cursor: cursor));
});

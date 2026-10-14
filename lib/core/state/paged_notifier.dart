import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../ui/error_view.dart';

import '../models/page.dart' as model;

class PagedState<T> {
  final List<T> items;
  final String? nextCursor;
  final bool isLoading;
  final String? error;
  final bool hasMore;

  const PagedState({
    required this.items,
    this.nextCursor,
    required this.isLoading,
    this.error,
    required this.hasMore,
  });

  PagedState<T> copyWith({
    List<T>? items,
    String? Function()? nextCursor,
    bool? isLoading,
    String? Function()? error,
    bool? hasMore,
  }) {
    return PagedState<T>(
      items: items ?? this.items,
      nextCursor: nextCursor != null ? nextCursor() : this.nextCursor,
      isLoading: isLoading ?? this.isLoading,
      error: error != null ? error() : this.error,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

abstract class PagedNotifier<T> extends StateNotifier<PagedState<T>> {
  PagedNotifier()
    : super(PagedState<T>(items: <T>[], isLoading: false, hasMore: true));

  Future<model.Page<T>> fetchPage({String? cursor, int limit = 20});

  Future<void> loadFirst({int limit = 20}) async {
    if (state.isLoading) return;
    state = state.copyWith(isLoading: true, error: () => null);

    try {
      final page = await fetchPage(limit: limit);
      state = state.copyWith(
        items: page.items,
        nextCursor: () => page.nextCursor,
        hasMore: page.nextCursor != null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: () => safeErrorText(e));
    }
  }

  Future<void> loadMore({int limit = 20}) async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true, error: () => null);

    try {
      final page = await fetchPage(cursor: state.nextCursor, limit: limit);
      state = state.copyWith(
        items: [...state.items, ...page.items],
        nextCursor: () => page.nextCursor,
        hasMore: page.nextCursor != null,
        isLoading: false,
      );
    } catch (e) {
      // Keeps previous items
      state = state.copyWith(isLoading: false, error: () => safeErrorText(e));
    }
  }

  Future<void> refresh({int limit = 20}) async {
    state = PagedState<T>(items: <T>[], isLoading: false, hasMore: true);
    await loadFirst(limit: limit);
  }
}

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/grade_models.dart';
import '../repository/grades_repository.dart';

class GradesState {
  final List<GradeItem> items;
  final String? nextCursor;
  final bool hasMore;
  final bool isLoadingMore;

  const GradesState({
    this.items = const [],
    this.nextCursor,
    this.hasMore = true,
    this.isLoadingMore = false,
  });

  GradesState copyWith({
    List<GradeItem>? items,
    String? nextCursor,
    bool? hasMore,
    bool? isLoadingMore,
  }) {
    // Note: Since nextCursor can be null to indicate no more items,
    // we need to pass a special way to set it to null or just use hasMore flag.
    return GradesState(
      items: items ?? this.items,
      nextCursor: nextCursor, // will replace null if nextCursor is explicitly passed? Actually, if nextCursor is null, how to clear it? Just use hasMore.
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

// We need a family provider to handle courseId
final gradesProvider = AutoDisposeAsyncNotifierProviderFamily<GradesNotifier, GradesState, String?>(() {
  return GradesNotifier();
});

class GradesNotifier extends AutoDisposeFamilyAsyncNotifier<GradesState, String?> {
  late GradesRepository _repo;

  @override
  Future<GradesState> build(String? arg) async {
    _repo = ref.watch(gradesRepositoryProvider);
    return _fetchInitial();
  }

  Future<GradesState> _fetchInitial() async {
    final res = await _repo.getGrades(courseId: arg, limit: 20);
    if (res is Ok) {
      final data = (res as Ok).data;
      return GradesState(
        items: data.items,
        nextCursor: data.nextCursor,
        hasMore: data.nextCursor != null,
        isLoadingMore: false,
      );
    } else {
      throw (res as Err).error;
    }
  }

  Future<void> fetchMore() async {
    final currentState = state.valueOrNull;
    if (currentState == null || !currentState.hasMore || currentState.isLoadingMore) {
      return;
    }

    state = AsyncValue.data(currentState.copyWith(isLoadingMore: true, nextCursor: currentState.nextCursor));

    final res = await _repo.getGrades(courseId: arg, cursor: currentState.nextCursor, limit: 20);

    if (res is Ok) {
      final data = (res as Ok).data;
      state = AsyncValue.data(
        GradesState(
          items: [...currentState.items, ...data.items],
          nextCursor: data.nextCursor,
          hasMore: data.nextCursor != null,
          isLoadingMore: false,
        ),
      );
    } else {
      // Revert loading state, keep items
      state = AsyncValue.data(currentState.copyWith(isLoadingMore: false, nextCursor: currentState.nextCursor));
      // Optionally surface error somehow, but usually infinite scroll errors are just a toast or a retry button
    }
  }
  
  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = await AsyncValue.guard(() => _fetchInitial());
  }
}

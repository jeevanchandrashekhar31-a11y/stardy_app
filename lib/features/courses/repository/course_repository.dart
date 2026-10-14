import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../../../core/models/gamification_result.dart';
import '../dto/course_dto.dart';
import '../../../core/data/ttl_cache.dart';
import '../models/course_enums.dart';

final courseRepositoryProvider = Provider<CourseRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return CourseRepository(apiClient);
});

class PagedCourseResult {
  final List<CourseSummary> items;
  final String? nextCursor;

  PagedCourseResult({required this.items, this.nextCursor});
}

class CompleteModuleResult {
  final bool isCompleted;
  final GamificationResult? gamification;

  CompleteModuleResult({
    required this.isCompleted,
    this.gamification,
  });
}

class CourseRepository {
  final ApiClient _apiClient;

  CourseRepository(this._apiClient);

  Future<Result<PagedCourseResult>> listCourses({
    Difficulty? difficulty,
    CourseCategory? category,
    String? cursor,
    int? limit,
  }) async {
    final queryParams = <String, String>{};
    if (difficulty != null && difficulty != Difficulty.unknown) {
      queryParams['difficulty'] = difficulty.name.toUpperCase();
    }
    if (category != null && category != CourseCategory.unknown) {
      queryParams['category'] = category.name.toUpperCase();
    }
    if (cursor != null) {
      queryParams['cursor'] = cursor;
    }
    if (limit != null) {
      queryParams['limit'] = limit.toString();
    }

    final uri = Uri(path: '/courses', queryParameters: queryParams.isNotEmpty ? queryParams : null);
    
    final res = await _apiClient.get<Map<String, dynamic>>(uri.toString());
    if (res is Ok<Map<String, dynamic>>) {
      try {
        final list = res.data['items'] as List<dynamic>;
        final items = list.map((e) => CourseSummary.fromJson(e as Map<String, dynamic>)).toList();
        final nextCursor = res.data['nextCursor'] as String?;
        return Ok(PagedCourseResult(items: items, nextCursor: nextCursor));
      } catch (e) {
        return Err(const MalformedFailure('Failed to parse courses data'));
      }
    } else {
      return Err((res as Err).error);
    }
  }

  Future<Result<CourseDetail>> getCourse(String id) async {
    final res = await _apiClient.get<Map<String, dynamic>>('/courses/$id');
    if (res is Ok<Map<String, dynamic>>) {
      try {
        final dto = CourseDetail.fromJson(res.data);
        return Ok(dto);
      } catch (e) {
        return Err(const MalformedFailure('Failed to parse course detail'));
      }
    } else {
      return Err((res as Err).error);
    }
  }

  Future<Result<List<ResourceItem>>> getResources(String courseId) async {
    final res = await _apiClient.get<Map<String, dynamic>>('/courses/$courseId/resources');
    if (res is Ok<Map<String, dynamic>>) {
      try {
        final list = res.data['items'] as List<dynamic>;
        final items = list.map((e) => ResourceItem.fromJson(e as Map<String, dynamic>)).toList();
        return Ok(items);
      } catch (e) {
        return Err(const MalformedFailure('Failed to parse resources data'));
      }
    } else {
      return Err((res as Err).error);
    }
  }

  Future<Result<ModuleContent>> getModuleContent(String moduleId) async {
    final res = await _apiClient.get<Map<String, dynamic>>('/modules/$moduleId/content');
    if (res is Ok<Map<String, dynamic>>) {
      try {
        final dto = ModuleContent.fromJson(res.data);
        return Ok(dto);
      } catch (e) {
        return Err(const MalformedFailure('Failed to parse module content'));
      }
    } else {
      return Err((res as Err).error);
    }
  }

  Future<Result<CompleteModuleResult>> completeModule(String moduleId, String idempotencyKey) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/modules/$moduleId/complete',
      body: {}, // No body specified in contract
      idempotencyKey: idempotencyKey,
    );
    
    if (res is Ok<Map<String, dynamic>>) {
      try {
        final isCompleted = res.data['isCompleted'] as bool;
        GamificationResult? gamification;
        if (res.data['gamification'] != null) {
          gamification = GamificationResult.fromJson(res.data['gamification'] as Map<String, dynamic>);
        }
        return Ok(CompleteModuleResult(
          isCompleted: isCompleted,
          gamification: gamification,
        ));
      } catch (e) {
        return Err(const MalformedFailure('Failed to parse complete module response'));
      }
    } else {
      return Err((res as Err).error);
    }
  }
}

// State class for paged lists
class PagedCourseState {
  final List<CourseSummary> items;
  final String? nextCursor;
  final bool isLoadingMore;

  PagedCourseState({
    required this.items,
    this.nextCursor,
    this.isLoadingMore = false,
  });

  PagedCourseState copyWith({
    List<CourseSummary>? items,
    String? nextCursor,
    bool? isLoadingMore,
    bool clearCursor = false,
  }) {
    return PagedCourseState(
      items: items ?? this.items,
      nextCursor: clearCursor ? null : (nextCursor ?? this.nextCursor),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
    );
  }
}

class CourseListArgs {
  final Difficulty? difficulty;
  final CourseCategory? category;

  const CourseListArgs({this.difficulty, this.category});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CourseListArgs &&
          runtimeType == other.runtimeType &&
          difficulty == other.difficulty &&
          category == other.category;

  @override
  int get hashCode => difficulty.hashCode ^ category.hashCode;
}

class CourseListNotifier extends AutoDisposeFamilyAsyncNotifier<PagedCourseState, CourseListArgs> {
  late CourseRepository _repo;

  @override
  FutureOr<PagedCourseState> build(CourseListArgs arg) async {
    _repo = ref.watch(courseRepositoryProvider);
    final result = await _repo.listCourses(
      difficulty: arg.difficulty,
      category: arg.category,
      limit: 20,
    );
    
    if (result is Ok<PagedCourseResult>) {
      return PagedCourseState(
        items: result.data.items,
        nextCursor: result.data.nextCursor,
      );
    } else {
      throw (result as Err).error;
    }
  }

  Future<void> loadMore() async {
    final current = state.valueOrNull;
    if (current == null || current.nextCursor == null || current.isLoadingMore) {
      return;
    }

    state = AsyncData(current.copyWith(isLoadingMore: true));

    try {
      final result = await _repo.listCourses(
        difficulty: arg.difficulty,
        category: arg.category,
        cursor: current.nextCursor,
        limit: 20,
      );

      if (result is Ok<PagedCourseResult>) {
        state = AsyncData(current.copyWith(
          items: [...current.items, ...result.data.items],
          nextCursor: result.data.nextCursor,
          isLoadingMore: false,
          clearCursor: result.data.nextCursor == null,
        ));
      } else {
        throw (result as Err).error;
      }
    } catch (e) {
      state = AsyncData(current.copyWith(isLoadingMore: false)); // Revert loading state
      // Actually we could set error state, but typical pagination keeps items
      // In a real app we'd broadcast an error event
    }
  }
}

final courseListProvider = AsyncNotifierProvider.autoDispose.family<CourseListNotifier, PagedCourseState, CourseListArgs>(
  CourseListNotifier.new,
);

final AutoDisposeFutureProviderFamily<CourseDetail, String> courseDetailProvider = FutureProvider.autoDispose.family<CourseDetail, String>((ref, String courseId) async {
  final repo = ref.watch(courseRepositoryProvider);

  ref.cacheFor(const Duration(seconds: 60));

  final result = await repo.getCourse(courseId);
  if (result is Ok<CourseDetail>) {
    return result.data;
  } else {
    throw (result as Err).error;
  }
});

final AutoDisposeFutureProviderFamily<List<ResourceItem>, String> resourcesProvider = FutureProvider.autoDispose.family<List<ResourceItem>, String>((ref, String courseId) async {
  final repo = ref.watch(courseRepositoryProvider);

  ref.cacheFor(const Duration(minutes: 5));

  final result = await repo.getResources(courseId);
  if (result is Ok<List<ResourceItem>>) {
    return result.data;
  } else {
    throw (result as Err).error;
  }
});

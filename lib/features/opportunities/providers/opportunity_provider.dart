import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/opportunity_models.dart';
import '../repository/opportunity_repository.dart';
import '../../../core/ui/error_view.dart';

class OpportunityFilter {
  final String type; // INTERNSHIP, FREELANCE
  final String category; // CREATIVE, BUSINESS, TECH

  const OpportunityFilter({required this.type, required this.category});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OpportunityFilter &&
          runtimeType == other.runtimeType &&
          type == other.type &&
          category == other.category;

  @override
  int get hashCode => type.hashCode ^ category.hashCode;
}

class OpportunityListState {
  final List<OpportunitySummary> items;
  final String? nextCursor;
  final bool isLoading;
  final String? error;

  const OpportunityListState({
    required this.items,
    this.nextCursor,
    this.isLoading = false,
    this.error,
  });

  OpportunityListState copyWith({
    List<OpportunitySummary>? items,
    String? nextCursor,
    bool? isLoading,
    String? error,
  }) {
    return OpportunityListState(
      items: items ?? this.items,
      nextCursor: nextCursor ?? this.nextCursor,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class OpportunityListNotifier
    extends AutoDisposeFamilyNotifier<OpportunityListState, OpportunityFilter> {
  late OpportunityRepository _repo;

  @override
  OpportunityListState build(OpportunityFilter arg) {
    _repo = ref.watch(opportunityRepositoryProvider);
    _fetchFirstPage();
    return const OpportunityListState(items: [], isLoading: true);
  }

  Future<void> _fetchFirstPage() async {
    try {
      final res = await _repo.getOpportunities(
        type: arg.type,
        category: arg.category,
        limit: 10,
      );

      if (res is Ok<PaginatedResponse<OpportunitySummary>>) {
        state = state.copyWith(
          items: res.data.items,
          nextCursor: res.data.nextCursor,
          isLoading: false,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          error: (res as Err).error.message,
        );
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, error: safeErrorText(e));
    }
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.nextCursor == null) return;

    state = state.copyWith(isLoading: true, error: null);
    final res = await _repo.getOpportunities(
      type: arg.type,
      category: arg.category,
      cursor: state.nextCursor,
      limit: 10,
    );

    if (res is Ok<PaginatedResponse<OpportunitySummary>>) {
      state = state.copyWith(
        items: [...state.items, ...res.data.items],
        nextCursor: res.data.nextCursor,
        isLoading: false,
      );
    } else {
      state = state.copyWith(
        isLoading: false,
        error: (res as Err).error.message,
      );
    }
  }

  void markApplied(String id) {
    final newItems = state.items.map((item) {
      if (item.id == id) {
        return OpportunitySummary(
          id: item.id,
          title: item.title,
          company: item.company,
          location: item.location,
          type: item.type,
          category: item.category,
          isPaid: item.isPaid,
          logoUrl: item.logoUrl,
          hasApplied: true,
        );
      }
      return item;
    }).toList();
    state = state.copyWith(items: newItems);
  }
}

final opportunityListProvider = AutoDisposeNotifierProviderFamily<OpportunityListNotifier,
    OpportunityListState, OpportunityFilter>(OpportunityListNotifier.new);

final opportunityDetailProvider = FutureProvider.family<OpportunityDetail, String>((ref, id) async {
  final repo = ref.watch(opportunityRepositoryProvider);
  final res = await repo.getOpportunity(id);
  if (res is Ok<OpportunityDetail>) {
    return res.data;
  }
  throw (res as Err).error;
});

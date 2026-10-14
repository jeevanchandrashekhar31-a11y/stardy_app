import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardy_app/Views/widgets/color_codes.dart';
import 'package:stardy_app/features/search/providers/search_provider.dart';
import 'package:stardy_app/Views/Courses/Course_Source/course_card.dart';
import 'package:stardy_app/Views/widgets/Opportunity_Source/opportunity_card.dart';

class SearchPage extends ConsumerStatefulWidget {
  const SearchPage({super.key});

  @override
  ConsumerState<SearchPage> createState() => _SearchPageState();
}

class _SearchPageState extends ConsumerState<SearchPage> with SingleTickerProviderStateMixin {
  final TextEditingController _queryController = TextEditingController();
  late TabController _tabController;
  Timer? _debounceTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _queryController.dispose();
    _tabController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onSearchChanged(String val) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(const Duration(milliseconds: 400), () {
      final query = val.trim().replaceAll(RegExp(r'\s+'), ' ');
      if (query.length > 60) return; // Prevent extreme lengths though handled by maxLength
      
      ref.read(courseSearchProvider.notifier).search(val);
      ref.read(opportunitySearchProvider.notifier).search(val);
    });
  }

  @override
  Widget build(BuildContext context) {
    final queryText = _queryController.text.trim().replaceAll(RegExp(r'\s+'), ' ');

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: TextField(
          controller: _queryController,
          autofocus: true,
          maxLength: 60,
          onChanged: _onSearchChanged,
          decoration: InputDecoration(
            hintText: 'Search...',
            border: InputBorder.none,
            counterText: '',
            suffixIcon: queryText.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, color: Colors.black54),
                    onPressed: () {
                      _queryController.clear();
                      _onSearchChanged('');
                      setState(() {}); // refresh suffix icon
                    },
                  )
                : null,
          ),
          style: const TextStyle(fontSize: 16),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.black54,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Courses'),
            Tab(text: 'Opportunities'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _CourseSearchTab(query: queryText),
          _OpportunitySearchTab(query: queryText),
        ],
      ),
    );
  }
}

class _CourseSearchTab extends ConsumerWidget {
  final String query;
  const _CourseSearchTab({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.length < 2) {
      return _buildIdleState();
    }

    final state = ref.watch(courseSearchProvider);

    if (state.isLoading && (state.items == null || state.items!.isEmpty)) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state.isRateLimited) {
      return _buildMessageState('Too many requests. Please wait and try again.', Icons.speed);
    }

    if (state.error != null) {
      return _buildErrorState(state.error!, () => ref.read(courseSearchProvider.notifier).retry());
    }

    final items = state.items;
    if (items != null && items.isEmpty) {
      return _buildMessageState('No courses found', Icons.search_off);
    }

    if (items == null) {
      return const SizedBox();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        // Lazy load
        if (index == items.length - 2 && state.nextCursor != null) {
          ref.read(courseSearchProvider.notifier).loadMore();
        }

        return CourseCard(course: items[index]);
      },
    );
  }

  Widget _buildIdleState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.black12),
          SizedBox(height: 16),
          Text(
            'Type at least 2 characters...',
            style: TextStyle(color: Colors.black45, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.black12),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.black45, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class _OpportunitySearchTab extends ConsumerWidget {
  final String query;
  const _OpportunitySearchTab({required this.query});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (query.length < 2) {
      return _buildIdleState();
    }

    final state = ref.watch(opportunitySearchProvider);

    if (state.isLoading && (state.items == null || state.items!.isEmpty)) {
      return const Center(child: CircularProgressIndicator(color: AppColors.primary));
    }

    if (state.isRateLimited) {
      return _buildMessageState('Too many requests. Please wait and try again.', Icons.speed);
    }

    if (state.error != null) {
      return _buildErrorState(state.error!, () => ref.read(opportunitySearchProvider.notifier).retry());
    }

    final items = state.items;
    if (items != null && items.isEmpty) {
      return _buildMessageState('No opportunities found', Icons.search_off);
    }

    if (items == null) {
      return const SizedBox();
    }

    return ListView.builder(
      padding: const EdgeInsets.all(20),
      itemCount: items.length + (state.isLoading ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == items.length) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }

        // Lazy load
        if (index == items.length - 2 && state.nextCursor != null) {
          ref.read(opportunitySearchProvider.notifier).loadMore();
        }

        return OpportunityCard(
          opp: items[index],
          onApplied: () {
            ref.read(opportunitySearchProvider.notifier).markOpportunityApplied(items[index].id);
          },
        );
      },
    );
  }

  Widget _buildIdleState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search, size: 64, color: Colors.black12),
          SizedBox(height: 16),
          Text(
            'Type at least 2 characters...',
            style: TextStyle(color: Colors.black45, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.black12),
          const SizedBox(height: 16),
          Text(
            message,
            style: const TextStyle(color: Colors.black45, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error, VoidCallback onRetry) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.redAccent),
          const SizedBox(height: 16),
          Text(
            error,
            style: const TextStyle(color: Colors.redAccent, fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Retry', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

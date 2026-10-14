import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardy_app/Views/widgets/color_codes.dart';
import '../../features/opportunities/providers/opportunity_provider.dart';
import '../widgets/Opportunity_Source/opportunity_card.dart';

class OpportunitiesPage extends ConsumerStatefulWidget {
  const OpportunitiesPage({super.key});

  @override
  ConsumerState<OpportunitiesPage> createState() => _OpportunitiesPageState();
}

class _OpportunitiesPageState extends ConsumerState<OpportunitiesPage> {
  bool _showInternships = true;
  String _category = 'TECH'; // Default to TECH

  void _onScroll(ScrollNotification scrollInfo) {
    if (scrollInfo.metrics.pixels >= scrollInfo.metrics.maxScrollExtent - 200) {
      final filter = OpportunityFilter(
        type: _showInternships ? 'INTERNSHIP' : 'FREELANCE',
        category: _category,
      );
      ref.read(opportunityListProvider(filter).notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final filter = OpportunityFilter(
      type: _showInternships ? 'INTERNSHIP' : 'FREELANCE',
      category: _category,
    );
    final state = ref.watch(opportunityListProvider(filter));
    final items = state.items;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 10),
              _topBar(),
              const SizedBox(height: 16),
              // Search bar UI preserved as requested, though search API is a separate scope
              _searchBar(),
              const SizedBox(height: 16),
              _tabs(),
              const SizedBox(height: 12),
              _categoryChips(),
              const SizedBox(height: 12),
              Expanded(
                child: items.isEmpty && !state.isLoading
                    ? _buildEmptyState()
                    : NotificationListener<ScrollNotification>(
                        onNotification: (scrollInfo) {
                          _onScroll(scrollInfo);
                          return true;
                        },
                        child: ListView.builder(
                          itemCount: items.length + (state.isLoading ? 1 : 0),
                          itemBuilder: (context, index) {
                            if (index == items.length) {
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(
                                  child: CircularProgressIndicator(
                                      color: AppColors.primary),
                                ),
                              );
                            }
                            return OpportunityCard(
                              opp: items[index],
                              onApplied: () {
                                ref.read(opportunityListProvider(filter).notifier).markApplied(items[index].id);
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =====================================================
  // TOP BAR
  // =====================================================
  Widget _topBar() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Icon(Icons.notifications_none, color: AppColors.primaryDark),
    );
  }

  // =====================================================
  // SEARCH BAR
  // =====================================================
  Widget _searchBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: AppColors.textSecondary),
          SizedBox(width: 10),
          Expanded(
            child: TextField(
              style: TextStyle(color: AppColors.textPrimary),
              decoration: InputDecoration(
                hintText: 'Search internships, skills or companies',
                hintStyle: TextStyle(color: AppColors.textSecondary),
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // TABS
  // =====================================================
  Widget _tabs() {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(child: _tabButton('Internships', _showInternships, true)),
          Expanded(child: _tabButton('Projects', !_showInternships, false)),
        ],
      ),
    );
  }

  Widget _tabButton(String label, bool selected, bool isInternships) {
    return GestureDetector(
      onTap: () {
        if (_showInternships != isInternships) {
          setState(() {
            _showInternships = isInternships;
          });
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : Colors.transparent,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Center(
          child: Text(
            label,
            style: TextStyle(
              color: selected ? Colors.white : Colors.black54,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // CATEGORIES
  // =====================================================
  Widget _categoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: ['CREATIVE', 'BUSINESS', 'TECH'].map((cat) {
          final isSelected = _category == cat;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ChoiceChip(
              label: Text(cat),
              selected: isSelected,
              selectedColor: AppColors.primary,
              onSelected: (selected) {
                if (selected) {
                  setState(() => _category = cat);
                }
              },
            ),
          );
        }).toList(),
      ),
    );
  }

  // =====================================================
  // EMPTY STATE
  // =====================================================
  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset('assets/images/illustration_empty_state.png', width: 160),
          const SizedBox(height: 16),
          const Text(
            'No results found',
            style: TextStyle(
              color: AppColors.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Try a different category or tab',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

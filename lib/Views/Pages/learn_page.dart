import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import '../../features/gamification/repository/gamification_repository.dart';
import '../../features/courses/repository/course_repository.dart';
import '../../features/courses/dto/course_dto.dart';
import '../../features/courses/models/course_enums.dart';

import 'package:stardy_app/Views/Courses/Course_Source/course_card.dart';
import 'package:stardy_app/Views/widgets/color_codes.dart';
import '../widgets/New_carousel_course/carousel_course_card.dart';

class Learnpage extends ConsumerStatefulWidget {
  const Learnpage({super.key});

  @override
  ConsumerState<Learnpage> createState() => _LearnpageState();
}

class _LearnpageState extends ConsumerState<Learnpage> {
  bool showStreak = true;
  Timer? _streakTimer;
  
  CourseCategory? _selectedCategory;
  Difficulty? _selectedDifficulty;
  
  final ScrollController _scrollController = ScrollController();

  final List<CourseCategory?> _categories = [null, CourseCategory.creative, CourseCategory.business, CourseCategory.tech];
  final List<Difficulty?> _difficulties = [null, Difficulty.beginner, Difficulty.intermediate, Difficulty.advanced];

  @override
  void initState() {
    super.initState();
    _streakTimer = Timer(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() {
          showStreak = false;
        });
      }
    });
    
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent * 0.8) {
      final args = CourseListArgs(category: _selectedCategory, difficulty: _selectedDifficulty);
      ref.read(courseListProvider(args).notifier).loadMore();
    }
  }

  @override
  void dispose() {
    _streakTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () async {
            final args = CourseListArgs(category: _selectedCategory, difficulty: _selectedDifficulty);
            ref.invalidate(courseListProvider(args));
          },
          child: CustomScrollView(
            controller: _scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 10),
                      _topBar(),
                      _streakBannerWidget(),
                      _searchBar(),
                      _filtersSection(),
                    ],
                  ),
                ),
              ),
              _buildCoursesSection(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _streakBannerWidget() {
    final gamificationAsync = ref.watch(gamificationProvider);
    final streak = gamificationAsync.valueOrNull?.currentStreak ?? 0;
    final bool shouldShowStreak = showStreak && !gamificationAsync.isLoading && !gamificationAsync.hasError && streak > 0;
    
    if (!shouldShowStreak) return const SizedBox.shrink();
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 15),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.5),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                "Continue your $streak day learning Streak !! 🔥",
                style: const TextStyle(color: Colors.white),
              ),
            ),
            GestureDetector(
              onTap: () {
                setState(() {
                  showStreak = false;
                });
              },
              child: const Icon(Icons.close, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }

  Widget _topBar() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Icon(Icons.notifications_none, color: AppColors.primaryDark),
    );
  }

  Widget _searchBar() {
    return Container(
      height: 50,
      margin: const EdgeInsets.only(top: 15, bottom: 15),
      padding: const EdgeInsets.symmetric(horizontal: 15),
      decoration: BoxDecoration(
        color: AppColors.secondary,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: const Row(
        children: [
          Icon(Icons.search, color: AppColors.textSecondary),
          SizedBox(width: 10),
          Text("Search", style: TextStyle(color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _filtersSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((c) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _categoryChip(c),
            )).toList(),
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _difficulties.map((d) => Padding(
              padding: const EdgeInsets.only(right: 10),
              child: _difficultyChip(d),
            )).toList(),
          ),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  Widget _categoryChip(CourseCategory? category) {
    final bool selected = _selectedCategory == category;
    final text = category == null ? "All" : category.name.toUpperCase();
    return _buildChip(text, selected, () {
      setState(() => _selectedCategory = category);
    });
  }

  Widget _difficultyChip(Difficulty? difficulty) {
    final bool selected = _selectedDifficulty == difficulty;
    final text = difficulty == null ? "All" : difficulty.name.toUpperCase();
    return _buildChip(text, selected, () {
      setState(() => _selectedDifficulty = difficulty);
    });
  }

  Widget _buildChip(String text, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.primaryDark : AppColors.secondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: selected
                  ? AppColors.primaryDark.withValues(alpha: 0.6)
                  : Colors.black.withValues(alpha: 0.25),
              blurRadius: selected ? 14 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          text,
          style: TextStyle(
            color: selected ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildCoursesSection() {
    final args = CourseListArgs(category: _selectedCategory, difficulty: _selectedDifficulty);
    final asyncState = ref.watch(courseListProvider(args));

    return asyncState.when(
      data: (state) {
        if (state.items.isEmpty) {
          return const SliverFillRemaining(
            child: Center(
              child: Text(
                "No courses found for these filters.",
                style: TextStyle(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "New Courses",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 15),
                      _carousel(state.items),
                      const SizedBox(height: 25),
                      const Text(
                        "Continue Learning",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(height: 15),
                    ],
                  ),
                );
              }
              
              final itemIndex = index - 1;
              if (itemIndex < state.items.length) {
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: CourseCard(course: state.items[itemIndex]),
                );
              } else if (state.isLoadingMore) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: CircularProgressIndicator()),
                );
              } else if (state.nextCursor == null) {
                return const Padding(
                  padding: EdgeInsets.all(16.0),
                  child: Center(child: Text("You've reached the end", style: TextStyle(color: AppColors.textSecondary))),
                );
              }
              return const SizedBox.shrink();
            },
            childCount: 1 + state.items.length + (state.nextCursor != null || state.isLoadingMore ? 1 : 0),
          ),
        );
      },
      loading: () => const SliverFillRemaining(
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, st) {
        final state = ref.read(courseListProvider(args)).valueOrNull;
        if (state != null && state.items.isNotEmpty) {
          // Keep items but show error footer
          return SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                if (index == 0) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          "New Courses",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 15),
                        _carousel(state.items),
                        const SizedBox(height: 25),
                        const Text(
                          "Continue Learning",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 15),
                      ],
                    ),
                  );
                }
                
                final itemIndex = index - 1;
                if (itemIndex < state.items.length) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: CourseCard(course: state.items[itemIndex]),
                  );
                } else {
                  return Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        const Text("Failed to load more courses", style: TextStyle(color: Colors.red)),
                        ElevatedButton(
                          onPressed: () => ref.read(courseListProvider(args).notifier).loadMore(),
                          child: const Text("Retry"),
                        ),
                      ],
                    ),
                  );
                }
              },
              childCount: 1 + state.items.length + 1,
            ),
          );
        }

        // Completely failed to load initial list
        return SliverFillRemaining(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Failed to load courses.", style: TextStyle(color: Colors.red)),
                ElevatedButton(
                  onPressed: () => ref.invalidate(courseListProvider(args)),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _carousel(List<CourseSummary> items) {
    final carouselItems = items.take(3).toList();
    if (carouselItems.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 270,
      child: CarouselSlider.builder(
        itemCount: carouselItems.length,
        options: CarouselOptions(
          height: 270,
          enlargeCenterPage: true,
          viewportFraction: 0.75,
          autoPlay: true,
        ),
        itemBuilder: (context, index, realIndex) {
          return CarouselCourseCard(course: carouselItems[index]);
        },
      ),
    );
  }
}


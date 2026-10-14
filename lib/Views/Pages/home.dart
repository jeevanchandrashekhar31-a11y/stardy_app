import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/config/feature_flags.dart';
import '../Courses/course_details_page.dart';
import '../starbuddy/starbuddy_screen.dart';
import '../widgets/color_codes.dart';
import '../widgets/New_carousel_course/carousel_course_card.dart';
import '../../features/dashboard/repository/dashboard_repository.dart';
import '../../features/dashboard/dto/home_dto.dart';
import '../../features/courses/dto/course_dto.dart';
import '../CareerPath/career_path_detail_page.dart';
import 'search_page.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final homeAsync = ref.watch(homeProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: homeAsync.when(
          data: (data) => _buildBody(context, data, ref),
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, st) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text("Failed to load home data", style: TextStyle(color: Colors.red)),
                ElevatedButton(
                  onPressed: () => ref.invalidate(homeProvider),
                  child: const Text("Retry"),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, HomeData data, WidgetRef ref) {
    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(homeProvider),
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 10),
            _buildTopBar(),
            const SizedBox(height: 20),
            _buildGreeting(data.greetingName),
            const SizedBox(height: 16),
            _buildSearchBar(context),
            const SizedBox(height: 24),
            _buildContinueSection(context, data.continueCourse),
            if (data.careerPaths.isNotEmpty) ...[
              const SizedBox(height: 24),
              _buildCareerPathSection(context, data.careerPaths.first),
            ],
            if (FeatureFlags.starbuddy) ...[
              const SizedBox(height: 16),
              _buildStarbuddyCard(context),
            ],
            const SizedBox(height: 24),
            if (data.recommended.isNotEmpty) ...[
              _buildCourseCarousel('Recommended for You', data.recommended),
              const SizedBox(height: 24),
            ],
            if (data.newCourses.isNotEmpty) ...[
              _buildCourseCarousel('New Courses', data.newCourses),
              const SizedBox(height: 24),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
    );
  }

  // ───────────────── TOP BAR ─────────────────
  Widget _buildTopBar() {
    return const Align(
      alignment: Alignment.centerLeft,
      child: Icon(Icons.notifications_none, color: AppColors.primaryDark),
    );
  }

  // ───────────────── GREETING ─────────────────
  Widget _buildGreeting(String name) {
    return Text(
      'Hi $name',
      style: const TextStyle(
        color: AppColors.textPrimary,
        fontSize: 24,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  // ───────────────── SEARCH BAR ─────────────────
  Widget _buildSearchBar(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: '/search'),
            builder: (_) => const SearchPage(),
          ),
        );
      },
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
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
            Text('Search', style: TextStyle(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ───────────────── CONTINUE SECTION ─────────────────
  Widget _buildContinueSection(BuildContext context, ContinueCourse? course) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          course != null ? 'Continue course' : 'Start a new course',
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        if (course != null)
          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  settings: const RouteSettings(name: '/course-details'),
                  builder: (_) => CourseDetailsPage(courseId: course.courseId),
                ),
              );
            },
            child: Container(
              width: double.infinity,
              height: 190,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: AppColors.primaryDark,
                image: course.thumbnailUrl != null
                    ? DecorationImage(
                        image: CachedNetworkImageProvider(course.thumbnailUrl!),
                        fit: BoxFit.cover,
                      )
                    : null,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withValues(alpha: 0.15),
                      Colors.black.withValues(alpha: 0.75),
                    ],
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${course.progressPercent}% completed',
                      style: const TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: course.progressPercent / 100.0,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                    ),
                    const Spacer(),
                    Align(
                      alignment: Alignment.bottomRight,
                      child: Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.15),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const Icon(
                          Icons.play_arrow,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        else
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.secondary,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
            ),
            child: const Text(
              "You don't have any active courses. Browse the Learn tab to find something new!",
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
      ],
    );
  }

  // ───────────────── CAREER PATH SECTION ─────────────────
  Widget _buildCareerPathSection(BuildContext context, CareerPathSummary path) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Your Career Path',
          style: TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                settings: const RouteSettings(name: '/career-path-detail'),
                builder: (_) => CareerPathDetailPage(
                  pathId: path.id,
                ),
              ),
            );
          },
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        path.title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${path.progress}% completed',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: path.progress / 100.0,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ───────────────── MEET STARBUDDY ─────────────────
  Widget _buildStarbuddyCard(BuildContext context) {
    if (!FeatureFlags.starbuddy) return const SizedBox.shrink();
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const StarbuddyScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppColors.primaryDark,
                shape: BoxShape.circle,
              ),
              child: ClipOval(
                child: Image.asset(
                  'assets/images/starbuddy_avatar.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 14),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Meet Starbuddy !!',
                    style: TextStyle(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Your star mentor is here\ntap to chat and ask any question ...',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ───────────────── COURSE CAROUSEL ─────────────────
  Widget _buildCourseCarousel(String title, List<CourseSummary> courses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontSize: 17,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 270,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: courses.length,
            itemBuilder: (context, index) {
              return SizedBox(
                width: MediaQuery.of(context).size.width * 0.75,
                child: CarouselCourseCard(course: courses[index]),
              );
            },
          ),
        ),
      ],
    );
  }
}

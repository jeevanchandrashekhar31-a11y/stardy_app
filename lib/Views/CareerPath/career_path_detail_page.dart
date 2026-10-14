import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ui/error_view.dart';
import 'package:uuid/uuid.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/color_codes.dart';
import 'module_list_page.dart';
import '../Courses/course_details_page.dart';
import '../../features/career_paths/providers/career_paths_provider.dart';
import '../../features/career_paths/repository/career_paths_repository.dart';
import '../../features/career_paths/models/career_path_models.dart';
import '../../core/network/api_client.dart';

class CareerPathDetailPage extends ConsumerStatefulWidget {
  final String pathId;

  const CareerPathDetailPage({super.key, required this.pathId});

  @override
  ConsumerState<CareerPathDetailPage> createState() => _CareerPathDetailPageState();
}

class _CareerPathDetailPageState extends ConsumerState<CareerPathDetailPage> {
  bool _isEnrolling = false;

  void _startCourse(CareerPathDetail path) async {
    if (_isEnrolling) return;

    if (!path.enrolled) {
      setState(() => _isEnrolling = true);
      final repo = ref.read(careerPathsRepositoryProvider);
      final key = const Uuid().v4();
      final res = await repo.enrollCareerPath(widget.pathId, key);
      setState(() => _isEnrolling = false);
      
      if (res is Ok<bool>) {
        ref.invalidate(careerPathDetailProvider(widget.pathId));
        // Open the first course
        if (path.courses.isNotEmpty) {
          if (!mounted) return;
          _openCourse(path.courses.first.courseId);
        }
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text((res as Err).error.message)),
        );
      }
    } else {
      // Find first incomplete course
      final incomplete = path.courses.firstWhere(
        (c) => c.progressPercent != 100,
        orElse: () => path.courses.isNotEmpty ? path.courses.first : const CareerPathCourse(courseId: '', title: '', difficulty: 'BEGINNER', order: 0),
      );
      if (incomplete.courseId.isNotEmpty) {
        _openCourse(incomplete.courseId);
      }
    }
  }

  void _openCourse(String courseId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        settings: const RouteSettings(name: '/course-details'),
        builder: (_) => CourseDetailsPage(courseId: courseId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detailAsync = ref.watch(careerPathDetailProvider(widget.pathId));

    return Scaffold(
      backgroundColor: const Color(0xffF5F5F5),
      body: detailAsync.when(
        data: (path) => _buildBody(context, path),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, st) => ErrorView(
          message: safeErrorText(err),
          onRetry: () => ref.invalidate(careerPathDetailProvider(widget.pathId)),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CareerPathDetail path) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            padding: const EdgeInsets.only(top: 60, left: 24, right: 24, bottom: 20),
            decoration: const BoxDecoration(
              color: AppColors.primaryDark,
              image: DecorationImage(
                image: AssetImage('assets/images/texture_dark_grid.png'),
                fit: BoxFit.cover,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  path.title.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  path.description,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 13, height: 1.5),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white38),
                      ),
                      child: const Icon(Icons.arrow_outward, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(30),
                        border: Border.all(color: Colors.white38),
                      ),
                      child: const Text(
                        'Skills to Know',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                Wrap(
                  spacing: 16,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  children: path.skills.map((s) => _BulletText(s)).toList(),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isEnrolling ? null : () => _startCourse(path),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    child: _isEnrolling 
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white))
                      : Text(
                          path.enrolled ? 'Continue' : 'Start Course',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // UPCOMING SECTION
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Upcoming',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        settings: const RouteSettings(name: '/module-list'),
                        builder: (_) => ModuleListPage(pathId: path.id),
                      ),
                    );
                  },
                  child: const Text(
                    'See all',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),

        // LIST OF 2 UPCOMING
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final incompleteCourses = path.courses.where((c) => c.progressPercent != 100).toList();
                if (index >= incompleteCourses.length || index >= 2) return null;
                return _buildUpcomingCard(context, incompleteCourses[index]);
              },
              childCount: 2,
            ),
          ),
        ),
        
        const SliverToBoxAdapter(child: SizedBox(height: 40)),
      ],
    );
  }

  Widget _buildUpcomingCard(BuildContext context, CareerPathCourse course) {
    return GestureDetector(
      onTap: () => _openCourse(course.courseId),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.primaryDark,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(14),
              child: course.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: course.thumbnailUrl!,
                      width: 64,
                      height: 64,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(width: 64, height: 64, color: Colors.grey),
                    )
                  : Container(width: 64, height: 64, color: Colors.grey),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      course.difficulty,
                      style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.title,
                    style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BulletText extends StatelessWidget {
  final String text;
  const _BulletText(this.text);

  @override
  Widget build(BuildContext context) {
    return Text(
      '•  $text',
      style: const TextStyle(color: Colors.white70, fontSize: 13),
    );
  }
}

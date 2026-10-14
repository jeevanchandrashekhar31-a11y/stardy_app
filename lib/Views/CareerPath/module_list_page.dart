import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ui/error_view.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../widgets/color_codes.dart';
import 'project_assignment_brief_page.dart';
import '../Courses/course_details_page.dart';
import '../../features/career_paths/providers/career_paths_provider.dart';
import '../../features/career_paths/models/career_path_models.dart';

class ModuleListPage extends ConsumerWidget {
  final String pathId;

  const ModuleListPage({super.key, required this.pathId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detailAsync = ref.watch(careerPathDetailProvider(pathId));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Color(0xff9A9A9A)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: detailAsync.when(
              data: (path) => _buildBody(context, path),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, st) => ErrorView(
                message: safeErrorText(err),
                onRetry: () => ref.invalidate(careerPathDetailProvider(pathId)),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context, CareerPathDetail path) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8),
              ],
            ),
            child: const Icon(Icons.chevron_left, color: Colors.black),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...path.courses.map((course) => _buildModuleTile(context, course)),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ProjectAssignmentBriefPage(
                          pathId: path.id,
                        ),
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: const BoxDecoration(
                          color: AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.flag_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 14),
                      const Expanded(
                        child: Text(
                          "YAY ! You've finished it ! (Project)",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildModuleTile(BuildContext context, CareerPathCourse course) {
    return GestureDetector(
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
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.black26),
        ),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: course.thumbnailUrl != null
                  ? CachedNetworkImage(
                      imageUrl: course.thumbnailUrl!,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorWidget: (_, _, _) => Container(width: 60, height: 60, color: Colors.grey),
                    )
                  : Container(width: 60, height: 60, color: Colors.grey),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      course.difficulty,
                      style: const TextStyle(color: Colors.white, fontSize: 10),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    course.title,
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  if (course.progressPercent != null) ...[
                    const SizedBox(height: 4),
                    LinearProgressIndicator(value: course.progressPercent! / 100.0),
                  ]
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

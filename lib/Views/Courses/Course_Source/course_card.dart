import 'package:flutter/material.dart';
import '../../widgets/color_codes.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../Courses/course_details_page.dart';
import '../../../features/courses/dto/course_dto.dart';

class CourseCard extends StatelessWidget {
  final CourseSummary course;

  const CourseCard({super.key, required this.course});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            settings: const RouteSettings(name: '/course-details'),
            builder: (_) => CourseDetailsPage(courseId: course.id),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppColors.secondary,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 10,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            // ───────── IMAGE ─────────
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: course.thumbnailUrl == null
                  ? Container(
                      height: 90,
                      width: 90,
                      color: AppColors.primary.withValues(alpha: 0.1),
                      child: const Icon(
                        Icons.menu_book_outlined,
                        color: AppColors.primary,
                      ),
                    )
                  : CachedNetworkImage(
                      imageUrl: course.thumbnailUrl!,
                      height: 90,
                      width: 90,
                      fit: BoxFit.cover,
                      memCacheWidth: 400,
                      placeholder: (context, url) => Container(
                        height: 90,
                        width: 90,
                        color: AppColors.primary.withValues(alpha: 0.1),
                      ),
                      errorWidget: (context, url, error) => Container(
                        height: 90,
                        width: 90,
                        color: AppColors.primary.withValues(alpha: 0.1),
                        child: const Icon(Icons.error, color: AppColors.primary),
                      ),
                    ),
            ),

            const SizedBox(width: 12),

            // ───────── CONTENT ─────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // TITLE + RATING
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          course.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      if (course.ratingCount > 0)
                        Row(
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.orange,
                              size: 16,
                            ),
                            const SizedBox(width: 2),
                            Text(
                              course.ratingAvg.toStringAsFixed(1),
                              style: const TextStyle(
                                color: Colors.orange,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),

                  const SizedBox(height: 6),

                  // CATEGORY
                  Text(
                    '${course.category.name.toUpperCase()} • ${course.difficulty.name.toUpperCase()}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // PROGRESS BAR
                  Builder(
                    builder: (context) {
                      final clampedProgress = (course.progressPercent ?? 0) / 100.0;
                      return Row(
                        children: [
                          Expanded(
                            child: LinearProgressIndicator(
                              value: clampedProgress,
                              backgroundColor: Colors.grey[800],
                              color: AppColors.primary,
                              minHeight: 5,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "${(clampedProgress * 100).toInt()}%",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // ───────── BUTTON ─────────
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: const StadiumBorder(),
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 8,
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    settings: const RouteSettings(name: '/course-details'),
                    builder: (_) => CourseDetailsPage(courseId: course.id),
                  ),
                );
              },
              child: const Text(
                "Resume",
                style: TextStyle(color: Colors.white, fontSize: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

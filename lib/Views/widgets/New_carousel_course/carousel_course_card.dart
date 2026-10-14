import 'dart:ui';
import 'package:flutter/material.dart';

import 'package:cached_network_image/cached_network_image.dart';
import '../../../features/courses/dto/course_dto.dart';
import '../../Courses/course_details_page.dart';
import '../color_codes.dart';

class CarouselCourseCard extends StatelessWidget {
  final CourseSummary course;

  const CarouselCourseCard({super.key, required this.course});

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
        width: double.infinity,
        margin: const EdgeInsets.symmetric(horizontal: 4),

        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),

          child: Container(
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              image: course.thumbnailUrl == null
                  ? null
                  : DecorationImage(
                      image: CachedNetworkImageProvider(course.thumbnailUrl!, maxWidth: 400),
                      fit: BoxFit.cover,
                    ),
            ),

            child: Container(
              padding: const EdgeInsets.all(18),

              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,

                  colors: [
                    Colors.black.withValues(alpha: 0.65),
                    Colors.black.withValues(alpha: 0.15),
                    Colors.black.withValues(alpha: 0.82),
                  ],
                ),
              ),

              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,

                children: [
                  // =====================================================
                  // TOP SECTION
                  // =====================================================
                  Row(
                    children: [
                      // CATEGORY CHIP
                      Expanded(
                        child: Align(
                          alignment: Alignment.centerLeft,

                          child: _topChip(
                            text: course.category.name.toUpperCase(),
                            color: Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                      ),

                      const SizedBox(width: 10),

                      if (course.ratingCount > 0)
                        Align(
                          alignment: Alignment.centerRight,
                          child: _topChip(
                            text: "⭐ ${course.ratingAvg.toStringAsFixed(1)}",
                            color: AppColors.primary.withValues(alpha: 0.4),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 18),

                  // =====================================================
                  // TITLE
                  // =====================================================
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,

                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 220),

                      child: Text(
                        course.title,

                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,

                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),

                  // =====================================================
                  // DESCRIPTION
                  // =====================================================
                  Flexible(
                    child: Text(
                      course.difficulty.name.toUpperCase(),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 12,
                        height: 1.4,
                      ),
                    ),
                  ),

                  const Spacer(),

                  // =====================================================
                  // INFO SECTION
                  // =====================================================
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,

                    child: Row(
                      children: [
                        _infoChip(icon: Icons.schedule, text: _formatDuration(course.durationSeconds)),

                        const SizedBox(width: 8),

                        _infoChip(
                          icon: Icons.layers,
                          text: "${course.moduleCount} modules",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 14),

                  // =====================================================
                  // BOTTOM ROW
                  // =====================================================
                  Row(
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            Container(
                              height: 10,
                              width: 10,

                              decoration: const BoxDecoration(
                                color: Colors.green,
                                shape: BoxShape.circle,
                              ),
                            ),

                            const SizedBox(width: 8),

                            const Expanded(
                              child: Text(
                                "Available Now",

                                overflow: TextOverflow.ellipsis,

                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(width: 10),

                      _glassButton(context),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // =====================================================
  // TOP CHIP
  // =====================================================

  Widget _topChip({required String text, required Color color}) {
    return IntrinsicWidth(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),

        decoration: BoxDecoration(
          color: color,

          borderRadius: BorderRadius.circular(30),

          border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
        ),

        child: Text(
          text,

          maxLines: 1,
          overflow: TextOverflow.ellipsis,

          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // =====================================================
  // INFO CHIP
  // =====================================================

  Widget _infoChip({required IconData icon, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),

      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),

        borderRadius: BorderRadius.circular(14),
      ),

      child: Row(
        mainAxisSize: MainAxisSize.min,

        children: [
          Icon(icon, color: Colors.white, size: 14),

          const SizedBox(width: 5),

          Text(
            text,

            overflow: TextOverflow.ellipsis,

            style: const TextStyle(color: Colors.white, fontSize: 11),
          ),
        ],
      ),
    );
  }

  // =====================================================
  // GLASS BUTTON
  // =====================================================

  Widget _glassButton(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(50),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: const Icon(Icons.arrow_outward, color: Colors.white, size: 18),
        ),
      ),
    );
  }

  String _formatDuration(int? seconds) {
    if (seconds == null || seconds == 0) return "TBA";
    if (seconds < 3600) {
      return "${seconds ~/ 60}m";
    } else {
      final hours = seconds ~/ 3600;
      final mins = (seconds % 3600) ~/ 60;
      return "${hours}h ${mins}m";
    }
  }
}

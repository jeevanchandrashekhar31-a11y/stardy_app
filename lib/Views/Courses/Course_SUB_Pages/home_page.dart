import 'package:flutter/material.dart';
import '../../widgets/color_codes.dart';
import '../Course_Source/video_learning_page.dart';
import 'assignment_page.dart';
import '../../../features/courses/dto/course_dto.dart';
import '../../../features/courses/models/course_enums.dart';
import '../../../features/courses/models/course_formatters.dart';

class HomePage extends StatelessWidget {
  final CourseDetail courseDetail;

  const HomePage({super.key, required this.courseDetail});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildProgressSection(),
          const SizedBox(height: 25),
          _buildDescriptionSection(),
          const SizedBox(height: 30),
          _buildModulesSection(context),
          const SizedBox(height: 30),
          _buildAssignmentSection(context),
          const SizedBox(height: 100),
        ],
      ),
    );
  }

  Widget _buildProgressSection() {
    final progress = courseDetail.progressPercent ?? 0;
    final boundedProgress = (progress / 100.0).clamp(0.0, 1.0).toDouble();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "$progress% Module completed",
          style: const TextStyle(color: AppColors.primaryDark),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: AppColors.primaryDark.withValues(alpha: 0.2),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: boundedProgress,
                    backgroundColor: AppColors.secondary,
                    color: AppColors.primary,
                    minHeight: 8,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const Row(
              children: [
                Icon(Icons.download_outlined),
                SizedBox(width: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Download',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text('200 MB', style: TextStyle(fontSize: 8)),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          "${courseDetail.assignments.length} Assignments due",
          style: const TextStyle(color: Colors.grey),
        ),
      ],
    );
  }

  Widget _buildDescriptionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Description",
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          courseDetail.description,
          style: const TextStyle(color: Colors.grey, height: 1.5),
        ),
      ],
    );
  }

  Widget _buildModulesSection(BuildContext context) {
    if (courseDetail.modules.isEmpty) {
      return const Text(
        "No modules available.",
        style: TextStyle(color: Colors.grey, fontSize: 16),
      );
    }

    final List<Widget> groupWidgets = [];
    String? currentSection = courseDetail.modules.first.section;
    List<ModuleItem> currentGroup = [];

    for (final module in courseDetail.modules) {
      if (module.section == currentSection) {
        currentGroup.add(module);
      } else {
        groupWidgets.add(_buildModuleGroup(context, currentSection ?? 'Lessons', currentGroup));
        currentSection = module.section;
        currentGroup = [module];
      }
    }
    if (currentGroup.isNotEmpty) {
      groupWidgets.add(_buildModuleGroup(context, currentSection ?? 'Lessons', currentGroup));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: groupWidgets,
    );
  }

  Widget _buildModuleGroup(BuildContext context, String sectionName, List<ModuleItem> modules) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          sectionName,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 16),
        for (int i = 0; i < modules.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildModuleCard(context, modules[i]),
          ),
      ],
    );
  }

  Widget _buildModuleCard(BuildContext context, ModuleItem module) {
    IconData icon;
    switch (module.contentType) {
      case ContentType.video:
        icon = Icons.play_circle_outline;
        break;
      case ContentType.text:
        icon = Icons.article_outlined;
        break;
      case ContentType.audio:
        icon = Icons.audiotrack_outlined;
        break;
      default:
        icon = Icons.insert_drive_file_outlined;
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => VideoLearningPage(
              moduleId: module.id,
              title: module.title,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 4),
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
                    module.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      _darkTag(formatContentType(module.contentType)),
                      if (module.durationSeconds != null) ...[
                        const SizedBox(width: 10),
                        _darkTag(formatDuration(module.durationSeconds)),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            if (module.isCompleted)
              const Icon(Icons.check_circle, color: Colors.green, size: 28)
            else
              Container(
                height: 44,
                width: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.primary, width: 1.5),
                ),
                child: Icon(
                  icon,
                  color: AppColors.primary,
                ),
              ),
          ],
        ),
      ),
    );
  }

  String formatContentType(ContentType type) {
    switch (type) {
      case ContentType.video:
        return 'Video';
      case ContentType.text:
        return 'Reading';
      case ContentType.audio:
        return 'Audio';
      case ContentType.unknown:
        return 'Content';
    }
  }

  Widget _buildAssignmentSection(BuildContext context) {
    if (courseDetail.assignments.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Assignments",
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 20),
        for (int i = 0; i < courseDetail.assignments.length; i++) ...[
          if (i > 0) const SizedBox(height: 16),
          _buildAssignmentCard(
            context,
            courseDetail.assignments[i],
          ),
        ],
      ],
    );
  }

  Widget _buildAssignmentCard(BuildContext context, AssignmentRef assignment) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AssignmentPage(assignmentId: assignment.id, title: assignment.title), 
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              height: 60,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.orange.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Icon(
                Icons.assignment,
                color: Colors.orange,
                size: 30,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    assignment.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (assignment.dueAt != null) ...[
                    const SizedBox(height: 8),
                    Text("Due: ${assignment.dueAt}", style: const TextStyle(color: Colors.grey)),
                  ],
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _darkTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 12),
      ),
    );
  }
}

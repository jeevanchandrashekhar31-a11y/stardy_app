import 'package:flutter/material.dart';

import 'package:stardy_app/Views/widgets/color_codes.dart';

import 'Course_SUB_Pages/home_page.dart';
import 'Course_SUB_Pages/grades_page.dart';
import 'Course_SUB_Pages/notes_page.dart';
import 'Course_SUB_Pages/resources_page.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/ui/error_view.dart';
import '../../features/courses/repository/course_repository.dart';

class CourseDetailsPage extends ConsumerStatefulWidget {
  final String courseId;

  const CourseDetailsPage({super.key, required this.courseId});

  @override
  ConsumerState<CourseDetailsPage> createState() => _CourseDetailsPageState();
}

class _CourseDetailsPageState extends ConsumerState<CourseDetailsPage> {
  int selectedTab = 0;

  final List<String> tabs = ["Home", "Grades", "Notes", "Resources"];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.secondary,

      appBar: AppBar(
        backgroundColor: AppColors.secondary,

        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),

        title: Text(
          ref.watch(courseDetailProvider(widget.courseId)).maybeWhen(
            data: (detail) => detail.title,
            orElse: () => 'Loading...',
          ),
          style: const TextStyle(
            color: AppColors.primaryDark,
            fontWeight: FontWeight.bold,
          ),
        ),

        actions: [
          IconButton(
            tooltip: 'History',
            icon: const Icon(Icons.access_time, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Course history coming soon')),
              );
            },
          ),
          IconButton(
            tooltip: 'More options',
            icon: const Icon(Icons.more_vert, color: Colors.black),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('More options coming soon')),
              );
            },
          ),
        ],

        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),

          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,

            children: List.generate(
              tabs.length,
              (index) => GestureDetector(
                onTap: () {
                  setState(() {
                    selectedTab = index;
                  });
                },

                child: _tab(tabs[index], selectedTab == index),
              ),
            ),
          ),
        ),
      ),

      body: ref.watch(courseDetailProvider(widget.courseId)).when(
        data: (courseDetail) => _buildPage(courseDetail),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => ErrorView(
          message: safeErrorText(err),
          onRetry: () => ref.invalidate(courseDetailProvider(widget.courseId)),
        ),
      ),
    );
  }

  Widget _buildPage(dynamic courseDetail) {
    switch (selectedTab) {
      case 0:
        return HomePage(courseDetail: courseDetail);

      case 1:
        return GradesPage(courseId: widget.courseId);

      case 2:
        return const NotesPage();

      case 3:
        return ResourcesPage(courseId: widget.courseId);

      default:
        return HomePage(courseDetail: courseDetail);
    }
  }

  Widget _tab(String text, bool selected) {
    return Column(
      mainAxisSize: MainAxisSize.min,

      children: [
        Text(
          text,
          style: TextStyle(
            fontWeight: selected ? FontWeight.bold : FontWeight.normal,
            color: Colors.black,
          ),
        ),

        const SizedBox(height: 5),

        AnimatedContainer(
          duration: const Duration(milliseconds: 300),

          height: 4,
          width: 60,

          decoration: BoxDecoration(
            color: selected ? Colors.black : Colors.transparent,

            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ],
    );
  }
}

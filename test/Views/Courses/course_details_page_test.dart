import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/Views/Courses/course_details_page.dart';
import 'package:stardy_app/features/courses/repository/course_repository.dart';
import 'package:stardy_app/features/courses/dto/course_dto.dart';
import 'package:stardy_app/features/courses/models/course_enums.dart';
import 'dart:async';

void main() {
  group('CourseDetailsPage Tests', () {
    testWidgets('renders loading state initially', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            courseDetailProvider('c1').overrideWith(
              (ref) => Completer<CourseDetail>().future,
            ),
          ],
          child: const MaterialApp(
            home: CourseDetailsPage(courseId: 'c1'),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            courseDetailProvider('c1').overrideWith(
              (ref) => throw Exception('Failed to load'),
            ),
          ],
          child: const MaterialApp(
            home: CourseDetailsPage(courseId: 'c1'),
          ),
        ),
      );

      expect(find.textContaining('Something went wrong'), findsOneWidget);
    });

    testWidgets('renders success state and sections including null', (tester) async {
      final mockCourseDetail = CourseDetail(
        id: 'c1',
        title: 'Test Course',
        description: 'A test course',
        durationSeconds: 3600,
        progressPercent: 50,
        category: CourseCategory.tech,
        difficulty: Difficulty.beginner,
        ratingAvg: 4.5,
        ratingCount: 10,
        moduleCount: 5,
        createdAt: '2026-01-01',
        modules: [
          ModuleItem(
            id: 'm1',
            title: 'Module 1',
            contentType: ContentType.video,
            section: 'Introduction',
            durationSeconds: 600,
            isCompleted: true,
            order: 0,
          ),
          ModuleItem(
            id: 'm2',
            title: 'Module 2',
            contentType: ContentType.text,
            section: 'Introduction', // same section
            durationSeconds: 300,
            isCompleted: false,
            order: 1,
          ),
          ModuleItem(
            id: 'm3',
            title: 'Module 3',
            contentType: ContentType.video,
            section: null, // null section
            durationSeconds: 120,
            isCompleted: false,
            order: 2,
          ),
          ModuleItem(
            id: 'm4',
            title: 'Module 4',
            contentType: ContentType.text,
            section: 'Interleaved', // new section
            durationSeconds: 500,
            isCompleted: false,
            order: 3,
          ),
          ModuleItem(
            id: 'm5',
            title: 'Module 5',
            contentType: ContentType.audio,
            section: 'Introduction', // interleaved section back to Intro
            durationSeconds: 600,
            isCompleted: false,
            order: 4,
          ),
        ],
        assignments: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            courseDetailProvider('c1').overrideWith(
              (ref) => mockCourseDetail,
            ),
          ],
          child: const MaterialApp(
            home: CourseDetailsPage(courseId: 'c1'),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check AppBar Title
      expect(find.text('Test Course'), findsOneWidget);
      expect(find.text('Description'), findsOneWidget);
      expect(find.text('A test course'), findsOneWidget);

      // Check section titles
      // We expect 'Introduction' to appear twice (because they are interleaved by 'Lessons' and 'Interleaved')
      final introFinders = find.text('Introduction');
      expect(introFinders, findsNWidgets(2));
      
      expect(find.text('Lessons'), findsOneWidget); // null section
      expect(find.text('Interleaved'), findsOneWidget); // new section

      // Check module items
      expect(find.text('Module 1'), findsOneWidget);
      expect(find.text('Module 2'), findsOneWidget);
      expect(find.text('Module 3'), findsOneWidget);
      expect(find.text('Module 4'), findsOneWidget);
      expect(find.text('Module 5'), findsOneWidget);
    });
  });
}

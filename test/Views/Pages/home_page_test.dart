import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardy_app/Views/Pages/home.dart';
import 'package:stardy_app/features/dashboard/repository/dashboard_repository.dart';
import 'package:stardy_app/features/dashboard/dto/home_dto.dart';
import 'package:stardy_app/core/network/api_client.dart';

void main() {
  group('HomePage Tests', () {
    testWidgets('renders loading state initially', (WidgetTester tester) async {
      final completer = Completer<HomeData>();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProvider.overrideWith((ref) => completer.future),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('renders error state with Retry', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProvider.overrideWith((ref) => Future<HomeData>.error(const MalformedFailure('error'))),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Failed to load home data'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('renders home with a continue course', (WidgetTester tester) async {
      const mockData = HomeData(
        greetingName: 'Jeevan',
        continueCourse: ContinueCourse(
          courseId: 'c1',
          title: 'Advanced Flutter',
          progressPercent: 50,
        ),
        recommended: [],
        newCourses: [],
        careerPaths: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProvider.overrideWith((ref) => Future.value(mockData)),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Hi Jeevan'), findsOneWidget);
      expect(find.text('Continue course'), findsOneWidget);
      expect(find.text('Advanced Flutter'), findsOneWidget);
      expect(find.text('50% completed'), findsOneWidget);
    });

    testWidgets('renders home with continueCourse null', (WidgetTester tester) async {
      const mockData = HomeData(
        greetingName: 'Jeevan',
        continueCourse: null,
        recommended: [],
        newCourses: [],
        careerPaths: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProvider.overrideWith((ref) => Future.value(mockData)),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Start a new course'), findsOneWidget);
      expect(find.text("You don't have any active courses. Browse the Learn tab to find something new!"), findsOneWidget);
    });

    testWidgets('renders empty recommended and new courses correctly (hidden)', (WidgetTester tester) async {
      const mockData = HomeData(
        greetingName: 'Jeevan',
        continueCourse: null,
        recommended: [],
        newCourses: [],
        careerPaths: [],
      );

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            homeProvider.overrideWith((ref) => Future.value(mockData)),
          ],
          child: const MaterialApp(home: HomePage()),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Recommended for You'), findsNothing);
      expect(find.text('New Courses'), findsNothing);
    });
  });
}

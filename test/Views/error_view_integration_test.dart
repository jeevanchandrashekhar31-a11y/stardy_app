import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/Views/Courses/Course_SUB_Pages/resources_page.dart';
import 'package:stardy_app/Views/Courses/Course_SUB_Pages/grades_page.dart';
import 'package:stardy_app/Views/Courses/course_details_page.dart';
import 'package:stardy_app/Views/CareerPath/project_assignment_brief_page.dart';
import 'package:stardy_app/Views/CareerPath/career_path_detail_page.dart';
import 'package:stardy_app/Views/CareerPath/module_list_page.dart';
import 'package:stardy_app/features/courses/repository/course_repository.dart';
import 'package:stardy_app/features/grades/repository/grades_repository.dart';
import 'package:stardy_app/features/career_paths/repository/career_paths_repository.dart';

import 'package:stardy_app/features/courses/dto/course_dto.dart';
import 'package:stardy_app/features/grades/dto/grades_response.dart';
import 'package:stardy_app/features/career_paths/models/career_path_models.dart';

class FailingCourseRepository extends CourseRepository {
  FailingCourseRepository() : super(ApiClient());
  @override Future<Result<List<ResourceItem>>> getResources(String id) async => Err(const NetworkFailure('secret-detail'));
  @override Future<Result<CourseDetail>> getCourse(String id) async => Err(const NetworkFailure('secret-detail'));
}

class FailingGradesRepository extends GradesRepository {
  FailingGradesRepository() : super(ApiClient());
  @override Future<Result<GradesResponse>> getGrades({String? courseId, String? cursor, int limit = 20}) async => Err(const NetworkFailure('secret-detail'));
}

class FailingCareerPathsRepository extends CareerPathsRepository {
  FailingCareerPathsRepository() : super(ApiClient());
  @override Future<Result<CareerPathDetail>> getCareerPath(String pathId) async => Err(const NetworkFailure('secret-detail'));
  @override Future<Result<CareerPathProjectResponse>> getProject(String pathId) async => Err(const NetworkFailure('secret-detail'));
}

void main() {
  Widget buildApp(Widget child) {
    return ProviderScope(
      overrides: [
        courseRepositoryProvider.overrideWithValue(FailingCourseRepository()),
        gradesRepositoryProvider.overrideWithValue(FailingGradesRepository()),
        careerPathsRepositoryProvider.overrideWithValue(FailingCareerPathsRepository()),
      ],
      child: MaterialApp(home: Scaffold(body: child)),
    );
  }

  testWidgets('ResourcesPage hides secret-detail', (tester) async {
    await tester.pumpWidget(buildApp(const ResourcesPage(courseId: '1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('secret-detail'), findsNothing);
    expect(find.textContaining('Something went wrong'), findsOneWidget);
  });

  testWidgets('GradesPage hides secret-detail', (tester) async {
    await tester.pumpWidget(buildApp(const GradesPage(courseId: '1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('secret-detail'), findsNothing);
    expect(find.textContaining('Something went wrong'), findsOneWidget);
  });

  testWidgets('CourseDetailsPage hides secret-detail', (tester) async {
    await tester.pumpWidget(buildApp(const CourseDetailsPage(courseId: '1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('secret-detail'), findsNothing);
    expect(find.textContaining('Something went wrong'), findsOneWidget);
  });

  testWidgets('ProjectAssignmentBriefPage hides secret-detail', (tester) async {
    await tester.pumpWidget(buildApp(const ProjectAssignmentBriefPage(pathId: '1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('secret-detail'), findsNothing);
    expect(find.textContaining('Something went wrong'), findsOneWidget);
  });

  testWidgets('CareerPathDetailPage hides secret-detail', (tester) async {
    await tester.pumpWidget(buildApp(const CareerPathDetailPage(pathId: '1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('secret-detail'), findsNothing);
    expect(find.textContaining('Something went wrong'), findsOneWidget);
  });

  testWidgets('ModuleListPage hides secret-detail', (tester) async {
    await tester.pumpWidget(buildApp(const ModuleListPage(pathId: '1')));
    await tester.pumpAndSettle();
    expect(find.textContaining('secret-detail'), findsNothing);
    expect(find.textContaining('Something went wrong'), findsOneWidget);
  });
}

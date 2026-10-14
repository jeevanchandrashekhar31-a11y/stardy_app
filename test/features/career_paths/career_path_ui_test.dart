import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardy_app/Views/CareerPath/project_assignment_brief_page.dart';
import 'package:stardy_app/Views/CareerPath/career_path_detail_page.dart';
import 'package:stardy_app/features/career_paths/repository/career_paths_repository.dart';
import 'package:stardy_app/features/career_paths/models/career_path_models.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/courses/repository/course_repository.dart';
import 'package:stardy_app/features/courses/dto/course_dto.dart';

class FakeCareerPathsRepository extends CareerPathsRepository {
  final Future<Result<CareerPathProjectResponse>> Function(String) onGetProject;
  final Future<Result<CareerPathDetail>> Function(String) onGetDetail;
  final Future<Result<CareerPathProjectResponse>> Function(String, String) onGenerateProject;
  final Future<Result<bool>> Function(String, String) onEnroll;

  FakeCareerPathsRepository({
    required this.onGetProject,
    required this.onGetDetail,
    required this.onGenerateProject,
    required this.onEnroll,
  }) : super(ApiClient());

  @override
  Future<Result<CareerPathProjectResponse>> getProject(String pathId) => onGetProject(pathId);

  @override
  Future<Result<CareerPathDetail>> getCareerPath(String pathId) => onGetDetail(pathId);

  @override
  Future<Result<CareerPathProjectResponse>> generateProject(String pathId, String key) => onGenerateProject(pathId, key);

  @override
  Future<Result<bool>> enrollCareerPath(String pathId, String key) => onEnroll(pathId, key);
}

class FakeCourseRepository extends CourseRepository {
  FakeCourseRepository() : super(ApiClient());

  @override
  Future<Result<CourseDetail>> getCourse(String courseId) async {
    return Err<CourseDetail>(const ServerFailure('Not mocked'));
  }
}

void main() {
  Widget buildApp(CareerPathsRepository repo, Widget page) {
    return ProviderScope(
      overrides: [
        careerPathsRepositoryProvider.overrideWithValue(repo),
        courseRepositoryProvider.overrideWithValue(FakeCourseRepository()),
      ],
      child: MaterialApp(home: page),
    );
  }

  group('CareerPathDetailPage Widget Tests', () {
    testWidgets('not enrolled Start Course', (tester) async {
      bool enrolled = false;
      final repo = FakeCareerPathsRepository(
        onGetDetail: (id) async => Ok(CareerPathDetail(
          id: id, title: 'Path', description: 'Desc', skills: [],
          enrolled: false, progress: 0,
          courses: const [CareerPathCourse(courseId: 'c1', title: 'C1', difficulty: 'B', order: 1)],
        )),
        onEnroll: (id, key) async {
          enrolled = true;
          return Ok(true);
        },
        onGetProject: (id) async => Err<CareerPathProjectResponse>(const ServerFailure('')),
        onGenerateProject: (id, k) async => Err<CareerPathProjectResponse>(const ServerFailure('')),
      );

      await tester.pumpWidget(buildApp(repo, const CareerPathDetailPage(pathId: 'p1')));
      await tester.pumpAndSettle();

      expect(find.text('Start Course'), findsOneWidget);
      await tester.tap(find.text('Start Course'));
      await tester.pump(); // wait for setState

      expect(enrolled, true);
    });

    testWidgets('enrolled Continue', (tester) async {
      final repo = FakeCareerPathsRepository(
        onGetDetail: (id) async => Ok(CareerPathDetail(
          id: id, title: 'Path', description: 'Desc', skills: [],
          enrolled: true, progress: 50,
          courses: const [CareerPathCourse(courseId: 'c1', title: 'C1', difficulty: 'B', order: 1)],
        )),
        onEnroll: (id, key) async => Err<bool>(const ServerFailure('')),
        onGetProject: (id) async => Err<CareerPathProjectResponse>(const ServerFailure('')),
        onGenerateProject: (id, k) async => Err<CareerPathProjectResponse>(const ServerFailure('')),
      );

      await tester.pumpWidget(buildApp(repo, const CareerPathDetailPage(pathId: 'p1')));
      await tester.pumpAndSettle();

      expect(find.text('Continue'), findsOneWidget);
    });
  });

  group('ProjectAssignmentBriefPage Widget Tests', () {
    testWidgets('project null + eligible', (tester) async {
      bool generated = false;
      final repo = FakeCareerPathsRepository(
        onGetProject: (id) async => Ok(const CareerPathProjectResponse(eligible: true, progress: 60, project: null)),
        onGenerateProject: (id, key) async {
          generated = true;
          return Ok(const CareerPathProjectResponse(eligible: true, progress: 60, project: null)); // In reality it returns project
        },
        onGetDetail: (id) async => Err<CareerPathDetail>(const ServerFailure('')),
        onEnroll: (id, key) async => Err<bool>(const ServerFailure('')),
      );

      await tester.pumpWidget(buildApp(repo, const ProjectAssignmentBriefPage(pathId: 'p1')));
      await tester.pumpAndSettle();

      expect(find.text('Generate my project'), findsOneWidget);
      
      await tester.tap(find.text('Generate my project'));
      await tester.pump();
      
      expect(generated, true);
    });

    testWidgets('project null + not eligible', (tester) async {
      final repo = FakeCareerPathsRepository(
        onGetProject: (id) async => Ok(const CareerPathProjectResponse(eligible: false, progress: 40, project: null)),
        onGenerateProject: (id, key) async => Err<CareerPathProjectResponse>(const ServerFailure('')),
        onGetDetail: (id) async => Err<CareerPathDetail>(const ServerFailure('')),
        onEnroll: (id, key) async => Err<bool>(const ServerFailure('')),
      );

      await tester.pumpWidget(buildApp(repo, const ProjectAssignmentBriefPage(pathId: 'p1')));
      await tester.pumpAndSettle();

      expect(find.text('Unlocks at 50% (you are at 40%)'), findsOneWidget);
      expect(find.text('Generate my project'), findsNothing);
    });

    testWidgets('existing project', (tester) async {
      final repo = FakeCareerPathsRepository(
        onGetProject: (id) async => Ok(const CareerPathProjectResponse(
          eligible: true, progress: 100,
          project: ProjectDetail(
            id: 'proj1', title: 'Amazing Proj', description: 'Make a good app',
            requirements: ['Req 1'], deliverables: [], stretchGoals: [],
          ),
        )),
        onGenerateProject: (id, key) async => Err<CareerPathProjectResponse>(const ServerFailure('')),
        onGetDetail: (id) async => Err<CareerPathDetail>(const ServerFailure('')),
        onEnroll: (id, key) async => Err<bool>(const ServerFailure('')),
      );

      await tester.pumpWidget(buildApp(repo, const ProjectAssignmentBriefPage(pathId: 'p1')));
      await tester.pumpAndSettle();

      expect(find.text('AMAZING PROJ'), findsOneWidget);
      expect(find.text('Submit project'), findsOneWidget);
    });
  });
}

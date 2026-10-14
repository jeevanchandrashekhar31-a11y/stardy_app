import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/session/session_controller.dart';
import 'package:stardy_app/features/onboarding/onboarding_repository.dart';
import 'package:stardy_app/features/onboarding/onboarding_form.dart';
import 'package:stardy_app/features/dashboard/repository/dashboard_repository.dart';
import 'package:stardy_app/features/courses/repository/course_repository.dart';
import 'package:stardy_app/features/courses/models/course_enums.dart';
import 'package:stardy_app/features/courses/repository/quiz_repository.dart';
import 'package:stardy_app/features/courses/repository/assignment_repository.dart';
import 'package:stardy_app/features/remedial/repository/remedial_repository.dart';
import 'package:stardy_app/features/opportunities/repository/opportunity_repository.dart';
import 'package:stardy_app/features/search/repository/search_repository.dart';

class MockUser extends Mock implements firebase_auth.User {
  final String _uid;
  MockUser(this._uid);
  @override
  String get uid => _uid;
}

String _readFixture(String filename) {
  final file = File('test/fixtures/contract/$filename');
  if (file.existsSync()) {
    return file.readAsStringSync();
  }
  throw StateError('Fixture file test/fixtures/contract/$filename not found');
}

void main() {
  group('FAKE-SERVER Integration Flows (Verified against contract fixtures only)', () {
    late StreamController<firebase_auth.User?> authStreamController;
    bool onboardingDone = false;

    MockClient createMockClient() {
      return MockClient((http.Request request) async {
        final path = request.url.path;

        // 1. Auth session
        if (path.contains('/auth/session') && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'user': {
                  'id': 'usr_101',
                  'name': 'Alex Mercer',
                  'username': 'alexm',
                  'email': 'alex@example.com',
                  'profilePictureUrl': 'https://example.com/avatar.jpg',
                },
                'onboardingCompleted': onboardingDone,
              },
            }),
            200,
          );
        }

        // 2. Onboarding submit
        if (path.contains('/onboarding') && request.method == 'POST') {
          onboardingDone = true;
          return http.Response(
            jsonEncode({'success': true, 'data': {'completed': true}}),
            201,
          );
        }

        // 3. Dashboard home
        if (path.contains('/dashboard/home') && request.method == 'GET') {
          return http.Response(_readFixture('dashboard_home.json'), 200);
        }

        // 4. Courses list & detail & complete
        if (path.contains('/courses/crs_flutter') && request.method == 'GET') {
          return http.Response(_readFixture('course_detail.json'), 200);
        }
        if (path.endsWith('/courses') && request.method == 'GET') {
          return http.Response(_readFixture('courses_list.json'), 200);
        }
        if (path.contains('/modules/mod_01/content') && request.method == 'GET') {
          return http.Response(_readFixture('module_content.json'), 200);
        }
        if (path.contains('/modules/mod_01/complete') && request.method == 'POST') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'isCompleted': true,
                'gamification': {
                  'xpAwarded': 50,
                  'xp': 250,
                  'level': 2,
                  'leveledUp': false,
                  'newLevel': null,
                  'badgesUnlocked': [],
                },
              },
            }),
            200,
          );
        }

        // 5. Quiz attempts & submit
        if (path.contains('/modules/mod_01/quiz/attempts') && request.method == 'POST') {
          return http.Response(_readFixture('quiz_attempt.json'), 200);
        }
        if (path.contains('/quiz/attempts/att_mod_01/submit') && request.method == 'POST') {
          return http.Response(_readFixture('quiz_submit_result.json'), 200);
        }

        // 6. Assignment quiz & submissions
        if (path.contains('/assignments/asg_01/submissions') && request.method == 'POST') {
          final body = jsonDecode(request.body) as Map<String, dynamic>;
          final answers = body['answers'] as List<dynamic>? ?? [];
          final bool willFail = answers.isNotEmpty && answers.first['selectedIndex'] == 99;

          if (willFail) {
            return http.Response(
              jsonEncode({
                'success': true,
                'data': {
                  'submissionId': 'sub_fail_999',
                  'score': 40,
                  'passed': false,
                  'correctCount': 1,
                  'totalCount': 3,
                  'remedialEligible': true,
                  'gamification': null,
                },
              }),
              201,
            );
          }
          return http.Response(_readFixture('quiz_submit_result.json'), 201);
        }
        if (path.contains('/assignments/asg_01/file-submission') && request.method == 'POST') {
          return http.Response(_readFixture('file_submission_result.json'), 201);
        }
        if (path.contains('/assignments/asg_01') && request.method == 'GET') {
          return http.Response(_readFixture('assignment_detail.json'), 200);
        }
        if (path.contains('/uploads/presign') && request.method == 'POST') {
          return http.Response(_readFixture('presign.json'), 200);
        }

        // 7. Remedial generate & submit
        if (path.contains('/remedial/generate') && request.method == 'POST') {
          return http.Response(_readFixture('remedial_quiz.json'), 200);
        }
        if (path.contains('/remedial/rem_quiz_01/submit') && request.method == 'POST') {
          return http.Response(_readFixture('remedial_submit.json'), 200);
        }

        // 8. Opportunities list & apply
        if (path.contains('/opportunities/opp_101/apply') && request.method == 'POST') {
          return http.Response(_readFixture('opportunity_apply.json'), 201);
        }
        if (path.contains('/opportunities/opp_101') && request.method == 'GET') {
          return http.Response(_readFixture('opportunity_detail.json'), 200);
        }
        if (path.contains('/opportunities') && request.method == 'GET') {
          return http.Response(_readFixture('opportunities_list.json'), 200);
        }

        // 9. Search
        if (path.contains('/search') && request.method == 'GET') {
          final type = request.url.queryParameters['type'];
          if (type == 'COURSE') {
            return http.Response(_readFixture('search_courses.json'), 200);
          } else {
            return http.Response(_readFixture('search_opportunities.json'), 200);
          }
        }

        return http.Response(jsonEncode({'success': false, 'error': 'Endpoint not found: $path'}), 404);
      });
    }

    ProviderContainer createContainer(MockClient mockClient) {
      return ProviderContainer(
        overrides: [
          httpClientProvider.overrideWithValue(mockClient),
          tokenProvider.overrideWithValue((force) async => 'fake-test-token'),
          authStateStreamProvider.overrideWithValue(authStreamController.stream),
        ],
      );
    }

    setUp(() {
      authStreamController = StreamController<firebase_auth.User?>();
      onboardingDone = false;
    });

    tearDown(() {
      authStreamController.close();
    });

    test('Flow 1: Sign-in then onboarding then home (FAKE-SERVER)', () async {
      final mockClient = createMockClient();
      final container = createContainer(mockClient);

      // Start session listener
      container.read(sessionControllerProvider);

      // User signs in with Firebase
      authStreamController.add(MockUser('usr_101'));
      await Future.delayed(const Duration(milliseconds: 100));

      // Session controller detects onboarding not completed
      final sessionState = container.read(sessionControllerProvider);
      if (sessionState is SessionFailed) {
        fail('Session failed: ${sessionState.error}');
      }
      expect(sessionState, isA<SessionNeedsOnboarding>());

      // User fills and submits onboarding form
      final onboardingRepo = container.read(onboardingRepositoryProvider);
      final submitResult = await onboardingRepo.submitOnboarding(
        const OnboardingFormState(
          careerGoal: 'Become a Flutter Engineer',
          purpose: OnboardingPurpose.learnSkills,
          howHeard: OnboardingHowHeard.socialMedia,
          expectation: 'I want to master Dart and Flutter to build production apps.',
          hasUsedSimilarApps: false,
        ),
        idempotencyKey: 'idem-onboarding-001',
      );
      expect(submitResult, isA<Ok>());

      // Session controller refreshes session
      await container.read(sessionControllerProvider.notifier).refresh();
      expect(container.read(sessionControllerProvider), isA<SessionReady>());
      final readyState = container.read(sessionControllerProvider) as SessionReady;
      expect(readyState.user.id, 'usr_101');
      expect(readyState.user.name, 'Alex Mercer');

      // Home dashboard loads successfully
      final dashboardRepo = container.read(dashboardRepositoryProvider);
      final homeResult = await dashboardRepo.getHomeData();
      expect(homeResult, isA<Ok>());
      final homeData = (homeResult as Ok).data;
      expect(homeData.greetingName, 'Alex');
      expect(homeData.continueCourse?.title, 'Flutter Fundamentals');

      container.dispose();
    });

    test('Flow 2: Open a course (FAKE-SERVER)', () async {
      final mockClient = createMockClient();
      final container = createContainer(mockClient);

      final courseRepo = container.read(courseRepositoryProvider);
      final result = await courseRepo.getCourse('crs_flutter');

      expect(result, isA<Ok>());
      final course = (result as Ok).data;
      expect(course.id, 'crs_flutter');
      expect(course.title, 'Flutter Fundamentals');
      expect(course.difficulty, Difficulty.beginner);
      expect(course.modules.length, 2);
      expect(course.modules.first.title, 'Introduction to Widgets');
      expect(course.assignments.length, 1);
      expect(course.assignments.first.title, 'Build a Counter App');

      container.dispose();
    });

    test('Flow 3: Play and complete a module (FAKE-SERVER)', () async {
      final mockClient = createMockClient();
      final container = createContainer(mockClient);

      final courseRepo = container.read(courseRepositoryProvider);

      // Fetch module streaming content
      final contentResult = await courseRepo.getModuleContent('mod_01');
      expect(contentResult, isA<Ok>());
      final content = (contentResult as Ok).data;
      expect(content.contentType, ContentType.video);
      expect(content.url, contains('.m3u8'));

      // Mark module complete (IDEM)
      final completeResult = await courseRepo.completeModule('mod_01', 'idem-mod-complete-001');
      expect(completeResult, isA<Ok>());
      final resultData = (completeResult as Ok).data;
      expect(resultData.isCompleted, isTrue);
      expect(resultData.gamification, isNotNull);
      expect(resultData.gamification!.xpAwarded, 50);
      expect(resultData.gamification!.xp, 250);

      container.dispose();
    });

    test('Flow 4: Quiz fail then remedial (FAKE-SERVER)', () async {
      final mockClient = createMockClient();
      final container = createContainer(mockClient);

      final quizRepo = container.read(quizRepositoryProvider);
      final remedialRepo = container.read(remedialRepositoryProvider);

      // Submit assignment quiz with failing answers
      final submitResult = await quizRepo.submitAssignmentQuiz(
        'asg_01',
        'idem-quiz-fail-001',
        [{'questionId': 'q_01', 'selectedIndex': 99}],
        null,
      );
      expect(submitResult, isA<Ok>());
      final quizRes = (submitResult as Ok).data;
      expect(quizRes.passed, isFalse);
      expect(quizRes.score, 40);
      expect(quizRes.remedialEligible, isTrue);

      // Generate remedial quiz
      final remedialGen = await remedialRepo.generate('sub_fail_999');
      expect(remedialGen, isA<Ok>());
      final remedialQuiz = (remedialGen as Ok).data;
      expect(remedialQuiz.remedialQuizId, 'rem_quiz_01');
      expect(remedialQuiz.questions.isNotEmpty, isTrue);
      expect(remedialQuiz.questions.first.explanation, isNotNull);

      // Submit remedial quiz
      final remedialSub = await remedialRepo.submit(
        'rem_quiz_01',
        [{'questionId': 'rq_01', 'selectedIndex': 0}],
      );
      expect(remedialSub, isA<Ok>());
      final submitData = (remedialSub as Ok).data;
      expect(submitData.score, 100);
      expect(submitData.status, 'COMPLETED');

      container.dispose();
    });

    test('Flow 5: Quiz pass with level-up (FAKE-SERVER)', () async {
      final mockClient = createMockClient();
      final container = createContainer(mockClient);

      final quizRepo = container.read(quizRepositoryProvider);

      // Start module quiz attempt
      final attemptResult = await quizRepo.getModuleQuizAttempt('mod_01', 'idem-att-start-001');
      expect(attemptResult, isA<Ok>());
      final attempt = (attemptResult as Ok).data;
      expect(attempt.attemptId, 'att_mod_01');
      expect(attempt.questions.length, 2);

      // Submit attempt with 100% score
      final submitResult = await quizRepo.submitModuleQuizAttempt(
        'att_mod_01',
        'idem-att-sub-001',
        [
          {'questionId': 'q_01', 'selectedIndex': 0},
          {'questionId': 'q_02', 'selectedIndex': 0},
        ],
      );
      expect(submitResult, isA<Ok>());
      final res = (submitResult as Ok).data;
      expect(res.passed, isTrue);
      expect(res.score, 100);
      expect(res.gamification, isNotNull);
      expect(res.gamification!.leveledUp, isTrue);
      expect(res.gamification!.newLevel, 2);
      expect(res.gamification!.badgesUnlocked.first.code, 'FIRST_LAUNCH');

      container.dispose();
    });

    test('Flow 6: Assignment file submission (FAKE-SERVER)', () async {
      final mockClient = createMockClient();
      final container = createContainer(mockClient);

      final assignmentRepo = container.read(assignmentRepositoryProvider);

      // Confirm assignment file submission after presigned upload
      final submitResult = await assignmentRepo.submitFile(
        'asg_01',
        'idem-file-sub-001',
        'assignments/usr_101/asg_01/sub_101.zip',
        'counter_app.zip',
        1048576,
      );

      expect(submitResult, isA<Ok>());
      final sub = (submitResult as Ok).data;
      expect(sub.status, 'PENDING_REVIEW');
      expect(sub.submittedAt, isNotNull);

      container.dispose();
    });

    test('Flow 7: Opportunity apply (FAKE-SERVER)', () async {
      final mockClient = createMockClient();
      final container = createContainer(mockClient);

      final oppRepo = container.read(opportunityRepositoryProvider);

      // List opportunities
      final listResult = await oppRepo.getOpportunities();
      expect(listResult, isA<Ok>());
      final paged = (listResult as Ok).data;
      expect(paged.items.isNotEmpty, isTrue);
      expect(paged.items.first.id, 'opp_101');

      // Apply with cover note
      final applyResult = await oppRepo.apply(
        'opp_101',
        'idem-opp-apply-001',
        coverNote: 'Excited to contribute to your mobile team.',
      );
      expect(applyResult, isA<Ok>());
      final applyData = (applyResult as Ok).data;
      expect(applyData.status, 'SUBMITTED');

      container.dispose();
    });

    test('Flow 8: Search for courses and opportunities (FAKE-SERVER)', () async {
      final mockClient = createMockClient();
      final container = createContainer(mockClient);

      final searchRepo = container.read(searchRepositoryProvider);

      // Course search
      final courseSearch = await searchRepo.searchCourses('Flutter');
      expect(courseSearch, isA<Ok>());
      final courses = (courseSearch as Ok).data.items;
      expect(courses.isNotEmpty, isTrue);
      expect(courses.first.title, contains('Flutter'));

      // Opportunity search
      final oppSearch = await searchRepo.searchOpportunities('Flutter');
      expect(oppSearch, isA<Ok>());
      final opps = (oppSearch as Ok).data.items;
      expect(opps.isNotEmpty, isTrue);
      expect(opps.first.title, contains('Flutter'));

      container.dispose();
    });
  });
}

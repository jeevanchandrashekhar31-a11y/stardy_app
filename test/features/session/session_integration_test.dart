import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:mocktail/mocktail.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/session/session_controller.dart';
import 'package:stardy_app/features/gamification/repository/gamification_repository.dart';
import 'package:stardy_app/features/profile/repository/profile_repository.dart';
import 'package:stardy_app/features/dashboard/repository/dashboard_repository.dart';
import 'package:stardy_app/features/grades/providers/grades_provider.dart';
import 'package:stardy_app/features/courses/repository/course_repository.dart';
import 'package:stardy_app/features/opportunities/providers/opportunity_provider.dart';
import 'package:stardy_app/features/career_paths/providers/career_paths_provider.dart';

class MockUser extends Mock implements firebase_auth.User {
  final String _uid;
  MockUser(this._uid);
  @override
  String get uid => _uid;
}

String currentTestUser = 'A';

void main() {
  test('Session data leak test using real apiClientProvider and real SessionController', () async {
    final mockClient = MockClient((req) async {
      final path = req.url.path;
      final u = currentTestUser;

      if (path.contains('/auth/session')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'user': {
                'id': u,
                'name': 'User $u',
                'email': '$u@test.com',
                'profilePictureUrl': null,
                'username': 'user_$u',
              },
              'onboardingCompleted': true,
            },
          }),
          200,
        );
      }
      if (path.contains('/gamification/me')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'xp': u == 'A' ? 100 : 200,
              'level': 1,
              'xpIntoLevel': 0,
              'xpForNextLevel': 1000,
              'currentStreak': 1,
              'longestStreak': 1,
              'activeToday': true,
            },
          }),
          200,
        );
      }
      if (path.contains('/users/me')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': u,
              'name': 'User $u',
              'email': '$u@test.com',
              'roles': [],
              'createdAt': '2023-01-01T00:00:00Z',
              'careerPaths': [],
            },
          }),
          200,
        );
      }
      if (path.contains('/dashboard/home')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'greetingName': 'Hello $u',
              'recommended': [],
              'newCourses': [],
              'careerPaths': [],
            },
          }),
          200,
        );
      }
      if (path.contains('/dashboard/grades')) {
        if (req.url.queryParameters['courseId'] == 'c1') {
          return http.Response(
            jsonEncode({
              'success': true,
              'data': {
                'items': [
                  {
                    'kind': 'ASSIGNMENT',
                    'refId': '$u-grade',
                    'title': 't',
                    'courseTitle': 'ct',
                    'percentage': 90,
                  },
                ],
                'hasMore': false,
              },
            }),
            200,
          );
        }
        return http.Response(
          jsonEncode({'success': true, 'data': {'items': [], 'hasMore': false}}),
          200,
        );
      }
      if (path.contains('/courses/c1')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'c1',
              'title': 'Course for $u',
              'description': 'desc',
              'category': 'TECH',
              'difficulty': 'BEGINNER',
              'durationSeconds': 3600,
              'thumbnailUrl': 'https://example.com/thumb.jpg',
              'modules': [],
              'assignments': [],
              'createdAt': '2023-01-01T00:00:00Z',
              'ratingAvg': 4.5,
              'ratingCount': 10,
              'moduleCount': 0,
            },
          }),
          200,
        );
      }
      if (path.startsWith('/opportunities')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'items': [
                {
                  'id': 'opp-$u',
                  'title': 'Opp $u',
                  'company': 'Co',
                  'type': 'INTERNSHIP',
                  'category': 'TECH',
                  'location': 'Remote',
                  'postedAt': '2023-01-01T00:00:00Z',
                  'isApplied': false,
                },
              ],
              'hasMore': false,
            },
          }),
          200,
        );
      }
      if (path.contains('/career-paths/p1')) {
        return http.Response(
          jsonEncode({
            'success': true,
            'data': {
              'id': 'p1',
              'title': 'Path $u',
              'description': 'desc',
              'milestones': [],
              'enrolled': true,
              'skills': [],
              'progress': 0,
              'courses': [],
            },
          }),
          200,
        );
      }
      return http.Response(jsonEncode({'success': false, 'error': 'Not found'}), 404);
    });

    final authStreamController = StreamController<firebase_auth.User?>();
    final container = ProviderContainer(
      overrides: [
        // Production seams: fake HTTP client, fake token, fake auth stream.
        // apiClientProvider and sessionControllerProvider are REAL.
        httpClientProvider.overrideWithValue(mockClient),
        tokenProvider.overrideWithValue((force) async => 'fake-token'),
        authStateStreamProvider.overrideWithValue(authStreamController.stream),
      ],
    );

    // Initialize session controller so it listens to auth stream
    container.read(sessionControllerProvider);

    // Initial sign in as A
    currentTestUser = 'A';
    authStreamController.add(MockUser('A'));
    await Future.delayed(const Duration(milliseconds: 50));

    // Keep providers alive with active subscriptions
    final subGamification = container.listen(gamificationProvider, (prev, next) {});
    final subMe = container.listen(meProvider, (prev, next) {});
    final subHome = container.listen(homeProvider, (prev, next) {});
    final subGrades = container.listen(gradesProvider('c1'), (prev, next) {});
    final subCourse = container.listen(courseDetailProvider('c1'), (prev, next) {});
    final subCareer = container.listen(careerPathDetailProvider('p1'), (prev, next) {});

    final gamificationA = await container.read(gamificationProvider.future);
    expect(gamificationA.xp, 100);

    final meA = await container.read(meProvider.future);
    expect(meA.name, 'User A');

    final homeA = await container.read(homeProvider.future);
    expect(homeA.greetingName, 'Hello A');

    final gradesA = await container.read(gradesProvider('c1').future);
    expect(gradesA.items.first.refId, 'A-grade');

    final courseA = await container.read(courseDetailProvider('c1').future);
    expect(courseA.title, 'Course for A');

    final filter = const OpportunityFilter(type: 'INTERNSHIP', category: 'TECH');
    final sub = container.listen(opportunityListProvider(filter), (prev, next) {});

    for (var i = 0; i < 20; i++) {
      if (!container.read(opportunityListProvider(filter)).isLoading) break;
      await Future.delayed(const Duration(milliseconds: 50));
    }
    final oppAData = container.read(opportunityListProvider(filter));
    expect(oppAData.items.first.title, 'Opp A');

    final careerA = await container.read(careerPathDetailProvider('p1').future);
    expect(careerA.title, 'Path A');

    sub.close();

    // Sign out A
    authStreamController.add(null);
    await Future.delayed(const Duration(milliseconds: 50));

    // Sign in B
    currentTestUser = 'B';
    authStreamController.add(MockUser('B'));
    await Future.delayed(const Duration(milliseconds: 50));

    // Assert B's data
    final gamificationB = await container.read(gamificationProvider.future);
    expect(gamificationB.xp, 200, reason: 'gamificationProvider leaked user A data');

    final meB = await container.read(meProvider.future);
    expect(meB.name, 'User B', reason: 'meProvider leaked user A data');

    final homeB = await container.read(homeProvider.future);
    expect(homeB.greetingName, 'Hello B', reason: 'homeProvider leaked user A data');

    final gradesB = await container.read(gradesProvider('c1').future);
    expect(gradesB.items.first.refId, 'B-grade', reason: 'gradesProvider leaked user A data');

    final courseB = await container.read(courseDetailProvider('c1').future);
    expect(courseB.title, 'Course for B', reason: 'courseDetailProvider leaked user A data');

    final subB = container.listen(opportunityListProvider(filter), (prev, next) {});
    for (var i = 0; i < 20; i++) {
      if (!container.read(opportunityListProvider(filter)).isLoading) break;
      await Future.delayed(const Duration(milliseconds: 50));
    }
    final oppBData = container.read(opportunityListProvider(filter));
    expect(oppBData.items.first.title, 'Opp B', reason: 'opportunityListProvider leaked user A data');
    subB.close();

    final careerB = await container.read(careerPathDetailProvider('p1').future);
    expect(careerB.title, 'Path B', reason: 'careerPathDetailProvider leaked user A data');

    subGamification.close();
    subMe.close();
    subHome.close();
    subGrades.close();
    subCourse.close();
    subCareer.close();
    container.dispose();
  });
}

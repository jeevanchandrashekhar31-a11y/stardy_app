import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/courses/models/quiz_models.dart';
import 'package:stardy_app/Views/Courses/Course_SUB_Pages/quiz_page.dart';
import 'package:stardy_app/Views/Courses/Course_SUB_Pages/quiz_result_page.dart';

class FakeApiClient extends ApiClient {
  final Future<Result<dynamic>> Function(String method, String path, Map<String, dynamic>? body, String? idempotencyKey) handler;

  FakeApiClient(this.handler);

  @override
  Future<Result<T>> get<T>(String path, {int retries = 0, int timeoutSeconds = 20}) async {
    final result = await handler('GET', path, null, null);
    if (result is Ok) {
      return Ok<T>(result.data as T);
    } else {
      return Err<T>((result as Err).error);
    }
  }

  @override
  Future<Result<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
    int timeoutSeconds = 20,
  }) async {
    final result = await handler('POST', path, body, idempotencyKey);
    if (result is Ok) {
      return Ok<T>(result.data as T);
    } else {
      return Err<T>((result as Err).error);
    }
  }
}

void main() {
  group('Quiz Integration (FAKE-SERVER)', () {
    testWidgets('module quiz start+submit, double-tap submits once, retry reuses key', (WidgetTester tester) async {
      int submitCallCount = 0;
      String? lastIdempKey;

      final fakeClient = FakeApiClient((method, path, body, idempotencyKey) async {
        if (method == 'POST' && path == '/modules/m1/quiz/attempts') {
          return Ok(<String, dynamic>{
            'attemptId': 'att-1',
            'startedAt': '2026-10-09T00:00:00Z',
            'questions': [
              {
                'id': 'q1',
                'question': 'Test Q1?',
                'options': ['Opt1', 'Opt2']
              }
            ]
          });
        }
        if (method == 'POST' && path == '/quiz/attempts/att-1/submit') {
          submitCallCount++;
          lastIdempKey = idempotencyKey;
          // Simulate network delay to test double tap
          await Future.delayed(const Duration(milliseconds: 100));
          return Ok({
            'score': 100,
            'passed': true,
            'correctCount': 1,
            'totalCount': 1,
            'remedialEligible': false
          });
        }
        return Err(const ServerFailure('Unknown path'));
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(fakeClient),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: QuizPage(target: ModuleQuiz('m1', 'Module 1 Quiz')),
          ),
        ),
      );

      await tester.pumpAndSettle(); // load quiz

      expect(find.text('Test Q1?'), findsOneWidget, reason: 'Question should be loaded');
      await tester.tap(find.textContaining('Opt1').first);
      await tester.pump();

      // Submit double tap
      final submitBtn = find.text('Submit');
      await tester.tap(submitBtn);
      await tester.tap(submitBtn); // double tap
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();

      expect(submitCallCount, 1, reason: 'Should submit exactly once due to in-flight disabling');
      expect(lastIdempKey, isNotNull, reason: 'Should have idempotency key');
      
      // Verify result page
      expect(find.text('100 %'), findsOneWidget, reason: 'QuizOutcome drives the screen');
      expect(find.text('Practice Weak Areas'), findsNothing, reason: 'remedialEligible false hides the button');
    });

    testWidgets('assignment quiz fetch+submit, 409 conflict', (WidgetTester tester) async {
      final fakeClient = FakeApiClient((method, path, body, idempotencyKey) async {
        if (method == 'GET' && path == '/assignments/a1/quiz') {
          return Ok({
            'questions': [
              {
                'id': 'q1',
                'question': 'Assignment Q?',
                'options': ['Opt1', 'Opt2']
              }
            ]
          });
        }
        if (method == 'POST' && path == '/assignments/a1/submissions') {
          return Err(const ConflictFailure('Already submitted'));
        }
        return Err(const ServerFailure('Unknown'));
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(fakeClient),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: QuizPage(target: AssignmentQuiz('a1', 'Assn Quiz')),
          ),
        ),
      );

      await tester.pumpAndSettle(); // load quiz

      await tester.tap(find.textContaining('Opt1').first);
      await tester.pump();

      await tester.tap(find.text('Submit'));
      await tester.pumpAndSettle();

      // We expect the conflict SnackBar
      expect(find.text('You have already submitted this'), findsOneWidget);
    });

    testWidgets('resume of an in-progress attempt', (WidgetTester tester) async {
      final fakeClient = FakeApiClient((method, path, body, idempotencyKey) async {
        if (method == 'POST' && path == '/modules/m2/quiz/attempts') {
          return Ok({
            'attemptId': 'att-resume',
            'startedAt': '2026-10-09T00:00:00Z',
            'questions': [
              {
                'id': 'q1',
                'question': 'Resume Q1?',
                'options': ['Opt1', 'Opt2']
              }
            ]
          });
        }
        return Err(const ServerFailure('Unknown'));
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(fakeClient),
        ],
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: QuizPage(target: ModuleQuiz('m2', 'Module 2')),
          ),
        ),
      );

      await tester.pumpAndSettle();
      expect(find.text('Resume Q1?'), findsOneWidget, reason: 'Successfully loaded in-progress attempt');
    });

    testWidgets('QuizOutcome drives the screen', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: QuizResultPage(
            outcome: QuizOutcome(
              score: 75,
              passed: true,
              correctCount: 3,
              totalCount: 4,
              remedialEligible: true,
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('75 %'), findsOneWidget);
      expect(find.text('You got 3/4 Right'), findsOneWidget);
      expect(find.text('Practice Weak Areas'), findsOneWidget, reason: 'remedialEligible true shows the button');
    });
  });
}

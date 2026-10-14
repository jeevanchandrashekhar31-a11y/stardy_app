import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/courses/models/quiz_models.dart';
import 'package:stardy_app/features/courses/repository/quiz_repository.dart';

void main() {
  group('QuizRepository tests (FAKE-SERVER)', () {
    test('getModuleQuizAttempt loads and parses quiz_attempt.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/quiz_attempt.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      String? capturedPath;
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        capturedPath = request.url.path;
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = QuizRepository(apiClient);

      final result = await repo.getModuleQuizAttempt('mod_01', 'idemp_key_1');
      expect(result is Ok<QuizAttemptStartResponse>, isTrue);

      final attempt = (result as Ok<QuizAttemptStartResponse>).data;
      expect(attempt.attemptId, 'att_mod_01');
      expect(attempt.questions.length, 2);
      expect(attempt.questions.first.question, 'What is Flutter?');
      expect(capturedPath, '/modules/mod_01/quiz/attempts');
    });

    test('submitModuleQuizAttempt loads and parses quiz_submit_result.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/quiz_submit_result.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      String? capturedPath;
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        capturedPath = request.url.path;
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = QuizRepository(apiClient);

      final result = await repo.submitModuleQuizAttempt('att_mod_01', 'idemp_key_2', [
        {'questionId': 'q_01', 'selectedIndex': 0}
      ]);
      expect(result is Ok<QuizOutcome>, isTrue);

      final outcome = (result as Ok<QuizOutcome>).data;
      expect(outcome.score, 100);
      expect(outcome.passed, isTrue);
      expect(outcome.gamification?.xpAwarded, 50);
      expect(capturedPath, '/quiz/attempts/att_mod_01/submit');
    });

    test('getAssignmentQuiz loads and parses assignment_quiz.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/assignment_quiz.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      String? capturedPath;
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        capturedPath = request.url.path;
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = QuizRepository(apiClient);

      final result = await repo.getAssignmentQuiz('asg_01');
      expect(result is Ok<List<QuizQuestion>>, isTrue);

      final questions = (result as Ok<List<QuizQuestion>>).data;
      expect(questions.length, 2);
      expect(questions.first.question, contains('Product Requirements Document'));
      expect(capturedPath, '/assignments/asg_01/quiz');
    });

    test('submitAssignmentQuiz loads and parses assignment_submission_result.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/assignment_submission_result.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      String? capturedPath;
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        capturedPath = request.url.path;
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = QuizRepository(apiClient);

      final result = await repo.submitAssignmentQuiz('asg_01', 'idemp_key_3', [
        {'questionId': 'q1', 'selectedIndex': 1}
      ], '2026-10-13T09:00:00Z');
      expect(result is Ok<QuizOutcome>, isTrue);

      final outcome = (result as Ok<QuizOutcome>).data;
      expect(outcome.score, 85);
      expect(outcome.passed, isTrue);
      expect(capturedPath, '/assignments/asg_01/submissions');
    });
  });
}

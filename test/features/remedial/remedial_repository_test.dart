import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/remedial/models/remedial_models.dart';
import 'package:stardy_app/features/remedial/repository/remedial_repository.dart';

class FakeApiClient extends ApiClient {
  final Future<Result<dynamic>> Function(String method, String path, Map<String, dynamic>? body, String? idempotencyKey) handler;
  FakeApiClient(this.handler);

  @override
  Future<Result<T>> get<T>(String path, {int retries = 0, int timeoutSeconds = 20}) async {
    final result = await handler('GET', path, null, null);
    if (result is Ok) return Ok<T>(result.data as T);
    return Err<T>((result as Err).error);
  }

  @override
  Future<Result<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
    int timeoutSeconds = 20,
  }) async {
    final result = await handler('POST', path, body, idempotencyKey);
    if (result is Ok) return Ok<T>(result.data as T);
    return Err<T>((result as Err).error);
  }
}

void main() {
  group('RemedialRepository FAKE-SERVER Integration', () {
    test('generate happy path loading remedial_quiz.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/remedial_quiz.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      int calls = 0;
      final fakeApi = FakeApiClient((method, path, body, idemp) async {
        if (path == '/remedial/generate') {
          calls++;
          return Ok(fixtureJson['data']);
        }
        return Err(const ServerFailure('Unknown'));
      });

      final repo = RemedialRepository(fakeApi);
      final res = await repo.generate('sub_1');
      expect(res is Ok, isTrue);
      expect((res as Ok).data.remedialQuizId, 'rem_quiz_01');
      expect(calls, 1);
    });

    test('getQuiz loads and parses remedial_quiz.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/remedial_quiz.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      String? capturedPath;
      final fakeApi = FakeApiClient((method, path, body, idemp) async {
        if (method == 'GET' && path == '/remedial/rem_quiz_01') {
          capturedPath = path;
          return Ok(fixtureJson['data']);
        }
        return Err(const ServerFailure('Unknown'));
      });

      final repo = RemedialRepository(fakeApi);
      final res = await repo.getQuiz('rem_quiz_01');
      expect(res is Ok<RemedialQuiz>, isTrue);
      final quiz = (res as Ok<RemedialQuiz>).data;
      expect(quiz.remedialQuizId, 'rem_quiz_01');
      expect(quiz.questions.length, 1);
      expect(quiz.questions.first.question, contains('What happens when setState'));
      expect(capturedPath, '/remedial/rem_quiz_01');
    });

    test('generate retries on 5xx', () async {
      int calls = 0;
      final fakeApi = FakeApiClient((method, path, body, idemp) async {
        if (path == '/remedial/generate') {
          calls++;
          if (calls < 3) {
            return Err(const ServerFailure('Internal Error'));
          }
          return Ok({
            'remedialQuizId': 'rq_123',
            'status': 'READY',
            'weakConcepts': [],
            'questions': [],
          });
        }
        return Err(const ServerFailure('Unknown'));
      });

      final repo = RemedialRepository(fakeApi);
      final res = await repo.generate('sub_1');
      
      expect(res is Ok, isTrue);
      expect(calls, 3);
    });
    
    test('generate fails after max retries', () async {
      int calls = 0;
      final fakeApi = FakeApiClient((method, path, body, idemp) async {
        if (path == '/remedial/generate') {
          calls++;
          return Err(const ServerFailure('Internal Error'));
        }
        return Err(const ServerFailure('Unknown'));
      });

      final repo = RemedialRepository(fakeApi);
      final res = await repo.generate('sub_1');
      
      expect(res is Err, isTrue);
      expect(calls, 3);
    });

    test('submit happy path loading remedial_submit.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/remedial_submit.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      int calls = 0;
      final fakeApi = FakeApiClient((method, path, body, idemp) async {
        if (path == '/remedial/rq_123/submit') {
          calls++;
          return Ok(fixtureJson['data']);
        }
        return Err(const ServerFailure('Unknown'));
      });

      final repo = RemedialRepository(fakeApi);
      final res = await repo.submit('rq_123', [
        {'questionId': 'q1', 'selectedIndex': 0}
      ]);
      expect(res is Ok, isTrue);
      expect((res as Ok).data.score, 100);
      expect(calls, 1);
    });

    test('two submit calls for the same quiz send the identical key', () async {
      final keys = <String?>[];
      final fakeApi = FakeApiClient((method, path, body, idemp) async {
        keys.add(idemp);
        return Err(const ServerFailure('Network error'));
      });

      final repo = RemedialRepository(fakeApi);
      await repo.submit('rq_123', []);
      await repo.submit('rq_123', []);

      expect(keys.length, 2);
      expect(keys[0], isNotNull);
      expect(keys[0], keys[1]);
    });
  });
}

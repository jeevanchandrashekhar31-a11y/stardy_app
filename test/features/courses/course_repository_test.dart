import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/courses/repository/course_repository.dart';

class FakeApiClient extends ApiClient {
  final Result<Map<String, dynamic>> responseToReturn;

  FakeApiClient(this.responseToReturn);

  @override
  Future<Result<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
    int timeoutSeconds = 20,
  }) async {
    return responseToReturn as Result<T>;
  }
}

void main() {
  group('CourseRepository Tests', () {
    test('completeModule parses contract JSON with gamification populated', () async {
      final fakeApi = FakeApiClient(Ok({
        'isCompleted': true,
        'gamification': {
          'xpAwarded': 100,
          'xp': 1500,
          'level': 5,
          'leveledUp': true,
          'newLevel': 5,
          'badgesUnlocked': [],
        }
      }));
      final repo = CourseRepository(fakeApi);

      final result = await repo.completeModule('m1', 'idem1');
      expect(result, isA<Ok<CompleteModuleResult>>());
      final data = (result as Ok<CompleteModuleResult>).data;
      expect(data.isCompleted, isTrue);
      expect(data.gamification, isNotNull);
      expect(data.gamification!.xpAwarded, 100);
      expect(data.gamification!.leveledUp, isTrue);
    });

    test('completeModule parses contract JSON with gamification null', () async {
      final fakeApi = FakeApiClient(Ok({
        'isCompleted': true,
        'gamification': null,
      }));
      final repo = CourseRepository(fakeApi);

      final result = await repo.completeModule('m1', 'idem1');
      expect(result, isA<Ok<CompleteModuleResult>>());
      final data = (result as Ok<CompleteModuleResult>).data;
      expect(data.isCompleted, isTrue);
      expect(data.gamification, isNull);
    });
  });
}

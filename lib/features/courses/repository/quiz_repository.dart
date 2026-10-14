import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/quiz_models.dart';

final quizRepositoryProvider = Provider<QuizRepository>((ref) {
  final apiClient = ref.watch(apiClientProvider);
  return QuizRepository(apiClient);
});

class QuizRepository {
  final ApiClient _apiClient;

  QuizRepository(this._apiClient);

  Future<Result<QuizAttemptStartResponse>> getModuleQuizAttempt(
      String moduleId, String idempotencyKey) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/modules/$moduleId/quiz/attempts',
      body: {},
      idempotencyKey: idempotencyKey,
    );
    if (res is Ok<Map<String, dynamic>>) {
      try {
        return Ok(QuizAttemptStartResponse.fromJson(res.data));
      } catch (e) {
        return Err(const MalformedFailure('Failed to parse quiz attempt'));
      }
    } else {
      return Err((res as Err).error);
    }
  }

  Future<Result<QuizOutcome>> submitModuleQuizAttempt(
      String attemptId, String idempotencyKey, List<Map<String, dynamic>> answers) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/quiz/attempts/$attemptId/submit',
      body: {'answers': answers},
      idempotencyKey: idempotencyKey,
    );
    if (res is Ok<Map<String, dynamic>>) {
      try {
        return Ok(QuizOutcome.fromJson(res.data));
      } catch (e) {
        return Err(const MalformedFailure('Failed to parse quiz outcome'));
      }
    } else {
      return Err((res as Err).error);
    }
  }

  Future<Result<List<QuizQuestion>>> getAssignmentQuiz(String assignmentId) async {
    final res = await _apiClient.get<Map<String, dynamic>>('/assignments/$assignmentId/quiz');
    if (res is Ok<Map<String, dynamic>>) {
      try {
        final qs = res.data['questions'] as List<dynamic>? ?? [];
        final questions = qs.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>)).toList();
        return Ok(questions);
      } catch (e) {
        return Err(const MalformedFailure('Failed to parse assignment quiz'));
      }
    } else {
      return Err((res as Err).error);
    }
  }

  Future<Result<QuizOutcome>> submitAssignmentQuiz(
      String assignmentId, String idempotencyKey, List<Map<String, dynamic>> answers, String? startedAt) async {
    final body = <String, dynamic>{'answers': answers};
    if (startedAt != null) {
      body['startedAt'] = startedAt;
    }
    
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/assignments/$assignmentId/submissions',
      body: body,
      idempotencyKey: idempotencyKey,
    );
    if (res is Ok<Map<String, dynamic>>) {
      try {
        return Ok(QuizOutcome.fromJson(res.data));
      } catch (e) {
        return Err(const MalformedFailure('Failed to parse quiz outcome'));
      }
    } else {
      return Err((res as Err).error);
    }
  }
}

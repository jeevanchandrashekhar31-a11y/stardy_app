import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/network/api_client.dart';
import '../models/remedial_models.dart';

final remedialRepositoryProvider = Provider((ref) {
  return RemedialRepository(ref.watch(apiClientProvider));
});

class RemedialRepository {
  final ApiClient _api;
  final Map<String, String> _submitKeys = {};

  RemedialRepository(this._api);

  Future<Result<RemedialQuiz>> generate(String assignmentSubmissionId) async {
    final idempotencyKey = const Uuid().v4();

    Result<Map<String, dynamic>> res = await _tryGenerate(assignmentSubmissionId, idempotencyKey);

    int retries = 0;
    while (retries < 2 && _shouldRetry(res)) {
      final backoff = pow(2, retries).toInt() * 1000;
      final jitter = Random().nextInt(500);
      await Future.delayed(Duration(milliseconds: backoff + jitter));
      retries++;
      res = await _tryGenerate(assignmentSubmissionId, idempotencyKey);
    }

    if (res is Ok<Map<String, dynamic>>) {
      return Ok(RemedialQuiz.fromJson(res.data));
    }
    return Err((res as Err).error);
  }

  Future<Result<Map<String, dynamic>>> _tryGenerate(String id, String idempKey) {
    return _api.post<Map<String, dynamic>>(
      '/remedial/generate',
      body: {'assignmentSubmissionId': id},
      idempotencyKey: idempKey,
      timeoutSeconds: 30,
    );
  }

  bool _shouldRetry(Result res) {
    if (res is Err) {
      if (res.error is TimeoutFailure || res.error is ServerFailure) {
        return true;
      }
    }
    return false;
  }

  Future<Result<RemedialQuiz>> getQuiz(String remedialQuizId) async {
    final res = await _api.get<Map<String, dynamic>>('/remedial/$remedialQuizId');
    if (res is Ok<Map<String, dynamic>>) {
      return Ok(RemedialQuiz.fromJson(res.data));
    }
    return Err((res as Err).error);
  }

  Future<Result<RemedialResult>> submit(String remedialQuizId, List<Map<String, dynamic>> answers) async {
    final idempotencyKey = _submitKeys.putIfAbsent(remedialQuizId, () => const Uuid().v4());
    final res = await _api.post<Map<String, dynamic>>(
      '/remedial/$remedialQuizId/submit',
      body: {'answers': answers},
      idempotencyKey: idempotencyKey,
    );
    if (res is Ok<Map<String, dynamic>>) {
      return Ok(RemedialResult.fromJson(res.data));
    }
    return Err<RemedialResult>((res as Err).error);
  }
}

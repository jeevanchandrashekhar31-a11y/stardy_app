import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_client.dart';
import '../models/assignment_models.dart';

final assignmentRepositoryProvider = Provider<AssignmentRepository>((ref) {
  return AssignmentRepository(ref.watch(apiClientProvider));
});

class AssignmentRepository {
  final ApiClient _apiClient;

  AssignmentRepository(this._apiClient);

  Future<Result<AssignmentDetails>> getAssignment(String assignmentId) async {
    final res = await _apiClient.get<Map<String, dynamic>>('/assignments/$assignmentId');
    if (res is Ok<Map<String, dynamic>>) {
      try {
        return Ok(AssignmentDetails.fromJson(res.data));
      } catch (e) {
        return Err(const MalformedFailure('Failed to parse assignment details'));
      }
    }
    return Err((res as Err).error);
  }

  Future<Result<AssignmentFileSubmissionResponse>> submitFile(
    String assignmentId,
    String idempotencyKey,
    String objectKey,
    String fileName,
    int sizeBytes,
  ) async {
    final res = await _apiClient.post<Map<String, dynamic>>(
      '/assignments/$assignmentId/file-submission',
      body: {
        'objectKey': objectKey,
        'fileName': fileName,
        'sizeBytes': sizeBytes,
      },
      idempotencyKey: idempotencyKey,
    );
    
    if (res is Ok<Map<String, dynamic>>) {
      try {
        return Ok(AssignmentFileSubmissionResponse.fromJson(res.data));
      } catch (e) {
        return Err(const MalformedFailure('Failed to parse file submission response'));
      }
    }
    return Err((res as Err).error);
  }
}

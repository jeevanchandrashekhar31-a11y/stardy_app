import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/courses/repository/assignment_repository.dart';

void main() {
  group('AssignmentRepository tests (FAKE-SERVER)', () {
    test('getAssignment loads and parses assignment_detail.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/assignment_detail.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/assignments/asg_01');
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = AssignmentRepository(apiClient);

      final result = await repo.getAssignment('asg_01');
      expect(result is Ok, isTrue);
      final assignment = (result as Ok).data;
      expect(assignment.id, 'asg_01');
      expect(assignment.title, 'Build a Counter App');
      expect(assignment.topics, contains('StatefulWidget'));
    });

    test('submitFile loads and parses file_submission_result.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/file_submission_result.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      String? capturedIdempKey;
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/assignments/asg_01/file-submission');
        capturedIdempKey = request.headers['Idempotency-Key'];
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = AssignmentRepository(apiClient);

      final result = await repo.submitFile(
        'asg_01',
        'key-submission-123',
        'uploads/user1/file.zip',
        'file.zip',
        1024,
      );

      expect(result is Ok, isTrue);
      final submission = (result as Ok).data;
      expect(submission.status, 'PENDING_REVIEW');
      expect(capturedIdempKey, 'key-submission-123');
      expect(capturedBody?['objectKey'], 'uploads/user1/file.zip');
    });
  });
}

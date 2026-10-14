import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/grades/repository/grades_repository.dart';

void main() {
  group('GradesRepository & Provider tests (FAKE-SERVER)', () {
    test('getGrades loads and parses grades.json fixture with cursor pagination', () async {
      final fixtureFile = File('test/fixtures/contract/grades.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      String? capturedPath;
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        capturedPath = request.url.toString();
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = GradesRepository(apiClient);

      final result = await repo.getGrades(courseId: 'crs_101', cursor: 'cur_abc', limit: 20);
      expect(result is Ok, isTrue);

      final gradesResponse = (result as Ok).data;
      expect(gradesResponse.items.length, 2);
      expect(gradesResponse.items.first.title, 'Dart Syntax Quiz');
      expect(gradesResponse.items.first.letter, 'A+');
      expect(gradesResponse.items.first.percentage, 95);
      expect(capturedPath, contains('courseId=crs_101'));
      expect(capturedPath, contains('cursor=cur_abc'));
    });

    test('getGrades TTL cache avoids immediate duplicate fetch', () async {
      int callCount = 0;
      final fixtureFile = File('test/fixtures/contract/grades.json');
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      final client = MockClient((request) async {
        callCount++;
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = GradesRepository(apiClient);

      await repo.getGrades(courseId: 'crs_101');
      expect(callCount, 1);

      // Immediate second call should use cache
      await repo.getGrades(courseId: 'crs_101');
      expect(callCount, 1);

      // Invalidation clears cache
      repo.invalidateAfterProgress();
      await repo.getGrades(courseId: 'crs_101');
      expect(callCount, 2);
    });
  });
}

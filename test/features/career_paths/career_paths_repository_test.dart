import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/career_paths/models/career_path_models.dart';
import 'package:stardy_app/features/career_paths/repository/career_paths_repository.dart';

class FakeApiClient extends ApiClient {
  final Map<String, dynamic> responses = {};
  final List<String> idempotencyKeys = [];
  bool shouldTimeout = false;
  int generateCalls = 0;

  @override
  Future<Result<T>> post<T>(String path, {Map<String, dynamic>? body, String? idempotencyKey, int timeoutSeconds = 20}) async {
    if (path.endsWith('/enroll')) {
      if (idempotencyKey != null) idempotencyKeys.add(idempotencyKey);
      return Ok({'enrolled': true} as T);
    }
    if (path.endsWith('/project')) {
      if (idempotencyKey != null) idempotencyKeys.add(idempotencyKey);
      generateCalls++;
      if (shouldTimeout && generateCalls == 1) {
        return Err<T>(const TimeoutFailure('Request timed out. Please try again.'));
      }
      if (responses.containsKey(path)) {
        if (responses[path] is ApiFailure) return Err<T>(responses[path] as ApiFailure);
        return Ok(responses[path] as T);
      }
    }
    return Err<T>(const ServerFailure('Not mocked'));
  }
}

void main() {
  group('CareerPathsRepository (FAKE-SERVER)', () {
    late FakeApiClient client;
    late CareerPathsRepository repo;

    setUp(() {
      client = FakeApiClient();
      repo = CareerPathsRepository(client);
    });

    test('enrol idempotency key reuse', () async {
      final res1 = await repo.enrollCareerPath('p1', 'key-123');
      final res2 = await repo.enrollCareerPath('p1', 'key-123');
      
      expect(res1 is Ok<bool>, true);
      expect(res2 is Ok<bool>, true);
      expect(client.idempotencyKeys, ['key-123', 'key-123']);
    });

    test('generate timeout then retry', () async {
      client.shouldTimeout = true;
      client.responses['/career-paths/p1/project'] = {
        'eligible': true,
        'progress': 60,
        'project': {
          'id': 'proj1',
          'title': 'Test Proj',
          'description': 'Desc',
          'requirements': [],
          'deliverables': [],
          'stretchGoals': [],
          'submission': null,
        }
      };

      final res1 = await repo.generateProject('p1', 'gen-key');
      expect(res1 is Err, true);

      final res2 = await repo.generateProject('p1', 'gen-key');
      expect(res2 is Ok, true);
      expect(client.idempotencyKeys, ['gen-key', 'gen-key']);
    });

    test('409 on generate below 50%', () async {
      client.responses['/career-paths/p2/project'] = const ConflictFailure('Must be at least 50%');
      
      final res = await repo.generateProject('p2', 'gen-key-2');
      expect(res is Err, true);
      expect((res as Err).error is ConflictFailure, true);
    });

    test('getCareerPath loads and parses career_path_detail.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/career_path_detail.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      final mockHttp = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/career-paths/cp_101');
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: mockHttp, tokenProvider: (f) async => 'fake-token');
      final repository = CareerPathsRepository(apiClient);

      final res = await repository.getCareerPath('cp_101');
      expect(res is Ok<CareerPathDetail>, isTrue);
      final detail = (res as Ok<CareerPathDetail>).data;
      expect(detail.id, 'cp_101');
      expect(detail.title, 'Full Stack Web Development');
      expect(detail.skills, contains('Flutter'));
    });

    test('enrollCareerPath loads and parses career_path_enroll.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/career_path_enroll.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      final mockHttp = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/career-paths/cp_101/enroll');
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: mockHttp, tokenProvider: (f) async => 'fake-token');
      final repository = CareerPathsRepository(apiClient);

      final res = await repository.enrollCareerPath('cp_101', 'key-enroll-1');
      expect(res is Ok<bool>, isTrue);
      expect((res as Ok<bool>).data, isTrue);
    });

    test('getProject loads and parses career_path_project.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/career_path_project.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      final mockHttp = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/career-paths/cp_101/project');
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: mockHttp, tokenProvider: (f) async => 'fake-token');
      final repository = CareerPathsRepository(apiClient);

      final res = await repository.getProject('cp_101');
      expect(res is Ok<CareerPathProjectResponse>, isTrue);
      final projectResp = (res as Ok<CareerPathProjectResponse>).data;
      expect(projectResp.eligible, isTrue);
      expect(projectResp.project?.title, 'Portfolio Web Application');
    });

    test('submitProject loads and parses project_submission_result.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/project_submission_result.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      final mockHttp = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/projects/proj_101/submission');
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: mockHttp, tokenProvider: (f) async => 'fake-token');
      final repository = CareerPathsRepository(apiClient);

      final res = await repository.submitProject(
        'proj_101',
        'key-submit-proj-1',
        linkUrl: 'https://github.com/stardy/portfolio',
      );
      expect(res is Ok<Map<String, dynamic>>, isTrue);
      final data = (res as Ok<Map<String, dynamic>>).data;
      expect(data['status'], 'PENDING_REVIEW');
    });
  });
}

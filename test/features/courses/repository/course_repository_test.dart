import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'dart:convert';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/courses/dto/course_dto.dart';
import 'package:stardy_app/features/courses/repository/course_repository.dart';
import 'package:stardy_app/features/courses/models/course_enums.dart';

void main() {
  group('CourseRepository tests (FAKE-SERVER)', () {
    test('listCourses loads and parses courses_list.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/courses_list.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/courses');
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = CourseRepository(apiClient);

      final result = await repo.listCourses();
      expect(result is Ok<PagedCourseResult>, isTrue);

      final paged = (result as Ok<PagedCourseResult>).data;
      expect(paged.items.length, 1);
      expect(paged.items.first.title, 'Flutter Fundamentals');
    });

    test('getCourse loads and parses course_detail.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/course_detail.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/courses/crs_flutter');
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = CourseRepository(apiClient);

      final result = await repo.getCourse('crs_flutter');
      expect(result is Ok<CourseDetail>, isTrue);

      final detail = (result as Ok<CourseDetail>).data;
      expect(detail.id, 'crs_flutter');
      expect(detail.modules.length, 2);
      expect(detail.assignments.length, 1);
    });

    test('getResources loads and parses course_resources.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/course_resources.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/courses/crs_flutter/resources');
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = CourseRepository(apiClient);

      final result = await repo.getResources('crs_flutter');
      expect(result is Ok<List<ResourceItem>>, isTrue);

      final items = (result as Ok<List<ResourceItem>>).data;
      expect(items.length, 2);
      expect(items.first.title, 'Flutter Official Documentation');
    });

    test('getModuleContent loads and parses module_content.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/module_content.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/modules/mod_01/content');
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = CourseRepository(apiClient);

      final result = await repo.getModuleContent('mod_01');
      expect(result is Ok<ModuleContent>, isTrue);

      final content = (result as Ok<ModuleContent>).data;
      expect(content.contentType, ContentType.video);
      expect(content.url, contains('module1.m3u8'));
    });

    test('completeModule loads and parses gamification_result.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/gamification_result.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/modules/mod_01/complete');
        return http.Response(jsonEncode({
          'success': true,
          'data': {
            'isCompleted': true,
            'gamification': fixtureJson['data'] ?? fixtureJson,
          }
        }), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = CourseRepository(apiClient);

      final result = await repo.completeModule('mod_01', 'idemp_key_complete');
      expect(result is Ok<CompleteModuleResult>, isTrue);

      final completeRes = (result as Ok<CompleteModuleResult>).data;
      expect(completeRes.isCompleted, isTrue);
      expect(completeRes.gamification?.xpAwarded, 150);
    });

    test('list with filters sends the right query parameters and no others', () async {
      http.Request? capturedRequest;
      final mockClient = MockClient((request) async {
        capturedRequest = request;
        final res = {
          'success': true,
          'data': {
            'items': [],
            'nextCursor': null
          }
        };
        return http.Response(jsonEncode(res), 200);
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(ApiClient(
            httpClient: mockClient, 
            tokenProvider: (_) async => 'fake-token'
          )),
        ]
      );

      final repo = container.read(courseRepositoryProvider);
      final result = await repo.listCourses(
        difficulty: Difficulty.beginner,
        category: CourseCategory.tech,
        cursor: 'abc',
        limit: 10,
      );

      expect(result is Ok<PagedCourseResult>, true);
      expect(capturedRequest!.url.path.endsWith('/courses'), true);
      expect(capturedRequest!.url.queryParameters, {
        'difficulty': 'BEGINNER',
        'category': 'TECH',
        'cursor': 'abc',
        'limit': '10'
      });
    });

    test('getModuleContent is never cached (repo directly returns result from API)', () async {
      int callCount = 0;
      http.Request? capturedRequest;
      final mockClient = MockClient((request) async {
        callCount++;
        capturedRequest = request;
        final res = {
          'success': true,
          'data': {
            'contentType': 'VIDEO',
            'url': 'http://example.com/video.m3u8'
          }
        };
        return http.Response(jsonEncode(res), 200);
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(ApiClient(
            httpClient: mockClient, 
            tokenProvider: (_) async => 'fake-token'
          )),
        ]
      );

      final repo = container.read(courseRepositoryProvider);
      
      final result1 = await repo.getModuleContent('m1');
      if (result1 is Err) fail((result1 as Err).error.message);
      final result2 = await repo.getModuleContent('m1');
      if (result2 is Err) fail((result2 as Err).error.message);
      
      expect(callCount, 2);
      expect(capturedRequest!.url.path.endsWith('/modules/m1/content'), true);
    });

    test('TTL behaviour for getCourse (60s cache)', () async {
      int callCount = 0;
      final mockClient = MockClient((request) async {
        callCount++;
        final res = {
          'success': true,
          'data': {
            'id': 'c1',
            'title': 'Test',
            'category': 'TECH',
            'difficulty': 'BEGINNER',
            'ratingAvg': 5.0,
            'ratingCount': 10,
            'moduleCount': 5,
            'description': 'desc',
            'createdAt': '2026-01-01T00:00:00Z',
            'modules': [],
            'assignments': []
          }
        };
        return http.Response(jsonEncode(res), 200);
      });

      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(ApiClient(
            httpClient: mockClient, 
            tokenProvider: (_) async => 'fake-token'
          )),
        ]
      );

      final sub = container.listen(courseDetailProvider('c1'), (prev, next) {});

      await container.read(courseDetailProvider('c1').future);
      expect(callCount, 1);

      await container.read(courseDetailProvider('c1').future);
      expect(callCount, 1);

      container.invalidate(courseDetailProvider('c1'));
      
      await container.read(courseDetailProvider('c1').future);
      expect(callCount, 2);
      
      sub.close();
    });
  });
}

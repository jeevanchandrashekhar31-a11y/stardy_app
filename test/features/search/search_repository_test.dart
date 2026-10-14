import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/search/repository/search_repository.dart';

void main() {
  group('SearchRepository tests (FAKE-SERVER)', () {
    test('searchCourses loads and parses search_courses.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/search_courses.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      String? capturedPath;
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        capturedPath = request.url.toString();
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = SearchRepository(apiClient);

      final result = await repo.searchCourses('flutter', limit: 10);
      expect(result is Ok, isTrue);

      final searchResult = (result as Ok).data;
      expect(searchResult.items.length, 1);
      expect(searchResult.items.first.title, 'Flutter Fundamentals');
      expect(capturedPath, contains('q=flutter'));
      expect(capturedPath, contains('type=COURSE'));
    });

    test('searchOpportunities loads and parses search_opportunities.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/search_opportunities.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      String? capturedPath;
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        capturedPath = request.url.toString();
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = SearchRepository(apiClient);

      final result = await repo.searchOpportunities('intern', limit: 10);
      expect(result is Ok, isTrue);

      final searchResult = (result as Ok).data;
      expect(searchResult.items.length, 1);
      expect(searchResult.items.first.title, 'Flutter Developer Intern');
      expect(capturedPath, contains('q=intern'));
      expect(capturedPath, contains('type=OPPORTUNITY'));
    });
  });
}

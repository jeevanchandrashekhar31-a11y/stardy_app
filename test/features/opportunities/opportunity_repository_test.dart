import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/opportunities/repository/opportunity_repository.dart';

void main() {
  group('OpportunityRepository tests (FAKE-SERVER)', () {
    test('getOpportunities loads and parses opportunities_list.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/opportunities_list.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      String? capturedPath;
      final client = MockClient((request) async {
        expect(request.method, 'GET');
        capturedPath = request.url.toString();
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = OpportunityRepositoryImpl(apiClient);

      final result = await repo.getOpportunities(type: 'INTERNSHIP', category: 'TECH', limit: 10);
      expect(result is Ok, isTrue);

      final paged = (result as Ok).data;
      expect(paged.items.length, 1);
      expect(paged.items.first.id, 'opp_101');
      expect(paged.items.first.title, 'Flutter Developer Intern');
      expect(capturedPath, contains('type=INTERNSHIP'));
      expect(capturedPath, contains('category=TECH'));
    });

    test('getOpportunity loads and parses opportunity_detail.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/opportunity_detail.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/opportunities/opp_101');
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = OpportunityRepositoryImpl(apiClient);

      final result = await repo.getOpportunity('opp_101');
      expect(result is Ok, isTrue);

      final detail = (result as Ok).data;
      expect(detail.summary.id, 'opp_101');
      expect(detail.summary.company, 'TechCorp');
      expect(detail.description, contains('cutting-edge Flutter'));
    });

    test('apply loads and parses opportunity_apply.json fixture with idempotency key', () async {
      final fixtureFile = File('test/fixtures/contract/opportunity_apply.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      String? capturedIdempKey;
      Map<String, dynamic>? capturedBody;

      final client = MockClient((request) async {
        expect(request.method, 'POST');
        expect(request.url.path, '/opportunities/opp_101/apply');
        capturedIdempKey = request.headers['Idempotency-Key'];
        capturedBody = jsonDecode(request.body) as Map<String, dynamic>;
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = OpportunityRepositoryImpl(apiClient);

      final result = await repo.apply('opp_101', 'key-apply-999', coverNote: 'Passionate Flutter dev');
      expect(result is Ok, isTrue);

      final response = (result as Ok).data;
      expect(response.status, 'SUBMITTED');
      expect(capturedIdempKey, 'key-apply-999');
      expect(capturedBody?['coverNote'], 'Passionate Flutter dev');
    });
  });
}

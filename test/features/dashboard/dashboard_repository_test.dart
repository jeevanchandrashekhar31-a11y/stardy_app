import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/dashboard/dto/home_dto.dart';
import 'package:stardy_app/features/dashboard/repository/dashboard_repository.dart';

void main() {
  group('DashboardRepository tests (FAKE-SERVER)', () {
    test('getHomeData loads and parses dashboard_home.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/dashboard_home.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/dashboard/home');
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = DashboardRepository(apiClient);

      final result = await repo.getHomeData();
      expect(result is Ok<HomeData>, isTrue);

      final homeData = (result as Ok<HomeData>).data;
      expect(homeData.greetingName, 'Alex');
      expect(homeData.continueCourse?.title, 'Flutter Fundamentals');
      expect(homeData.recommended.first.title, 'Dart In-Depth');
      expect(homeData.newCourses.first.title, 'Figma UI/UX Masterclass');
    });
  });
}

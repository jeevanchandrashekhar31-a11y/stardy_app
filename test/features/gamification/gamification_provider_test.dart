import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardy_app/features/gamification/repository/gamification_repository.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  group('GamificationRepository & Provider tests (FAKE-SERVER)', () {
    test('getMe loads and parses gamification_me.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/gamification_me.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/gamification/me');
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = GamificationRepository(apiClient);

      final result = await repo.getMe();
      expect(result is Ok, isTrue);

      final me = (result as Ok).data;
      expect(me.xp, 1899);
      expect(me.level, 12);
    });

    test('getBadges loads and parses gamification_badges.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/gamification_badges.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/gamification/badges');
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = GamificationRepository(apiClient);

      final result = await repo.getBadges();
      expect(result is Ok, isTrue);

      final badges = (result as Ok).data;
      expect(badges.length, 2);
      expect(badges.first.code, 'FIRST_LAUNCH');
    });

    test('getCertificates loads and parses certificates.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/certificates.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/certificates');
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = GamificationRepository(apiClient);

      final result = await repo.getCertificates();
      expect(result is Ok, isTrue);

      final certsPage = (result as Ok).data;
      expect(certsPage.items.length, 1);
      expect(certsPage.items.first.title, 'Flutter Developer Certificate');
    });

    test('FAKE-SERVER TTL hit does not refetch, refresh bypasses TTL, invalidateAfterProgress forces a refetch', () async {
      int fetchCount = 0;
      
      final client = MockClient((request) async {
        fetchCount++;
        return http.Response('''{
          "success": true,
          "data": {
            "xp": 0,
            "level": 1,
            "xpIntoLevel": 0,
            "xpForNextLevel": 100,
            "currentStreak": 0,
            "longestStreak": 0,
            "lastActiveAt": null,
            "activeToday": false
          }
        }''', 200, headers: {'content-type': 'application/json'});
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (force) async => "fake-token");
      
      final container = ProviderContainer(
        overrides: [
          apiClientProvider.overrideWithValue(apiClient),
        ],
      );

      await container.read(gamificationProvider.future);
      expect(fetchCount, 1);

      await container.read(gamificationProvider.future);
      expect(fetchCount, 1);
      
      container.invalidate(gamificationProvider);
      await container.read(gamificationProvider.future);
      expect(fetchCount, 2);

      invalidateAfterProgress(container.invalidate);
      await container.read(gamificationProvider.future);
      expect(fetchCount, 3);
    });
  });
}

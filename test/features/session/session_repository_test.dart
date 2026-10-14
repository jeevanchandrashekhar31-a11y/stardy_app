import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/session/session_repository.dart';

void main() {
  group('SessionRepository tests (FAKE-SERVER)', () {
    test('authSession loads and parses auth_session.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/auth_session.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      String? capturedPath;
      final client = MockClient((request) async {
        expect(request.method, 'POST');
        capturedPath = request.url.path;
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = SessionRepository(apiClient);

      final sessionResponse = await repo.authSession(displayName: 'Test User');
      expect(sessionResponse.user.id, 'usr_101');
      expect(sessionResponse.user.email, 'alex@example.com');
      expect(sessionResponse.onboardingCompleted, isTrue);
      expect(capturedPath, '/auth/session');
    });
  });
}

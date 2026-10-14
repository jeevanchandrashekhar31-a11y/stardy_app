import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/profile/dto/user_profile_dto.dart';
import 'package:stardy_app/features/profile/repository/profile_repository.dart';

void main() {
  group('ProfileRepository tests (FAKE-SERVER)', () {
    test('getMe loads and parses users_me.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/users_me.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;

      final client = MockClient((request) async {
        expect(request.method, 'GET');
        expect(request.url.path, '/users/me');
        return http.Response(jsonEncode(fixtureJson), 200);
      });

      final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => 'fake-token');
      final repo = ProfileRepository(apiClient);

      final result = await repo.getMe();
      expect(result is Ok<UserProfileDto>, isTrue);

      final user = (result as Ok<UserProfileDto>).data;
      expect(user.id, 'user_123');
      expect(user.name, 'Sai');
      expect(user.careerPaths.length, 1);
      expect(user.careerPaths.first.title, 'UI UX Design');
    });
  });
}

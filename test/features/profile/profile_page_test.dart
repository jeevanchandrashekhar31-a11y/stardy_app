import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardy_app/Views/Pages/profile.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('Profile header in loading, error, success', (tester) async {
    final clientError = MockClient((request) async {
      return http.Response('Error', 500);
    });
    final apiClientError = ApiClient(httpClient: clientError, tokenProvider: (f) async => "token");

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ apiClientProvider.overrideWithValue(apiClientError) ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    
    expect(find.text('Failed to load profile.'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    final clientSuccess = MockClient((request) async {
      if (request.url.path.contains('gamification/me')) {
        return http.Response('''{
          "success": true,
          "data": { "xp": 123, "level": 5, "xpIntoLevel": 20, "xpForNextLevel": 100, "currentStreak": 7, "longestStreak": 10, "lastActiveAt": null, "activeToday": true }
        }''', 200, headers: {'content-type': 'application/json'});
      } else if (request.url.path.contains('gamification/badges')) {
        return http.Response('''{
          "success": true,
          "data": { "items": [
            { "id": "b1", "code": "FIRST_LAUNCH", "name": "First Launch", "description": "", "iconUrl": null, "earned": true, "earnedAt": "2026-01-01T00:00:00Z" },
            { "id": "b2", "code": "UNKNOWN_CODE", "name": "Mystery", "description": "", "iconUrl": null, "earned": true, "earnedAt": "2026-01-01T00:00:00Z" }
          ] }
        }''', 200, headers: {'content-type': 'application/json'});
      } else if (request.url.path.contains('certificates')) {
        return http.Response('''{
          "success": true,
          "data": { "items": [
            { "id": "c1", "courseId": "cs1", "courseTitle": "Math", "title": "Math 101", "certificateUrl": "https://example.com/cert", "issuedAt": "2026-01-01T00:00:00Z" },
            { "id": "c2", "courseId": "cs2", "courseTitle": "Art", "title": "Art 101", "certificateUrl": "http://example.com/bad", "issuedAt": "2026-01-01T00:00:00Z" }
          ] }
        }''', 200, headers: {'content-type': 'application/json'});
      } else {
        return http.Response('''{
          "success": true,
          "data": { "id": "1", "name": "Test User", "email": "test@example.com", "createdAt": "2023-10-09T00:00:00Z", "careerPaths": [] }
        }''', 200, headers: {'content-type': 'application/json'});
      }
    });
    final apiClientSuccess = ApiClient(httpClient: clientSuccess, tokenProvider: (f) async => "token");

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ apiClientProvider.overrideWithValue(apiClientSuccess) ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    expect(find.text('Test User'), findsOneWidget);
    expect(find.textContaining('123'), findsWidgets);
    expect(find.textContaining('5'), findsWidgets); 
  });
}

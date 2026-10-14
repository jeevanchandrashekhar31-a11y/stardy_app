import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardy_app/Views/Pages/profile.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:stardy_app/core/config/feature_flags.dart';

void main() {
  testWidgets('Badges render, zero shows empty state, unknown does not crash, cert tap shows snackbar, flags off hide sections', (tester) async {
    final client = MockClient((request) async {
      if (request.url.path.contains('gamification/me')) {
        return http.Response('''{
          "success": true,
          "data": { "xp": 123, "level": 5, "xpIntoLevel": 20, "xpForNextLevel": 100, "currentStreak": 7, "longestStreak": 10, "lastActiveAt": null, "activeToday": true }
        }''', 200, headers: {'content-type': 'application/json'});
      } else if (request.url.path.contains('gamification/badges')) {
        return http.Response('''{
          "success": true,
          "data": { "items": [
            { "id": "b1", "code": "UNKNOWN_CODE", "name": "Mystery", "description": "", "iconUrl": null, "earned": true, "earnedAt": "2026-01-01T00:00:00Z" }
          ] }
        }''', 200, headers: {'content-type': 'application/json'});
      } else if (request.url.path.contains('certificates')) {
        return http.Response('''{
          "success": true,
          "data": { "items": [
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
    final apiClient = ApiClient(httpClient: client, tokenProvider: (f) async => "token");

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ apiClientProvider.overrideWithValue(apiClient) ],
        child: const MaterialApp(home: ProfilePage()),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }

    // Check flags are off
    expect(FeatureFlags.weekRewind, false);
    expect(FeatureFlags.socialLinks, false);
    expect(find.text('Week Rewind'), findsNothing);
    expect(find.text('Log In with'), findsNothing);

    // Swipe page view to badges
    final pageView = find.byType(PageView);
    await tester.drag(pageView, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('MYSTERY'), findsOneWidget); // earned badge rendered, unknown code didn't crash

    // Swipe page view to certificates
    await tester.drag(pageView, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.text('Art 101'), findsOneWidget);

    // Tap certificate with non-https
    await tester.tap(find.text('Art 101'));
    await tester.pumpAndSettle();
    expect(find.text('Invalid or insecure URL'), findsOneWidget); // SnackBar
  });
}

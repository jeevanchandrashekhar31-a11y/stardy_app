import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardy_app/Views/Pages/learn_page.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('streak banner hidden at 0 and while loading, visible at > 0', (tester) async {
    final clientZero = MockClient((request) async {
      return http.Response('''{
        "success": true,
        "data": { "xp": 0, "level": 1, "xpIntoLevel": 0, "xpForNextLevel": 100, "currentStreak": 0, "longestStreak": 0, "lastActiveAt": null, "activeToday": false }
      }''', 200, headers: {'content-type': 'application/json'});
    });
    final apiClientZero = ApiClient(httpClient: clientZero, tokenProvider: (force) async => "token");

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ apiClientProvider.overrideWithValue(apiClientZero) ],
        child: const MaterialApp(home: Learnpage()),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.textContaining('learning Streak !!'), findsNothing);

    final clientSeven = MockClient((request) async {
      return http.Response('''{
        "success": true,
        "data": { "xp": 100, "level": 5, "xpIntoLevel": 20, "xpForNextLevel": 100, "currentStreak": 7, "longestStreak": 10, "lastActiveAt": null, "activeToday": true }
      }''', 200, headers: {'content-type': 'application/json'});
    });
    final apiClientSeven = ApiClient(httpClient: clientSeven, tokenProvider: (force) async => "token");

    await tester.pumpWidget(
      ProviderScope(
        overrides: [ apiClientProvider.overrideWithValue(apiClientSeven) ],
        child: const MaterialApp(home: Learnpage()),
      ),
    );
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 50));
    }
    expect(find.text('Continue your 7 day learning Streak !! 🔥'), findsOneWidget);
  });
}

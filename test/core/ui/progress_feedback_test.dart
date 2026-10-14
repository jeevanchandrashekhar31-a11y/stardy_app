import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardy_app/core/ui/progress_feedback.dart';
import 'package:stardy_app/core/models/gamification_result.dart';
import 'package:stardy_app/Views/CareerPath/level_up_page.dart';

void main() {
  testWidgets('progress feedback: null does nothing', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) {
                return ElevatedButton(
                  onPressed: () {
                    showProgressFeedback(context, ref, null);
                  },
                  child: const Text('Tap'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap'));
    await tester.pumpAndSettle();

    expect(find.byType(LevelUpPage), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets('progress feedback: xp>0 without level-up shows only snackbar', (tester) async {
    const result = GamificationResult(
      xpAwarded: 150,
      xp: 200,
      level: 2,
      leveledUp: false,
      badgesUnlocked: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) {
                return ElevatedButton(
                  onPressed: () {
                    showProgressFeedback(context, ref, result);
                  },
                  child: const Text('Tap'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap'));
    await tester.pump(); // SnackBar appears

    expect(find.byType(LevelUpPage), findsNothing);
    expect(find.text('+150 XP'), findsOneWidget);
  });

  testWidgets('progress feedback: pushes only when leveledUp is true', (tester) async {
    const result = GamificationResult(
      xpAwarded: 300,
      xp: 1500,
      level: 3,
      leveledUp: true,
      newLevel: 3,
      badgesUnlocked: [],
    );

    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          home: Scaffold(
            body: Consumer(
              builder: (context, ref, child) {
                return ElevatedButton(
                  onPressed: () {
                    showProgressFeedback(context, ref, result);
                  },
                  child: const Text('Tap'),
                );
              },
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Tap'));
    await tester.pumpAndSettle(); // Navigate

    expect(find.byType(LevelUpPage), findsOneWidget);
    expect(find.text('LEVEL UP!'), findsOneWidget);
  });
}

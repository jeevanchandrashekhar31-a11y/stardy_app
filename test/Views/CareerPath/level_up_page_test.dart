import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/Views/CareerPath/level_up_page.dart';
import 'package:stardy_app/core/models/gamification_result.dart';

void main() {
  testWidgets('LevelUpPage renders from a result', (tester) async {
    const result = GamificationResult(
      xpAwarded: 500,
      xp: 2000,
      level: 3,
      leveledUp: true,
      newLevel: 4,
      badgesUnlocked: [
        BadgeUnlock(code: 'CODE1', name: 'Master badge'),
      ],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: LevelUpPage(result: result),
      ),
    );

    expect(find.text('4'), findsOneWidget); // newLevel
    expect(find.text('+500'), findsOneWidget); // xpAwarded
    expect(find.text('Master badge'), findsOneWidget); // badge
  });
}

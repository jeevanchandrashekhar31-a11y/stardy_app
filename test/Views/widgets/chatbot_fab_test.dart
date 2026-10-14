import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/core/config/feature_flags.dart';
import 'package:stardy_app/Views/widgets/chatbot_fab.dart';

void main() {
  testWidgets('StarbuddyFabButton is absent when FeatureFlags.starbuddy is false', (tester) async {
    expect(FeatureFlags.starbuddy, isFalse);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              StarbuddyFabButton(),
            ],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // The FAB container and avatar image should be completely absent
    expect(find.byType(GestureDetector), findsNothing);
    expect(find.byType(Image), findsNothing);
    expect(find.byType(SizedBox), findsWidgets);
  });
}

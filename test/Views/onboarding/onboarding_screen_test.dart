import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardy_app/Views/onboarding/onboarding_screen.dart';
import 'package:stardy_app/features/onboarding/onboarding_form.dart';
import 'package:stardy_app/features/onboarding/onboarding_controller.dart';

void main() {
  Widget createWidget({ProviderContainer? container}) {
    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: OnboardingScreen(),
        ),
      );
    }
    return const ProviderScope(
      child: MaterialApp(
        home: OnboardingScreen(),
      ),
    );
  }

  group('Onboarding UI tests', () {
    testWidgets('Next is disabled until valid, testing navigation and toggles', (WidgetTester tester) async {
      await tester.pumpWidget(createWidget());

      // Page 0: Intro (valid by default)
      expect(find.text('Start your journey\nwith STARDY!'), findsOneWidget);
      final forwardIcon = find.byIcon(Icons.arrow_forward);
      
      // Tap next to go to Page 1
      await tester.tap(forwardIcon);
      await tester.pumpAndSettle();

      // Page 1: Career goal
      expect(find.text('What is your\ncareer goal?'), findsOneWidget);
      // Next is disabled, tapping shouldn't advance
      await tester.tap(forwardIcon);
      await tester.pumpAndSettle();
      expect(find.text('What is your\ncareer goal?'), findsOneWidget); // still here

      // Enter valid goal
      await tester.enterText(find.byType(TextField).first, 'Senior Dev');
      await tester.pumpAndSettle();
      
      // Tap next
      await tester.tap(forwardIcon);
      await tester.pumpAndSettle();

      // Page 2: Purpose
      expect(find.text('Define the Purpose for\nusing Stardy AI ?'), findsOneWidget);
      // Dropdown interaction
      await tester.tap(find.byType(DropdownButtonFormField<OnboardingPurpose>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Learn Skills').last);
      await tester.pumpAndSettle();
      
      // Tap next
      await tester.tap(forwardIcon);
      await tester.pumpAndSettle();

      // Page 3: How Heard
      expect(find.text('How did you hear\nabout us?'), findsOneWidget);
      await tester.tap(find.byType(DropdownButtonFormField<OnboardingHowHeard>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Influencer').last);
      await tester.pumpAndSettle();
      
      // Tap next
      await tester.tap(forwardIcon);
      await tester.pumpAndSettle();

      // Page 4: Influencer (appeared because of choice)
      expect(find.text('Influencer details'), findsOneWidget);
      await tester.enterText(find.widgetWithText(TextField, 'Influencer Name'), 'Some Guy');
      await tester.enterText(find.widgetWithText(TextField, 'Referral Code (Optional)'), 'CODE_123');
      await tester.pumpAndSettle();

      // Tap next
      await tester.tap(forwardIcon);
      await tester.pumpAndSettle();

      // Page 5: Expectation
      expect(find.text('What do you expect\nto achieve?'), findsOneWidget);
      // enter < 10 chars
      await tester.enterText(find.widgetWithText(TextField, 'Minimum 10 characters...'), 'short');
      await tester.pumpAndSettle();
      // Verify counter/error
      expect(find.text('Expectation must be between 10 and 500 characters'), findsOneWidget);
      // Still can't go next
      await tester.tap(forwardIcon);
      await tester.pumpAndSettle();
      expect(find.text('What do you expect\nto achieve?'), findsOneWidget);

      // Enter valid
      await tester.enterText(find.widgetWithText(TextField, 'Minimum 10 characters...'), 'long enough expectation here');
      await tester.pumpAndSettle();

      // Tap next
      await tester.tap(forwardIcon);
      await tester.pumpAndSettle();

      // Page 6: Similar apps
      expect(find.text('Have you used\nsimilar apps before?'), findsOneWidget);
      // Tap Yes
      await tester.tap(find.text('Yes'));
      await tester.pumpAndSettle();
      // Field appears
      expect(find.widgetWithText(TextField, 'Tell us about your experience...'), findsOneWidget);

      // Tap No
      await tester.tap(find.text('No'));
      await tester.pumpAndSettle();
      // Field disappears
      expect(find.widgetWithText(TextField, 'Tell us about your experience...'), findsNothing);

      // Finish button should be enabled - check GestureDetector onTap is not null
      final finishGestureFinder = find.ancestor(of: find.text('Finish'), matching: find.byType(GestureDetector)).first;
      final finishGesture = tester.widget<GestureDetector>(finishGestureFinder);
      expect(finishGesture.onTap, isNotNull);
    });

    testWidgets('influencer page disappears if choice changes', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createWidget(container: container));

      // Advance to How Heard
      container.read(onboardingFormProvider.notifier).updateCareerGoal('Valid goal');
      container.read(onboardingFormProvider.notifier).updatePurpose(OnboardingPurpose.learnSkills);
      
      final forwardIcon = find.byIcon(Icons.arrow_forward);
      // intro -> career -> purpose -> howheard
      await tester.tap(forwardIcon);
      await tester.pumpAndSettle();
      await tester.tap(forwardIcon);
      await tester.pumpAndSettle();
      await tester.tap(forwardIcon);
      await tester.pumpAndSettle();

      // Page 3: How Heard
      expect(find.text('How did you hear\nabout us?'), findsOneWidget);
      
      // Select Influencer
      await tester.tap(find.byType(DropdownButtonFormField<OnboardingHowHeard>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Influencer').last);
      await tester.pumpAndSettle();
      
      // Next
      await tester.tap(forwardIcon);
      await tester.pumpAndSettle();
      expect(find.text('Influencer details'), findsOneWidget);

      // Go back
      await tester.tap(find.byIcon(Icons.arrow_back));
      await tester.pumpAndSettle();
      
      // Select Google instead
      await tester.tap(find.byType(DropdownButtonFormField<OnboardingHowHeard>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Google').last);
      await tester.pumpAndSettle();

      // Next
      await tester.tap(forwardIcon);
      await tester.pumpAndSettle();
      // Should skip Influencer and go to Expectation
      expect(find.text('What do you expect\nto achieve?'), findsOneWidget);
    });

    testWidgets('state survives a simulated rotation/rebuild', (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(createWidget(container: container));
      
      final forwardIcon = find.byIcon(Icons.arrow_forward);
      await tester.tap(forwardIcon); // go to career
      await tester.pumpAndSettle();
      
      await tester.enterText(find.byType(TextField).first, 'Simulated Goal');
      await tester.pumpAndSettle();
      
      // simulate rebuild by pumping a new widget with the SAME container
      await tester.pumpWidget(createWidget(container: container));
      await tester.pumpAndSettle();
      
      final textFinder = find.text('Simulated Goal');
      expect(textFinder, findsOneWidget);
    });
  });
}

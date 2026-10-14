import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardy_app/Views/onboarding/onboarding_screen.dart';
import 'package:stardy_app/features/onboarding/onboarding_form.dart';
import 'package:stardy_app/features/onboarding/onboarding_controller.dart';
import 'package:stardy_app/features/session/session_controller.dart';
import 'package:stardy_app/core/network/api_client.dart';

// Fake server API client
class FakeApiClient implements ApiClient {
  int postCallCount = 0;
  String? lastIdempotencyKey;
  Result<dynamic> nextPostResult = Ok(null);

  @override
  Future<Result<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
    int timeoutSeconds = 20,
  }) async {
    postCallCount++;
    lastIdempotencyKey = idempotencyKey;
    
    // Simulate network delay to allow testing 'isSubmitting' state
    await Future.delayed(const Duration(milliseconds: 50));
    
    if (nextPostResult is Err<dynamic>) {
      return Err<T>((nextPostResult as Err<dynamic>).error);
    }
    return Ok<T>(null as T);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class MockSessionController extends StateNotifier<SessionState> implements SessionController {
  int refreshCallCount = 0;

  MockSessionController() : super(SessionSignedOut());

  @override
  Future<void> refresh() async {
    refreshCallCount++;
  }

  @override
  Future<void> signOut() async {}

  @override
  int get sessionEpoch => 0;
}

void main() {
  late FakeApiClient fakeApiClient;
  late MockSessionController mockSessionController;

  setUp(() {
    fakeApiClient = FakeApiClient();
    mockSessionController = MockSessionController();
  });

  Widget createWidget() {
    return ProviderScope(
      overrides: [
        apiClientProvider.overrideWithValue(fakeApiClient),
        sessionControllerProvider.overrideWith((ref) => mockSessionController),
      ],
      child: const MaterialApp(
        home: OnboardingScreen(),
      ),
    );
  }

  Future<void> advanceToLastPage(WidgetTester tester) async {
    await tester.pumpWidget(createWidget());
    
    final state = tester.state<ConsumerState>(find.byType(OnboardingScreen));
    final container = ProviderScope.containerOf(state.context);
    
    // Fill out form
    container.read(onboardingFormProvider.notifier).updateCareerGoal('Valid goal');
    container.read(onboardingFormProvider.notifier).updatePurpose(OnboardingPurpose.learnSkills);
    container.read(onboardingFormProvider.notifier).updateHowHeard(OnboardingHowHeard.google);
    container.read(onboardingFormProvider.notifier).updateExpectation('Valid expectation');
    container.read(onboardingFormProvider.notifier).updateHasUsedSimilarApps(false);
    
    final forwardIcon = find.byIcon(Icons.arrow_forward);
    // intro -> career -> purpose -> howheard -> expectation -> similar apps
    for (int i = 0; i < 5; i++) {
      await tester.tap(forwardIcon);
      await tester.pumpAndSettle();
    }
  }

  group('Onboarding Submit Integration (FAKE-SERVER)', () {
    testWidgets('double-tap submit sends exactly one request', (tester) async {
      await advanceToLastPage(tester);
      
      fakeApiClient.nextPostResult = Ok(null);
      
      final finishButtonFinder = find.byKey(const Key('finish_button'));
      
      await tester.tap(finishButtonFinder);
      await tester.pump(); // rebuild UI to disable the button
      
      // Try tapping again while it's submitting
      await tester.tap(finishButtonFinder);
      
      await tester.pumpAndSettle();
      
      expect(fakeApiClient.postCallCount, 1);
      expect(mockSessionController.refreshCallCount, 1);
    });

    testWidgets('a retry after a network failure sends the identical Idempotency-Key', (tester) async {
      await advanceToLastPage(tester);
      
      fakeApiClient.nextPostResult = Err(const NetworkFailure('Network error'));
      
      final finishButtonFinder = find.byKey(const Key('finish_button'));
      
      await tester.tap(finishButtonFinder);
      await tester.pumpAndSettle();
      
      expect(fakeApiClient.postCallCount, 1);
      final firstKey = fakeApiClient.lastIdempotencyKey;
      expect(firstKey, isNotNull);
      
      // UI should show error and "Retry"
      expect(find.text('Network error. Please check your connection.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      
      // Tap again (retry)
      fakeApiClient.nextPostResult = Ok(null);
      await tester.tap(finishButtonFinder);
      await tester.pumpAndSettle();
      
      expect(fakeApiClient.postCallCount, 2);
      expect(fakeApiClient.lastIdempotencyKey, firstKey);
      expect(mockSessionController.refreshCallCount, 1);
    });

    testWidgets('409 leads to /main', (tester) async {
      await advanceToLastPage(tester);
      
      fakeApiClient.nextPostResult = Err(const ConflictFailure('Already done'));
      
      final finishButtonFinder = find.byKey(const Key('finish_button'));
      
      await tester.tap(finishButtonFinder);
      await tester.pumpAndSettle();
      
      expect(fakeApiClient.postCallCount, 1);
      // 409 is treated as success, should trigger refresh (which routes to /main)
      expect(mockSessionController.refreshCallCount, 1);
    });

    testWidgets('400 shows the message and stays', (tester) async {
      await advanceToLastPage(tester);
      
      fakeApiClient.nextPostResult = Err(const ValidationFailure('Invalid expectation length'));
      
      final finishButtonFinder = find.byKey(const Key('finish_button'));
      
      await tester.tap(finishButtonFinder);
      await tester.pumpAndSettle();
      
      expect(fakeApiClient.postCallCount, 1);
      // UI shows message
      expect(find.text('Invalid expectation length'), findsOneWidget);
      expect(mockSessionController.refreshCallCount, 0); // Not successful
    });
  });
}

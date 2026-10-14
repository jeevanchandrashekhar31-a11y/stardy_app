import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardy_app/Routers/routes.dart';
import 'package:stardy_app/features/session/session_controller.dart';
import 'package:stardy_app/core/models/user.dart';
import 'package:flutter/material.dart';

// Fake controller to inject state directly
class FakeSessionController extends StateNotifier<SessionState> implements SessionController {
  FakeSessionController(super.state);

  
  @override
  Future<void> refresh() async {}

  @override
  Future<void> signOut() async {}

  @override
  int get sessionEpoch => 0;

  void setState(SessionState newState) {
    state = newState;
  }
}

void main() {
  final user = const User(id: '1', name: 'Test', email: 'test@test.com');

  Widget buildApp(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: Consumer(builder: (context, ref, _) {
        final router = ref.watch(routerProvider);
        return MaterialApp.router(
          routerConfig: router,
        );
      }),
    );
  }

  group('Router Redirect Table', () {
    testWidgets('Table test: every session state', (tester) async {
      final statesToTest = [
        SessionBooting(),
        SessionSignedOut(),
        SessionNeedsOnboarding(),
        SessionReady(user),
        SessionFailed('error'),
      ];

      for (final state in statesToTest) {
        final controller = FakeSessionController(state);
        final container = ProviderContainer(
          overrides: [
            sessionControllerProvider.overrideWith((ref) => controller),
            splashFinishedProvider.overrideWith((ref) => true),
          ],
        );

        await tester.pumpWidget(buildApp(container));
        await tester.pumpAndSettle();

        final router = container.read(routerProvider);
        final loc = router.routerDelegate.currentConfiguration.uri.path;

        if (state is SessionBooting) {
          expect(loc, '/splash');
        } else if (state is SessionSignedOut) {
          expect(loc, '/auth');
        } else if (state is SessionNeedsOnboarding) {
          expect(loc, '/onboarding');
        } else if (state is SessionReady) {
          expect(loc, '/main');
        } else if (state is SessionFailed) {
          expect(loc, '/session_error');
        }
        container.dispose();
      }
    });

    testWidgets('Cold start with signed-out lands on /auth', (tester) async {
      final controller = FakeSessionController(SessionBooting());
      final container = ProviderContainer(
        overrides: [
          sessionControllerProvider.overrideWith((ref) => controller),
          splashFinishedProvider.overrideWith((ref) => false),
        ],
      );


      await tester.pumpWidget(buildApp(container));
      await tester.pumpAndSettle();

      final router = container.read(routerProvider);
      
      // Before splash finishes, we should be on /splash
      expect(router.routerDelegate.currentConfiguration.uri.path, '/splash');

      // Then session becomes SignedOut
      controller.setState(SessionSignedOut());
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/splash');

      // Then splash finishes
      container.read(splashFinishedProvider.notifier).state = true;
      await tester.pumpAndSettle();
      
      expect(router.routerDelegate.currentConfiguration.uri.path, '/auth');
      container.dispose();
    });

    testWidgets('Cold start with ready session lands on /main', (tester) async {
      final controller = FakeSessionController(SessionBooting());
      final container = ProviderContainer(
        overrides: [
          sessionControllerProvider.overrideWith((ref) => controller),
          splashFinishedProvider.overrideWith((ref) => false),
        ],
      );


      await tester.pumpWidget(buildApp(container));
      await tester.pumpAndSettle();

      final router = container.read(routerProvider);
      
      // Before splash finishes, we should be on /splash
      expect(router.routerDelegate.currentConfiguration.uri.path, '/splash');

      // Then session becomes Ready
      controller.setState(SessionReady(user));
      await tester.pumpAndSettle();
      expect(router.routerDelegate.currentConfiguration.uri.path, '/splash');

      // Then splash finishes
      container.read(splashFinishedProvider.notifier).state = true;
      await tester.pumpAndSettle();
      
      expect(router.routerDelegate.currentConfiguration.uri.path, '/main');
      container.dispose();
    });

    testWidgets('once onboardingCompleted is true, navigating to /onboarding redirects to /main', (tester) async {
      final controller = FakeSessionController(SessionReady(user));
      final container = ProviderContainer(
        overrides: [
          sessionControllerProvider.overrideWith((ref) => controller),
          splashFinishedProvider.overrideWith((ref) => true),
        ],
      );


      await tester.pumpWidget(buildApp(container));
      await tester.pumpAndSettle();

      final router = container.read(routerProvider);
      
      expect(router.routerDelegate.currentConfiguration.uri.path, '/main');

      // Attempt to navigate to /onboarding
      router.go('/onboarding');
      await tester.pumpAndSettle();

      // It should redirect back to /main
      expect(router.routerDelegate.currentConfiguration.uri.path, '/main');

      container.dispose();
    });
  });
}

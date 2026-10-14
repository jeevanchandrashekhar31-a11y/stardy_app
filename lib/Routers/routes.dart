import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:stardy_app/Views/widgets/nav_bar.dart';

import '../Views/screens/splash_screen.dart';
import '../Views/screens/error_screen.dart';
import '../Views/Pages/signup.dart';
import '../Views/onboarding/onboarding_screen.dart';
import '../features/session/session_controller.dart';
import '../core/ui/loading_view.dart';
import '../core/ui/error_view.dart';
import '../services/auth_service.dart';
import 'package:flutter/material.dart';

final splashFinishedProvider = StateProvider<bool>((ref) => false);

class RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  RouterNotifier(this._ref) {
    _ref.listen(sessionControllerProvider, (_, _) => notifyListeners());
    _ref.listen(splashFinishedProvider, (_, _) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final notifier = RouterNotifier(ref);

  return GoRouter(
    initialLocation: '/splash',
    refreshListenable: notifier,
    redirect: (context, state) {
      final sessionState = ref.read(sessionControllerProvider);
      final splashFinished = ref.read(splashFinishedProvider);
      final path = state.uri.path;

      if (!splashFinished) {
        return path == '/splash' ? null : '/splash';
      }

      // If we reach here, splashFinished is true.
      if (sessionState is SessionBooting) {
        // Technically shouldn't happen because Booting shouldn't be long,
        // but if splash finished and it's still booting, wait on splash.
        return path == '/splash' ? null : '/splash';
      }

      if (sessionState is SessionSignedOut) {
        return path == '/auth' ? null : '/auth';
      }

      if (sessionState is SessionNeedsOnboarding) {
        return path == '/onboarding' ? null : '/onboarding';
      }

      if (sessionState is SessionReady) {
        if (path == '/auth' ||
            path == '/onboarding' ||
            path == '/splash') {
          return '/main';
        }
        return null;
      }

      if (sessionState is SessionSyncing) {
        if (path != '/syncing') {
          return '/syncing';
        }
        return null;
      }

      if (sessionState is SessionFailed) {
        if (path != '/session_error') {
          return '/session_error';
        }
        return null;
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(path: '/auth', builder: (context, state) => const AuthPage()),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) => const OnboardingScreen(),
      ),
      GoRoute(path: '/main', builder: (context, state) => const NavbarPage()),
      GoRoute(
        path: '/syncing',
        builder: (context, state) => const Scaffold(
          body: LoadingView(message: 'Syncing your session...'),
        ),
      ),
      GoRoute(
        path: '/session_error',
        builder: (context, state) {
          final sessionState = ref.read(sessionControllerProvider);
          return Scaffold(
            body: ErrorView(
              message: sessionState is SessionFailed
                  ? sessionState.error
                  : 'Session error',
              onRetry: () =>
                  ref.read(sessionControllerProvider.notifier).refresh(),
              actionLabel: 'Sign Out',
              onAction: () {
                AuthService.instance.signOut();
              },
            ),
          );
        },
      ),
    ],
    errorBuilder: (context, state) => const ErrorScreen(),
  );
});

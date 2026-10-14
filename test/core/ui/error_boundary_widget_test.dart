import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/core/ui/error_view.dart';
import 'package:stardy_app/main.dart';

void main() {
  group('ErrorBoundaryApp Widget Tests', () {
    testWidgets('displays generic safe error message and never displays raw exception text in release mode', (tester) async {
      const secretErrorString = 'SECRET_FIREBASE_INTERNAL_ERROR_403_KEY_FAILED';
      final exception = Exception(secretErrorString);

      await tester.pumpWidget(ErrorBoundaryApp(error: exception, isDebug: false));

      // Must find ErrorView
      expect(find.byType(ErrorView), findsOneWidget);

      // Must show safe generic message
      expect(find.text('Something went wrong. Please try again.'), findsOneWidget);

      // Must NOT display raw exception text or exception.toString()
      expect(find.textContaining(secretErrorString), findsNothing);
      expect(find.textContaining('Exception:'), findsNothing);

      // Must display Retry button
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('displays real error message in debug mode to aid developer configuration', (tester) async {
      const configError = 'APP_ENV is missing or empty.';
      const exception = FormatException(configError);

      await tester.pumpWidget(const ErrorBoundaryApp(error: exception, isDebug: true));

      // Must find ErrorView
      expect(find.byType(ErrorView), findsOneWidget);

      // Must show real developer error message
      expect(find.text(configError), findsOneWidget);

      // Must display Retry button
      expect(find.text('Retry'), findsOneWidget);
    });

    testWidgets('retry callback triggers without crash', (tester) async {
      await tester.pumpWidget(
        ErrorBoundaryApp(
          error: Exception('Init failure'),
          isDebug: false,
        ),
      );

      expect(find.text('Retry'), findsOneWidget);
      await tester.tap(find.text('Retry'));
      await tester.pump(const Duration(milliseconds: 600));
      // Verifies no widget build crash
      expect(find.byType(ErrorView), findsOneWidget);
    });
  });
}

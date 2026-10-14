import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/core/ui/empty_view.dart';
import 'package:stardy_app/core/ui/error_view.dart';
import 'package:stardy_app/core/ui/loading_view.dart';

void main() {
  Widget wrapper(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('State Views', () {
    testWidgets('LoadingView displays indicator and message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapper(const LoadingView(message: 'Loading data...')),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Loading data...'), findsOneWidget);
    });

    testWidgets('EmptyView displays icon and message', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrapper(
          const EmptyView(message: 'No items found', icon: Icons.search_off),
        ),
      );

      expect(find.byIcon(Icons.search_off), findsOneWidget);
      expect(find.text('No items found'), findsOneWidget);
    });

    testWidgets('ErrorView displays message and retry fires once on double tap', (
      WidgetTester tester,
    ) async {
      int retryCount = 0;
      await tester.pumpWidget(
        wrapper(
          ErrorView(
            message: 'Something went wrong',
            onRetry: () {
              retryCount++;
            },
          ),
        ),
      );

      expect(find.text('Something went wrong'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);

      final button = find.byType(ElevatedButton);

      // Tap twice quickly
      await tester.tap(button);
      await tester.tap(button);

      // Since there is a debounce of 500ms, we pump just enough to process taps
      await tester.pump();

      expect(retryCount, 1);

      // Advance time to reset debounce
      await tester.pump(const Duration(milliseconds: 600));
    });
  });
}

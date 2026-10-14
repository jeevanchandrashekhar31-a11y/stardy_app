import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardy_app/Views/Courses/Course_SUB_Pages/grades_page.dart';
import 'package:stardy_app/features/grades/models/grade_models.dart';
import 'package:stardy_app/features/grades/dto/grades_response.dart';
import 'package:stardy_app/features/grades/repository/grades_repository.dart';
import 'package:stardy_app/core/network/api_client.dart';


class FakeGradesRepository extends GradesRepository {
  final Future<Result<GradesResponse>> Function(String? courseId, String? cursor, int limit) handler;

  FakeGradesRepository(this.handler) : super(ApiClient());

  @override
  Future<Result<GradesResponse>> getGrades({String? courseId, String? cursor, int limit = 20}) async {
    return handler(courseId, cursor, limit);
  }
}

void main() {
  Widget buildApp(GradesRepository repository) {
    return ProviderScope(
      overrides: [
        gradesRepositoryProvider.overrideWithValue(repository),
      ],
      child: const MaterialApp(
        home: GradesPage(),
      ),
    );
  }

  group('GradesPage Widget Tests', () {
    testWidgets('empty state', (tester) async {
      final repo = FakeGradesRepository((courseId, cursor, limit) async {
        return Ok(const GradesResponse(items: []));
      });

      await tester.pumpWidget(buildApp(repo));
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      
      await tester.pumpAndSettle();
      
      expect(find.text('No graded work yet'), findsOneWidget);
    });

    testWidgets('one page success with unknown letter mapping', (tester) async {
      final repo = FakeGradesRepository((courseId, cursor, limit) async {
        return Ok(GradesResponse(
          items: [
            GradeItem(
              kind: GradeKind.assignment,
              refId: 'a1',
              title: 'First Assignment',
              courseTitle: 'Course 1',
              percentage: 85,
              letter: 'B',
              submittedAt: DateTime.now(),
            ),
            GradeItem(
              kind: GradeKind.quiz,
              refId: 'q1',
              title: 'First Quiz',
              courseTitle: 'Course 1',
              percentage: 45,
              letter: null, // unknown/missing letter
              submittedAt: DateTime.now(),
            ),
          ],
        ));
      });

      await tester.pumpWidget(buildApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('First Assignment'), findsOneWidget);
      expect(find.text('B'), findsOneWidget); // specific letter
      
      expect(find.text('First Quiz'), findsOneWidget);
      expect(find.text('-'), findsOneWidget); // fallback for missing letter
    });

    testWidgets('error with Retry', (tester) async {
      int attempts = 0;
      final repo = FakeGradesRepository((courseId, cursor, limit) async {
        attempts++;
        if (attempts == 1) {
          return Err(const ServerFailure('Network failure'));
        }
        return Ok(const GradesResponse(items: []));
      });

      await tester.pumpWidget(buildApp(repo));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong. Please try again.'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);

      await tester.tap(find.text('Retry'));
      await tester.pump(); // Start the retry
      await tester.pumpAndSettle();

      expect(find.text('No graded work yet'), findsOneWidget);
      await tester.pump(const Duration(milliseconds: 500)); // Clear the ErrorView retry timer
    });

    testWidgets('multiple pages (infinite scroll)', (tester) async {
      int fetchCalls = 0;
      final repo = FakeGradesRepository((courseId, cursor, limit) async {
        fetchCalls++;
        if (cursor == null) {
          return Ok(GradesResponse(
            items: List.generate(20, (i) => GradeItem(
              kind: GradeKind.assignment,
              refId: 'page1_$i',
              title: 'Title 1_$i',
              courseTitle: 'Course',
              percentage: 100,
              letter: 'A',
              submittedAt: DateTime.now(),
            )),
            nextCursor: 'next_token',
          ));
        } else if (cursor == 'next_token') {
          return Ok(GradesResponse(
            items: [
              GradeItem(
                kind: GradeKind.assignment,
                refId: 'page2_1',
                title: 'Title 2_1',
                courseTitle: 'Course',
                percentage: 100,
                letter: 'A',
                submittedAt: DateTime.now(),
              )
            ],
            nextCursor: null,
          ));
        }
        return Err(const ServerFailure('Unknown cursor'));
      });

      await tester.pumpWidget(buildApp(repo));
      await tester.pumpAndSettle();
      
      expect(fetchCalls, 1);
      
      // Scroll down
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pump(); // trigger scroll listener
      await tester.pumpAndSettle();
      
      expect(fetchCalls, 2);
      
      // Scroll to bottom again to find it
      scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
      await tester.pump();
      expect(find.text('Title 2_1'), findsWidgets);
    });
  });
}

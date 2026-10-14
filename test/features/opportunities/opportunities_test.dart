import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:stardy_app/Views/Pages/opportunity_page.dart';
import 'package:stardy_app/features/opportunities/models/opportunity_models.dart';
import 'package:stardy_app/features/opportunities/repository/opportunity_repository.dart';
import 'package:stardy_app/core/network/api_client.dart';

class FakeOpportunityRepository extends OpportunityRepository {
  final Future<Result<PaginatedResponse<OpportunitySummary>>> Function({
    String? type,
    String? category,
    String? cursor,
    int limit,
  }) onGetOpportunities;
  
  final Future<Result<OpportunityDetail>> Function(String) onGetOpportunity;
  
  final Future<Result<OpportunityApplyResponse>> Function(
    String id,
    String idempotencyKey, {
    String? coverNote,
  }) onApply;

  FakeOpportunityRepository({
    required this.onGetOpportunities,
    required this.onGetOpportunity,
    required this.onApply,
  });

  @override
  Future<Result<PaginatedResponse<OpportunitySummary>>> getOpportunities({
    String? type,
    String? category,
    String? cursor,
    int limit = 10,
  }) {
    return onGetOpportunities(
      type: type,
      category: category,
      cursor: cursor,
      limit: limit,
    );
  }

  @override
  Future<Result<OpportunityDetail>> getOpportunity(String id) {
    return onGetOpportunity(id);
  }

  @override
  Future<Result<OpportunityApplyResponse>> apply(
    String id,
    String idempotencyKey, {
    String? coverNote,
  }) {
    return onApply(id, idempotencyKey, coverNote: coverNote);
  }
}

void main() {
  Widget buildApp(OpportunityRepository repo) {
    return ProviderScope(
      overrides: [
        opportunityRepositoryProvider.overrideWithValue(repo),
      ],
      child: const MaterialApp(home: OpportunitiesPage()),
    );
  }

  testWidgets('OpportunitiesPage UI: tab and category switching sends the right parameters', (tester) async {
    String? lastType;
    String? lastCategory;

    final repo = FakeOpportunityRepository(
      onGetOpportunities: ({type, category, cursor, limit = 10}) async {
        lastType = type;
        lastCategory = category;
        return Ok(PaginatedResponse([], null));
      },
      onGetOpportunity: (id) async => Err(const ServerFailure('')),
      onApply: (id, key, {coverNote}) async => Err(const ServerFailure('')),
    );

    await tester.pumpWidget(buildApp(repo));
    await tester.pumpAndSettle();

    expect(lastType, 'INTERNSHIP');
    expect(lastCategory, 'TECH');

    await tester.tap(find.text('Projects'));
    await tester.pumpAndSettle();
    expect(lastType, 'FREELANCE');
    expect(lastCategory, 'TECH');

    await tester.tap(find.text('CREATIVE'));
    await tester.pumpAndSettle();
    expect(lastType, 'FREELANCE');
    expect(lastCategory, 'CREATIVE');
  });

  testWidgets('OpportunitiesPage UI: paging', (tester) async {
    int page = 0;
    final repo = FakeOpportunityRepository(
      onGetOpportunities: ({type, category, cursor, limit = 10}) async {
        if (cursor == null) {
          page = 1;
          return Ok(PaginatedResponse([
            const OpportunitySummary(id: '1', title: 'Opp 1', company: 'Co', type: 'INTERNSHIP', category: 'TECH', isPaid: true, hasApplied: false),
            const OpportunitySummary(id: '2', title: 'Opp 2', company: 'Co', type: 'INTERNSHIP', category: 'TECH', isPaid: true, hasApplied: false),
          ], 'cursor1'));
        } else if (cursor == 'cursor1') {
          page = 2;
          return Ok(PaginatedResponse([
            const OpportunitySummary(id: '3', title: 'Opp 3', company: 'Co', type: 'INTERNSHIP', category: 'TECH', isPaid: true, hasApplied: false),
          ], null));
        }
        return Ok(PaginatedResponse([], null));
      },
      onGetOpportunity: (id) async => Err(const ServerFailure('')),
      onApply: (id, key, {coverNote}) async => Err(const ServerFailure('')),
    );

    await tester.pumpWidget(buildApp(repo));
    await tester.pumpAndSettle();

    expect(page, 1);
    expect(find.text('Opp 1'), findsOneWidget);
    await tester.drag(find.byType(ListView), const Offset(0, -500));
    await tester.pump();
    expect(find.text('Opp 2'), findsOneWidget);
    expect(find.text('Opp 3'), findsNothing);

    // Scroll to end
    await tester.drag(find.byType(ListView), const Offset(0, -1000));
    await tester.pump(); // Start loading
    await tester.pumpAndSettle(); // Finish loading

    expect(page, 2);
    expect(find.text('Opp 3'), findsOneWidget);
  });

  testWidgets('OpportunitiesPage UI: apply happy path', (tester) async {
    final repo = FakeOpportunityRepository(
      onGetOpportunities: ({type, category, cursor, limit = 10}) async {
        return Ok(PaginatedResponse([
          const OpportunitySummary(id: '1', title: 'Opp 1', company: 'Co', type: 'INTERNSHIP', category: 'TECH', isPaid: true, hasApplied: false),
        ], null));
      },
      onGetOpportunity: (id) async {
        return Ok(const OpportunityDetail(
          summary: OpportunitySummary(id: '1', title: 'Opp 1', company: 'Co', type: 'INTERNSHIP', category: 'TECH', isPaid: true, hasApplied: false),
          description: 'Desc',
        ));
      },
      onApply: (id, key, {coverNote}) async {
        return Ok(const OpportunityApplyResponse(status: 'SUBMITTED', appliedAt: '2025-01-01'));
      },
    );

    await tester.pumpWidget(buildApp(repo));
    await tester.pumpAndSettle();

    expect(find.text('Apply Now'), findsOneWidget);
    await tester.tap(find.text('Apply Now'));
    await tester.pumpAndSettle(); // Bottom sheet opens and loads details

    expect(find.text('Desc'), findsOneWidget);
    
    // Tap Confirm Apply
    await tester.tap(find.text('Confirm Apply'));
    await tester.pumpAndSettle();

    // Verify it changed to Applied
    expect(find.text('Applied'), findsOneWidget);
    expect(find.text('Apply Now'), findsNothing);
  });

  testWidgets('OpportunitiesPage UI: apply 409 shows Applied', (tester) async {
    final repo = FakeOpportunityRepository(
      onGetOpportunities: ({type, category, cursor, limit = 10}) async {
        return Ok(PaginatedResponse([
          const OpportunitySummary(id: '1', title: 'Opp 1', company: 'Co', type: 'INTERNSHIP', category: 'TECH', isPaid: true, hasApplied: false),
        ], null));
      },
      onGetOpportunity: (id) async {
        return Ok(const OpportunityDetail(
          summary: OpportunitySummary(id: '1', title: 'Opp 1', company: 'Co', type: 'INTERNSHIP', category: 'TECH', isPaid: true, hasApplied: false),
          description: 'Desc',
        ));
      },
      onApply: (id, key, {coverNote}) async {
        return Err(const ConflictFailure('Already applied'));
      },
    );

    await tester.pumpWidget(buildApp(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply Now'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm Apply'));
    await tester.pumpAndSettle();

    // Verify it changed to Applied despite error
    expect(find.text('Applied'), findsOneWidget);
  });

  testWidgets('OpportunitiesPage UI: apply failure leaves button enabled', (tester) async {
    final repo = FakeOpportunityRepository(
      onGetOpportunities: ({type, category, cursor, limit = 10}) async {
        return Ok(PaginatedResponse([
          const OpportunitySummary(id: '1', title: 'Opp 1', company: 'Co', type: 'INTERNSHIP', category: 'TECH', isPaid: true, hasApplied: false),
        ], null));
      },
      onGetOpportunity: (id) async {
        return Ok(const OpportunityDetail(
          summary: OpportunitySummary(id: '1', title: 'Opp 1', company: 'Co', type: 'INTERNSHIP', category: 'TECH', isPaid: true, hasApplied: false),
          description: 'Desc',
        ));
      },
      onApply: (id, key, {coverNote}) async {
        return Err(const ServerFailure('Server exploded'));
      },
    );

    await tester.pumpWidget(buildApp(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply Now'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Confirm Apply'));
    await tester.pumpAndSettle();

    // Should show error and bottom sheet should still be open
    expect(find.text('Server exploded'), findsOneWidget);
    expect(find.text('Confirm Apply'), findsOneWidget); // Button still there
  });

  testWidgets('OpportunitiesPage UI: cover note 1001 chars blocked', (tester) async {
    int applyCalls = 0;
    String? lastCoverNote;
    final repo = FakeOpportunityRepository(
      onGetOpportunities: ({type, category, cursor, limit = 10}) async {
        return Ok(PaginatedResponse([
          const OpportunitySummary(id: '1', title: 'Opp 1', company: 'Co', type: 'INTERNSHIP', category: 'TECH', isPaid: true, hasApplied: false),
        ], null));
      },
      onGetOpportunity: (id) async {
        return Ok(const OpportunityDetail(
          summary: OpportunitySummary(id: '1', title: 'Opp 1', company: 'Co', type: 'INTERNSHIP', category: 'TECH', isPaid: true, hasApplied: false),
          description: 'Desc',
        ));
      },
      onApply: (id, key, {coverNote}) async {
        applyCalls++;
        lastCoverNote = coverNote;
        return Ok(const OpportunityApplyResponse(status: 'SUBMITTED', appliedAt: '2025-01-01'));
      },
    );

    await tester.pumpWidget(buildApp(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Apply Now'));
    await tester.pumpAndSettle();

    // Enter 1001 chars. The TextField has maxLength: 1000, so it will truncate it.
    final longText = 'a' * 1001;
    await tester.enterText(find.byType(TextField).last, longText);
    await tester.pump();

    await tester.tap(find.text('Confirm Apply'));
    await tester.pumpAndSettle();

    expect(applyCalls, 1);
    expect(lastCoverNote?.length, 1000); // The 1001st char was blocked by the UI
  });
}

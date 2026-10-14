import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/features/opportunities/models/opportunity_models.dart';

void main() {
  group('OpportunityModels', () {
    test('OpportunitySummary parses valid JSON', () {
      final json = {
        'id': '123',
        'title': 'Flutter Dev',
        'company': 'TechCorp',
        'location': 'Remote',
        'type': 'INTERNSHIP',
        'category': 'TECH',
        'isPaid': true,
        'logoUrl': 'https://example.com/logo.png',
        'hasApplied': false,
      };

      final summary = OpportunitySummary.fromJson(json);
      expect(summary.id, '123');
      expect(summary.title, 'Flutter Dev');
      expect(summary.company, 'TechCorp');
      expect(summary.location, 'Remote');
      expect(summary.type, 'INTERNSHIP');
      expect(summary.category, 'TECH');
      expect(summary.isPaid, true);
      expect(summary.logoUrl, 'https://example.com/logo.png');
      expect(summary.hasApplied, false);
    });

    test('OpportunitySummary handles missing optional fields and nulls', () {
      final json = {
        'id': '123',
        'title': 'Flutter Dev',
        'company': 'TechCorp',
        'type': 'FREELANCE',
        'category': 'CREATIVE',
      };

      final summary = OpportunitySummary.fromJson(json);
      expect(summary.location, isNull);
      expect(summary.logoUrl, isNull);
      expect(summary.isPaid, false); // Default
      expect(summary.hasApplied, false); // Default
    });

    test('OpportunityDetail parses correctly', () {
      final json = {
        'id': '123',
        'title': 'Flutter Dev',
        'company': 'TechCorp',
        'type': 'INTERNSHIP',
        'category': 'TECH',
        'description': 'Great job',
        'applyUrl': 'https://apply.com',
      };

      final detail = OpportunityDetail.fromJson(json);
      expect(detail.summary.id, '123');
      expect(detail.description, 'Great job');
      expect(detail.applyUrl, 'https://apply.com');
    });

    test('OpportunityDetail handles missing optional fields', () {
      final json = {
        'id': '123',
        'title': 'Flutter Dev',
        'company': 'TechCorp',
        'type': 'INTERNSHIP',
        'category': 'TECH',
      };

      final detail = OpportunityDetail.fromJson(json);
      expect(detail.description, '');
      expect(detail.applyUrl, isNull);
    });

    test('OpportunityApplyResponse parses correctly', () {
      final json = {
        'status': 'SUBMITTED',
        'appliedAt': '2026-01-01T00:00:00Z',
      };

      final res = OpportunityApplyResponse.fromJson(json);
      expect(res.status, 'SUBMITTED');
      expect(res.appliedAt, '2026-01-01T00:00:00Z');
    });
  });
}

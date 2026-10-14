import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/features/gamification/dto/gamification_badge_dto.dart';
import 'package:stardy_app/features/gamification/dto/certificate_dto.dart';

void main() {
  test('GamificationBadgeDto parsing', () {
    final json = {
      "id": "b1",
      "code": "FIRST_LAUNCH",
      "name": "First Launch",
      "description": "Complete first module",
      "iconUrl": "https://example.com/icon",
      "earned": true,
      "earnedAt": "2026-01-01T00:00:00Z"
    };
    final dto = GamificationBadgeDto.fromJson(json);
    expect(dto.id, "b1");
    expect(dto.code, "FIRST_LAUNCH");
    expect(dto.name, "First Launch");
    expect(dto.earned, true);
    expect(dto.iconUrl, "https://example.com/icon");
    expect(dto.earnedAt, DateTime.utc(2026, 1, 1));
  });

  test('CertificateDto parsing', () {
    final json = {
      "id": "c1",
      "courseId": "cs1",
      "courseTitle": "Math",
      "title": "Math 101",
      "certificateUrl": "https://example.com/cert",
      "issuedAt": "2026-01-01T00:00:00Z"
    };
    final dto = CertificateDto.fromJson(json);
    expect(dto.id, "c1");
    expect(dto.courseId, "cs1");
    expect(dto.courseTitle, "Math");
    expect(dto.title, "Math 101");
    expect(dto.certificateUrl, "https://example.com/cert");
    expect(dto.issuedAt, DateTime.utc(2026, 1, 1));
  });
}

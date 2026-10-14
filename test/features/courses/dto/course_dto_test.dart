import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/features/courses/models/course_enums.dart';
import 'package:stardy_app/features/courses/dto/course_dto.dart';

void main() {
  group('Course Enums', () {
    test('unknown enum values fallback safely', () {
      expect(difficultyFromString('XYZ'), Difficulty.unknown);
      expect(difficultyFromString(null), Difficulty.unknown);
      
      expect(categoryFromString('XYZ'), CourseCategory.unknown);
      expect(categoryFromString(null), CourseCategory.unknown);
      
      expect(contentTypeFromString('XYZ'), ContentType.unknown);
      expect(contentTypeFromString(null), ContentType.unknown);
    });
  });

  group('DTO Parsing', () {
    test('CourseSummary', () {
      final json = {
        'id': '123',
        'title': 'Test Course',
        'category': 'TECH',
        'difficulty': 'BEGINNER',
        'thumbnailUrl': 'http://example.com/thumb.png',
        'ratingAvg': 4.5,
        'ratingCount': 100,
        'durationSeconds': 3600,
        'moduleCount': 10,
        'progressPercent': 50
      };

      final dto = CourseSummary.fromJson(json);
      expect(dto.id, '123');
      expect(dto.category, CourseCategory.tech);
      expect(dto.difficulty, Difficulty.beginner);
      expect(dto.thumbnailUrl, 'http://example.com/thumb.png');
      expect(dto.ratingAvg, 4.5);
      expect(dto.ratingCount, 100);
      expect(dto.durationSeconds, 3600);
      expect(dto.moduleCount, 10);
      expect(dto.progressPercent, 50);
    });

    test('CourseDetail with zero modules', () {
      final json = {
        'id': '123',
        'title': 'Empty Course',
        'category': 'CREATIVE',
        'difficulty': 'ADVANCED',
        'ratingAvg': 0,
        'ratingCount': 0, // ratingCount 0
        'moduleCount': 0,
        'description': 'A very empty course',
        'createdAt': '2026-01-01T00:00:00Z',
        'modules': [],
        'assignments': []
      };

      final dto = CourseDetail.fromJson(json);
      expect(dto.modules.length, 0);
      expect(dto.ratingCount, 0);
      expect(dto.description, 'A very empty course');
    });

    test('ModuleItem with null section and duration', () {
      final json = {
        'id': 'm1',
        'title': 'Intro',
        'order': 1,
        'section': null,
        'contentType': 'UNKNOWN_TYPE', // unknown enum value
        'durationSeconds': null,
        'isCompleted': true
      };

      final dto = ModuleItem.fromJson(json);
      expect(dto.section, isNull);
      expect(dto.durationSeconds, isNull);
      expect(dto.contentType, ContentType.unknown);
      expect(dto.isCompleted, true);
    });

    test('AssignmentRef', () {
      final json = {
        'id': 'a1',
        'title': 'Final Project',
        'dueAt': null
      };

      final dto = AssignmentRef.fromJson(json);
      expect(dto.id, 'a1');
      expect(dto.dueAt, isNull);
    });

    test('ResourceItem', () {
      final json = {
        'id': 'r1',
        'title': 'Slides',
        'author': null,
        'type': 'FILE',
        'url': 'http://example.com/file'
      };

      final dto = ResourceItem.fromJson(json);
      expect(dto.id, 'r1');
      expect(dto.type, ResourceType.file);
    });

    test('ModuleContent', () {
      final json = {
        'contentType': 'VIDEO',
        'url': 'http://example.com/video.m3u8',
        'expiresAt': '2026-01-01T00:00:00Z',
        'textContent': null
      };

      final dto = ModuleContent.fromJson(json);
      expect(dto.contentType, ContentType.video);
      expect(dto.url, 'http://example.com/video.m3u8');
      expect(dto.textContent, isNull);
    });
  });
}

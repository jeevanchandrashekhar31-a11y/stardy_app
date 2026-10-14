import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/features/courses/models/course_formatters.dart';
import 'package:stardy_app/features/courses/models/course_enums.dart';

void main() {
  group('formatDuration', () {
    test('null or negative returns 0m', () {
      expect(formatDuration(null), '0m');
      expect(formatDuration(-5), '0m');
    });

    test('less than an hour returns just minutes', () {
      expect(formatDuration(0), '0m');
      expect(formatDuration(59), '0m');
      expect(formatDuration(60), '1m');
      expect(formatDuration(3599), '59m');
    });

    test('more than an hour returns hours and minutes', () {
      expect(formatDuration(3600), '1h 0m');
      expect(formatDuration(3660), '1h 1m');
      expect(formatDuration(7200), '2h 0m');
    });
  });

  group('formatDifficulty', () {
    test('returns correct label', () {
      expect(formatDifficulty(Difficulty.beginner), 'Beginner');
      expect(formatDifficulty(Difficulty.intermediate), 'Intermediate');
      expect(formatDifficulty(Difficulty.advanced), 'Advanced');
      expect(formatDifficulty(Difficulty.unknown), 'Unknown');
    });
  });

  group('formatCategory', () {
    test('returns correct label', () {
      expect(formatCategory(CourseCategory.creative), 'Creative');
      expect(formatCategory(CourseCategory.business), 'Business');
      expect(formatCategory(CourseCategory.tech), 'Tech');
      expect(formatCategory(CourseCategory.unknown), 'Unknown');
    });
  });

  group('formatRating', () {
    test('returns null when ratingCount <= 0', () {
      expect(formatRating(4.5, 0), isNull);
      expect(formatRating(4.5, -1), isNull);
    });

    test('returns formatted string when ratingCount > 0', () {
      expect(formatRating(4.56, 10), '4.6');
      expect(formatRating(4.0, 5), '4.0');
    });
  });
}

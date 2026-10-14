import 'course_enums.dart';

String formatDuration(int? seconds) {
  if (seconds == null || seconds < 0) return '0m';
  final h = seconds ~/ 3600;
  final m = (seconds % 3600) ~/ 60;
  if (h > 0) return '${h}h ${m}m';
  return '${m}m';
}

String formatDifficulty(Difficulty d) {
  switch (d) {
    case Difficulty.beginner: return 'Beginner';
    case Difficulty.intermediate: return 'Intermediate';
    case Difficulty.advanced: return 'Advanced';
    case Difficulty.unknown: return 'Unknown';
  }
}

String formatCategory(CourseCategory c) {
  switch (c) {
    case CourseCategory.creative: return 'Creative';
    case CourseCategory.business: return 'Business';
    case CourseCategory.tech: return 'Tech';
    case CourseCategory.unknown: return 'Unknown';
  }
}

String? formatRating(double rating, int ratingCount) {
  if (ratingCount <= 0) return null;
  return rating.toStringAsFixed(1);
}

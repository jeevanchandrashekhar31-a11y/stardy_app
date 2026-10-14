import '../../courses/dto/course_dto.dart';

class ContinueCourse {
  final String courseId;
  final String title;
  final String? thumbnailUrl;
  final int progressPercent;
  final String? nextModuleId;

  const ContinueCourse({
    required this.courseId,
    required this.title,
    this.thumbnailUrl,
    required this.progressPercent,
    this.nextModuleId,
  });

  factory ContinueCourse.fromJson(Map<String, dynamic> json) {
    return ContinueCourse(
      courseId: json['courseId'] as String,
      title: json['title'] as String,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      progressPercent: json['progressPercent'] as int,
      nextModuleId: json['nextModuleId'] as String?,
    );
  }
}

class CareerPathSummary {
  final String id;
  final String title;
  final int progress;

  const CareerPathSummary({
    required this.id,
    required this.title,
    required this.progress,
  });

  factory CareerPathSummary.fromJson(Map<String, dynamic> json) {
    return CareerPathSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      progress: json['progress'] as int,
    );
  }
}

class HomeData {
  final String greetingName;
  final ContinueCourse? continueCourse;
  final List<CourseSummary> recommended;
  final List<CourseSummary> newCourses;
  final List<CareerPathSummary> careerPaths;

  const HomeData({
    required this.greetingName,
    this.continueCourse,
    required this.recommended,
    required this.newCourses,
    required this.careerPaths,
  });

  factory HomeData.fromJson(Map<String, dynamic> json) {
    return HomeData(
      greetingName: json['greetingName'] as String,
      continueCourse: json['continueCourse'] != null
          ? ContinueCourse.fromJson(json['continueCourse'] as Map<String, dynamic>)
          : null,
      recommended: (json['recommended'] as List<dynamic>?)
              ?.map((e) => CourseSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      newCourses: (json['newCourses'] as List<dynamic>?)
              ?.map((e) => CourseSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      careerPaths: (json['careerPaths'] as List<dynamic>?)
              ?.map((e) => CareerPathSummary.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

import '../models/course_enums.dart';

class CourseSummary {
  final String id;
  final String title;
  final CourseCategory category;
  final Difficulty difficulty;
  final String? thumbnailUrl;
  final double ratingAvg;
  final int ratingCount;
  final int? durationSeconds;
  final int moduleCount;
  final int? progressPercent;

  CourseSummary({
    required this.id,
    required this.title,
    required this.category,
    required this.difficulty,
    this.thumbnailUrl,
    required this.ratingAvg,
    required this.ratingCount,
    this.durationSeconds,
    required this.moduleCount,
    this.progressPercent,
  });

  factory CourseSummary.fromJson(Map<String, dynamic> json) {
    return CourseSummary(
      id: json['id'] as String,
      title: json['title'] as String,
      category: categoryFromString(json['category'] as String?),
      difficulty: difficultyFromString(json['difficulty'] as String?),
      thumbnailUrl: json['thumbnailUrl'] as String?,
      ratingAvg: (json['ratingAvg'] as num).toDouble(),
      ratingCount: json['ratingCount'] as int,
      durationSeconds: json['durationSeconds'] as int?,
      moduleCount: json['moduleCount'] as int,
      progressPercent: json['progressPercent'] as int?,
    );
  }
}

class CourseDetail extends CourseSummary {
  final String description;
  final String createdAt;
  final List<ModuleItem> modules;
  final List<AssignmentRef> assignments;

  CourseDetail({
    required super.id,
    required super.title,
    required super.category,
    required super.difficulty,
    super.thumbnailUrl,
    required super.ratingAvg,
    required super.ratingCount,
    super.durationSeconds,
    required super.moduleCount,
    super.progressPercent,
    required this.description,
    required this.createdAt,
    required this.modules,
    required this.assignments,
  });

  factory CourseDetail.fromJson(Map<String, dynamic> json) {
    final base = CourseSummary.fromJson(json);
    return CourseDetail(
      id: base.id,
      title: base.title,
      category: base.category,
      difficulty: base.difficulty,
      thumbnailUrl: base.thumbnailUrl,
      ratingAvg: base.ratingAvg,
      ratingCount: base.ratingCount,
      durationSeconds: base.durationSeconds,
      moduleCount: base.moduleCount,
      progressPercent: base.progressPercent,
      description: json['description'] as String,
      createdAt: json['createdAt'] as String,
      modules: (json['modules'] as List<dynamic>?)
              ?.map((e) => ModuleItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      assignments: (json['assignments'] as List<dynamic>?)
              ?.map((e) => AssignmentRef.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ModuleItem {
  final String id;
  final String title;
  final int order;
  final String? section;
  final ContentType contentType;
  final int? durationSeconds;
  final bool isCompleted;

  ModuleItem({
    required this.id,
    required this.title,
    required this.order,
    this.section,
    required this.contentType,
    this.durationSeconds,
    required this.isCompleted,
  });

  factory ModuleItem.fromJson(Map<String, dynamic> json) {
    return ModuleItem(
      id: json['id'] as String,
      title: json['title'] as String,
      order: json['order'] as int,
      section: json['section'] as String?,
      contentType: contentTypeFromString(json['contentType'] as String?),
      durationSeconds: json['durationSeconds'] as int?,
      isCompleted: json['isCompleted'] as bool,
    );
  }
}

class AssignmentRef {
  final String id;
  final String title;
  final String? dueAt;

  AssignmentRef({
    required this.id,
    required this.title,
    this.dueAt,
  });

  factory AssignmentRef.fromJson(Map<String, dynamic> json) {
    return AssignmentRef(
      id: json['id'] as String,
      title: json['title'] as String,
      dueAt: json['dueAt'] as String?,
    );
  }
}

class ResourceItem {
  final String id;
  final String title;
  final String? author;
  final ResourceType type;
  final String url;

  ResourceItem({
    required this.id,
    required this.title,
    this.author,
    required this.type,
    required this.url,
  });

  factory ResourceItem.fromJson(Map<String, dynamic> json) {
    return ResourceItem(
      id: json['id'] as String,
      title: json['title'] as String,
      author: json['author'] as String?,
      type: resourceTypeFromString(json['type'] as String?),
      url: json['url'] as String,
    );
  }
}

class ModuleContent {
  final ContentType contentType;
  final String? url;
  final String? expiresAt;
  final String? textContent;

  ModuleContent({
    required this.contentType,
    this.url,
    this.expiresAt,
    this.textContent,
  });

  factory ModuleContent.fromJson(Map<String, dynamic> json) {
    return ModuleContent(
      contentType: contentTypeFromString(json['contentType'] as String?),
      url: json['url'] as String?,
      expiresAt: json['expiresAt'] as String?,
      textContent: json['textContent'] as String?,
    );
  }
}

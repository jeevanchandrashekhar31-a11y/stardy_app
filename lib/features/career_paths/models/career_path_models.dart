class CareerPathCourse {
  final String courseId;
  final String title;
  final String difficulty;
  final String? thumbnailUrl;
  final int order;
  final int? progressPercent;

  const CareerPathCourse({
    required this.courseId,
    required this.title,
    required this.difficulty,
    this.thumbnailUrl,
    required this.order,
    this.progressPercent,
  });

  factory CareerPathCourse.fromJson(Map<String, dynamic> json) {
    return CareerPathCourse(
      courseId: json['courseId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      difficulty: json['difficulty'] as String? ?? 'BEGINNER',
      thumbnailUrl: json['thumbnailUrl'] as String?,
      order: json['order'] as int? ?? 0,
      progressPercent: json['progressPercent'] as int?,
    );
  }
}

class CareerPathDetail {
  final String id;
  final String title;
  final String description;
  final List<String> skills;
  final bool enrolled;
  final int progress;
  final List<CareerPathCourse> courses;

  const CareerPathDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.skills,
    required this.enrolled,
    required this.progress,
    required this.courses,
  });

  factory CareerPathDetail.fromJson(Map<String, dynamic> json) {
    return CareerPathDetail(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      skills: (json['skills'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      enrolled: json['enrolled'] as bool? ?? false,
      progress: json['progress'] as int? ?? 0,
      courses: (json['courses'] as List<dynamic>?)
              ?.map((e) => CareerPathCourse.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
    );
  }
}

class ProjectSubmissionDetail {
  final String status;
  final String? linkUrl;
  final String? fileName;
  final DateTime? submittedAt;

  const ProjectSubmissionDetail({
    required this.status,
    this.linkUrl,
    this.fileName,
    this.submittedAt,
  });

  factory ProjectSubmissionDetail.fromJson(Map<String, dynamic> json) {
    return ProjectSubmissionDetail(
      status: json['status'] as String? ?? 'PENDING_REVIEW',
      linkUrl: json['linkUrl'] as String?,
      fileName: json['fileName'] as String?,
      submittedAt: json['submittedAt'] != null 
          ? DateTime.tryParse(json['submittedAt'] as String) 
          : null,
    );
  }
}

class ProjectDetail {
  final String id;
  final String title;
  final String description;
  final List<String> requirements;
  final List<String> deliverables;
  final List<String> stretchGoals;
  final ProjectSubmissionDetail? submission;

  const ProjectDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.requirements,
    required this.deliverables,
    required this.stretchGoals,
    this.submission,
  });

  factory ProjectDetail.fromJson(Map<String, dynamic> json) {
    return ProjectDetail(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      requirements: (json['requirements'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      deliverables: (json['deliverables'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      stretchGoals: (json['stretchGoals'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      submission: json['submission'] != null 
          ? ProjectSubmissionDetail.fromJson(json['submission'] as Map<String, dynamic>) 
          : null,
    );
  }
}

class CareerPathProjectResponse {
  final bool eligible;
  final int progress;
  final ProjectDetail? project;

  const CareerPathProjectResponse({
    required this.eligible,
    required this.progress,
    this.project,
  });

  factory CareerPathProjectResponse.fromJson(Map<String, dynamic> json) {
    return CareerPathProjectResponse(
      eligible: json['eligible'] as bool? ?? false,
      progress: json['progress'] as int? ?? 0,
      project: json['project'] != null 
          ? ProjectDetail.fromJson(json['project'] as Map<String, dynamic>) 
          : null,
    );
  }
}

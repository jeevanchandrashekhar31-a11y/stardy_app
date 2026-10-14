class AssignmentFileSubmission {
  final String status;
  final String? fileName;
  final String? submittedAt;
  final String? feedback;

  AssignmentFileSubmission({
    required this.status,
    this.fileName,
    this.submittedAt,
    this.feedback,
  });

  factory AssignmentFileSubmission.fromJson(Map<String, dynamic> json) {
    return AssignmentFileSubmission(
      status: json['status'] as String? ?? 'NOT_SUBMITTED',
      fileName: json['fileName'] as String?,
      submittedAt: json['submittedAt'] as String?,
      feedback: json['feedback'] as String?,
    );
  }
}

class AssignmentQuizSubmission {
  final int score;
  final String? submittedAt;
  final bool remedialEligible;

  AssignmentQuizSubmission({
    required this.score,
    this.submittedAt,
    required this.remedialEligible,
  });

  factory AssignmentQuizSubmission.fromJson(Map<String, dynamic> json) {
    return AssignmentQuizSubmission(
      score: (json['score'] as num?)?.toInt() ?? 0,
      submittedAt: json['submittedAt'] as String?,
      remedialEligible: json['remedialEligible'] as bool? ?? false,
    );
  }
}

class AssignmentDetails {
  final String id;
  final String courseId;
  final String title;
  final String? instructions;
  final List<String> topics;
  final String? dueAt;
  final AssignmentFileSubmission? fileSubmission;
  final AssignmentQuizSubmission? quizSubmission;

  AssignmentDetails({
    required this.id,
    required this.courseId,
    required this.title,
    this.instructions,
    required this.topics,
    this.dueAt,
    this.fileSubmission,
    this.quizSubmission,
  });

  factory AssignmentDetails.fromJson(Map<String, dynamic> json) {
    return AssignmentDetails(
      id: json['id'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      instructions: json['instructions'] as String?,
      topics: (json['topics'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      dueAt: json['dueAt'] as String?,
      fileSubmission: json['fileSubmission'] != null 
          ? AssignmentFileSubmission.fromJson(json['fileSubmission'] as Map<String, dynamic>)
          : null,
      quizSubmission: json['quizSubmission'] != null
          ? AssignmentQuizSubmission.fromJson(json['quizSubmission'] as Map<String, dynamic>)
          : null,
    );
  }
}

class AssignmentFileSubmissionResponse {
  final String status;
  final String? submittedAt;

  AssignmentFileSubmissionResponse({
    required this.status,
    this.submittedAt,
  });

  factory AssignmentFileSubmissionResponse.fromJson(Map<String, dynamic> json) {
    return AssignmentFileSubmissionResponse(
      status: json['status'] as String? ?? 'PENDING_REVIEW',
      submittedAt: json['submittedAt'] as String?,
    );
  }
}

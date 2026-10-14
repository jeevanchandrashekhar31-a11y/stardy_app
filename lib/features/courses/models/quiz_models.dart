import '../../../core/models/gamification_result.dart';

sealed class QuizTarget {
  final String title;
  const QuizTarget(this.title);
}

class ModuleQuiz extends QuizTarget {
  final String moduleId;
  const ModuleQuiz(this.moduleId, String title) : super(title);
}

class AssignmentQuiz extends QuizTarget {
  final String assignmentId;
  const AssignmentQuiz(this.assignmentId, String title) : super(title);
}

class QuizQuestion {
  final String id;
  final String question;
  final List<String> options;

  QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
  });

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    return QuizQuestion(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
    );
  }
}

class QuizAttemptStartResponse {
  final String? attemptId;
  final String? startedAt;
  final List<QuizQuestion> questions;

  QuizAttemptStartResponse({
    this.attemptId,
    this.startedAt,
    required this.questions,
  });

  factory QuizAttemptStartResponse.fromJson(Map<String, dynamic> json) {
    final qs = json['questions'] as List<dynamic>? ?? [];
    return QuizAttemptStartResponse(
      attemptId: json['attemptId'] as String?,
      startedAt: json['startedAt'] as String?,
      questions: qs.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class QuizOutcome {
  final int score;
  final bool passed;
  final int correctCount;
  final int totalCount;
  final bool remedialEligible;
  final String? submissionId;
  final GamificationResult? gamification;

  QuizOutcome({
    required this.score,
    required this.passed,
    required this.correctCount,
    required this.totalCount,
    required this.remedialEligible,
    this.submissionId,
    this.gamification,
  });

  factory QuizOutcome.fromJson(Map<String, dynamic> json) {
    return QuizOutcome(
      score: (json['score'] as num?)?.toInt() ?? 0,
      passed: json['passed'] as bool? ?? false,
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      totalCount: (json['totalCount'] as num?)?.toInt() ?? 0,
      remedialEligible: json['remedialEligible'] as bool? ?? false,
      submissionId: json['submissionId'] as String?,
      gamification: json['gamification'] != null
          ? GamificationResult.fromJson(json['gamification'] as Map<String, dynamic>)
          : null,
    );
  }
}

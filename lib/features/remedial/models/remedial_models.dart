class RemedialQuestion {
  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String? explanation;

  RemedialQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    this.explanation,
  });

  factory RemedialQuestion.fromJson(Map<String, dynamic> json) {
    return RemedialQuestion(
      id: json['id'] as String? ?? '',
      question: json['question'] as String? ?? '',
      options: (json['options'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      correctIndex: (json['correctIndex'] as num?)?.toInt() ?? 0,
      explanation: json['explanation'] as String?,
    );
  }
}

class RemedialQuiz {
  final String remedialQuizId;
  final String status;
  final List<String> weakConcepts;
  final List<RemedialQuestion> questions;

  RemedialQuiz({
    required this.remedialQuizId,
    required this.status,
    required this.weakConcepts,
    required this.questions,
  });

  factory RemedialQuiz.fromJson(Map<String, dynamic> json) {
    final qs = json['questions'] as List<dynamic>? ?? [];
    return RemedialQuiz(
      remedialQuizId: json['remedialQuizId'] as String? ?? '',
      status: json['status'] as String? ?? '',
      weakConcepts: (json['weakConcepts'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      questions: qs.map((e) => RemedialQuestion.fromJson(e as Map<String, dynamic>)).toList(),
    );
  }
}

class RemedialResult {
  final int score;
  final String status;

  RemedialResult({
    required this.score,
    required this.status,
  });

  factory RemedialResult.fromJson(Map<String, dynamic> json) {
    return RemedialResult(
      score: (json['score'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? '',
    );
  }
}

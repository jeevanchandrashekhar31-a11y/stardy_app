enum GradeKind {
  assignment,
  quiz,
  unknown,
}

class GradeItem {
  final GradeKind kind;
  final String refId;
  final String title;
  final String courseTitle;
  final int percentage;
  final String? letter;
  final DateTime submittedAt;

  const GradeItem({
    required this.kind,
    required this.refId,
    required this.title,
    required this.courseTitle,
    required this.percentage,
    required this.letter,
    required this.submittedAt,
  });

  factory GradeItem.fromJson(Map<String, dynamic> json) {
    return GradeItem(
      kind: _parseKind(json['kind'] as String?),
      refId: json['refId'] as String? ?? '',
      title: json['title'] as String? ?? 'Unknown',
      courseTitle: json['courseTitle'] as String? ?? 'Unknown Course',
      percentage: json['percentage'] as int? ?? 0,
      letter: json['letter'] as String?,
      submittedAt: json['submittedAt'] != null 
          ? DateTime.parse(json['submittedAt'] as String) 
          : DateTime.now(),
    );
  }

  static GradeKind _parseKind(String? kind) {
    if (kind == 'ASSIGNMENT') return GradeKind.assignment;
    if (kind == 'QUIZ') return GradeKind.quiz;
    return GradeKind.unknown;
  }
}

import '../models/grade_models.dart';

class GradesResponse {
  final List<GradeItem> items;
  final String? nextCursor;

  const GradesResponse({
    required this.items,
    this.nextCursor,
  });

  factory GradesResponse.fromJson(Map<String, dynamic> json) {
    return GradesResponse(
      items: (json['items'] as List<dynamic>?)
              ?.map((e) => GradeItem.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      nextCursor: json['nextCursor'] as String?,
    );
  }
}

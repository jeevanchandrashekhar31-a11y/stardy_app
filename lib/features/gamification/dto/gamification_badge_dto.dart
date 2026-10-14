class GamificationBadgeDto {
  final String id;
  final String code;
  final String name;
  final String description;
  final String? iconUrl;
  final bool earned;
  final DateTime? earnedAt;

  GamificationBadgeDto({
    required this.id,
    required this.code,
    required this.name,
    required this.description,
    this.iconUrl,
    required this.earned,
    this.earnedAt,
  });

  factory GamificationBadgeDto.fromJson(Map<String, dynamic> json) {
    return GamificationBadgeDto(
      id: json['id'] as String,
      code: json['code'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      iconUrl: json['iconUrl'] as String?,
      earned: json['earned'] as bool,
      earnedAt: json['earnedAt'] != null ? DateTime.parse(json['earnedAt'] as String) : null,
    );
  }
}

class GamificationMeDto {
  final int xp;
  final int level;
  final int xpIntoLevel;
  final int xpForNextLevel;
  final int currentStreak;
  final int longestStreak;
  final DateTime? lastActiveAt;
  final bool activeToday;

  const GamificationMeDto({
    required this.xp,
    required this.level,
    required this.xpIntoLevel,
    required this.xpForNextLevel,
    required this.currentStreak,
    required this.longestStreak,
    this.lastActiveAt,
    required this.activeToday,
  });

  factory GamificationMeDto.fromJson(Map<String, dynamic> json) {
    return GamificationMeDto(
      xp: json['xp'] as int,
      level: json['level'] as int,
      xpIntoLevel: json['xpIntoLevel'] as int,
      xpForNextLevel: json['xpForNextLevel'] as int,
      currentStreak: json['currentStreak'] as int,
      longestStreak: json['longestStreak'] as int,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.parse(json['lastActiveAt'] as String)
          : null,
      activeToday: json['activeToday'] as bool,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'xp': xp,
      'level': level,
      'xpIntoLevel': xpIntoLevel,
      'xpForNextLevel': xpForNextLevel,
      'currentStreak': currentStreak,
      'longestStreak': longestStreak,
      if (lastActiveAt != null) 'lastActiveAt': lastActiveAt!.toIso8601String(),
      'activeToday': activeToday,
    };
  }
}

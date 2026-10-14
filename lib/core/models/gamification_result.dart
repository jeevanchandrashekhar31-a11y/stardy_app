class BadgeUnlock {
  final String code;
  final String name;
  final String? iconUrl;

  const BadgeUnlock({required this.code, required this.name, this.iconUrl});

  factory BadgeUnlock.fromJson(Map<String, dynamic> json) {
    if (json['code'] is! String) {
      throw const FormatException('BadgeUnlock.code must be a string');
    }
    if (json['name'] is! String) {
      throw const FormatException('BadgeUnlock.name must be a string');
    }

    String? icon;
    if (json.containsKey('iconUrl') && json['iconUrl'] != null) {
      if (json['iconUrl'] is! String) {
        throw const FormatException('BadgeUnlock.iconUrl must be a string');
      }
      icon = json['iconUrl'] as String;
    }

    return BadgeUnlock(
      code: json['code'] as String,
      name: json['name'] as String,
      iconUrl: icon,
    );
  }
}

class GamificationResult {
  final int xpAwarded;
  final int xp;
  final int level;
  final bool leveledUp;
  final int? newLevel;
  final List<BadgeUnlock> badgesUnlocked;

  const GamificationResult({
    required this.xpAwarded,
    required this.xp,
    required this.level,
    required this.leveledUp,
    this.newLevel,
    required this.badgesUnlocked,
  });

  factory GamificationResult.fromJson(Map<String, dynamic> json) {
    if (json['xpAwarded'] is! int) {
      throw const FormatException('xpAwarded must be an int');
    }
    if (json['xp'] is! int) throw const FormatException('xp must be an int');
    if (json['level'] is! int) {
      throw const FormatException('level must be an int');
    }
    if (json['leveledUp'] is! bool) {
      throw const FormatException('leveledUp must be a bool');
    }

    int? nLevel;
    if (json.containsKey('newLevel') && json['newLevel'] != null) {
      if (json['newLevel'] is! int) {
        throw const FormatException('newLevel must be an int');
      }
      nLevel = json['newLevel'] as int;
    }

    final badges = <BadgeUnlock>[];
    if (json['badgesUnlocked'] is List) {
      for (var b in json['badgesUnlocked'] as List) {
        if (b is Map<String, dynamic>) {
          badges.add(BadgeUnlock.fromJson(b));
        } else {
          throw const FormatException('BadgeUnlock item must be an object');
        }
      }
    } else {
      throw const FormatException('badgesUnlocked must be a list');
    }

    return GamificationResult(
      xpAwarded: json['xpAwarded'] as int,
      xp: json['xp'] as int,
      level: json['level'] as int,
      leveledUp: json['leveledUp'] as bool,
      newLevel: nLevel,
      badgesUnlocked: badges,
    );
  }
}

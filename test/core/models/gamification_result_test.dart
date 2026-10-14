import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/core/models/gamification_result.dart';

void main() {
  group('GamificationResult model', () {
    test('valid payload parses correctly', () {
      final json = {
        'xpAwarded': 100,
        'xp': 1000,
        'level': 2,
        'leveledUp': true,
        'newLevel': 3,
        'badgesUnlocked': [
          {
            'code': 'TEST',
            'name': 'Test Badge',
            'iconUrl': 'http://test.com/icon.png',
          },
        ],
      };
      final result = GamificationResult.fromJson(json);
      expect(result.xpAwarded, 100);
      expect(result.xp, 1000);
      expect(result.level, 2);
      expect(result.leveledUp, true);
      expect(result.newLevel, 3);
      expect(result.badgesUnlocked.length, 1);
      expect(result.badgesUnlocked[0].code, 'TEST');
    });

    test('unknown fields ignored', () {
      final json = {
        'xpAwarded': 100,
        'xp': 1000,
        'level': 2,
        'leveledUp': false,
        'badgesUnlocked': [],
        'unknownField': 'ignored',
      };
      final result = GamificationResult.fromJson(json);
      expect(result.xpAwarded, 100);
      // It parsed successfully without crash
    });

    test('missing optional fields (newLevel, iconUrl)', () {
      final json = {
        'xpAwarded': 100,
        'xp': 1000,
        'level': 2,
        'leveledUp': false,
        'badgesUnlocked': [
          {'code': 'TEST', 'name': 'Test Badge'},
        ],
      };
      final result = GamificationResult.fromJson(json);
      expect(result.newLevel, isNull);
      expect(result.badgesUnlocked[0].iconUrl, isNull);
    });

    test('wrong types throw FormatException', () {
      final json = {
        'xpAwarded': '100', // string instead of int
        'xp': 1000,
        'level': 2,
        'leveledUp': false,
        'badgesUnlocked': [],
      };
      expect(() => GamificationResult.fromJson(json), throwsFormatException);
    });

    test('badgesUnlocked not a list throws', () {
      final json = {
        'xpAwarded': 100,
        'xp': 1000,
        'level': 2,
        'leveledUp': false,
        'badgesUnlocked': 'not a list',
      };
      expect(() => GamificationResult.fromJson(json), throwsFormatException);
    });
  });
}

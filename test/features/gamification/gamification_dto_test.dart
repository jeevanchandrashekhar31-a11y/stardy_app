import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/features/gamification/dto/gamification_me_dto.dart';

void main() {
  test('GamificationMeDto parses from existing user fixture', () {
    final file = File('test/fixtures/contract/gamification_me.json');
    final jsonStr = file.readAsStringSync();
    final json = jsonDecode(jsonStr);
    
    final dto = GamificationMeDto.fromJson(json['data']);
    
    expect(dto.xp, 1899);
    expect(dto.level, 12);
    expect(dto.currentStreak, 4);
    expect(dto.activeToday, true);
    expect(dto.lastActiveAt, isNotNull);
  });

  test('GamificationMeDto parses from new user fixture', () {
    final file = File('test/fixtures/contract/gamification_me_new.json');
    final jsonStr = file.readAsStringSync();
    final json = jsonDecode(jsonStr);
    
    final dto = GamificationMeDto.fromJson(json['data']);
    
    expect(dto.xp, 0);
    expect(dto.level, 1);
    expect(dto.currentStreak, 0);
    expect(dto.activeToday, false);
    expect(dto.lastActiveAt, isNull);
  });
}

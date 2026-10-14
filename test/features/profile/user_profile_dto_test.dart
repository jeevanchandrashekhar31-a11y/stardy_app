import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/features/profile/dto/user_profile_dto.dart';

void main() {
  test('UserProfileDto parses from valid fixture', () {
    final file = File('test/fixtures/contract/users_me.json');
    final jsonStr = file.readAsStringSync();
    final json = jsonDecode(jsonStr);
    
    final dto = UserProfileDto.fromJson(json['data']);
    
    expect(dto.id, 'user_123');
    expect(dto.name, 'Sai');
    expect(dto.username, '@sai_12');
    expect(dto.email, 'sai@example.com');
    expect(dto.profilePictureUrl, isNull);
    expect(dto.careerPaths.length, 1);
    expect(dto.careerPaths.first.title, 'UI UX Design');
  });
}

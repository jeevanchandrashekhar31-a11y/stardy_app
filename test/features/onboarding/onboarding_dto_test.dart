import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/features/onboarding/onboarding_dto.dart';
import 'package:stardy_app/features/onboarding/onboarding_form.dart';

void main() {
  group('OnboardingRequestDto', () {
    test('output equals the contract fixture exactly', () {
      const state = OnboardingFormState(
        careerGoal: 'Become a senior mobile developer',
        purpose: OnboardingPurpose.growCareer,
        howHeard: OnboardingHowHeard.influencer,
        influencerName: 'Tech Guru',
        referralCodeUsed: 'TECH-123_45',
        expectation: 'I expect to learn advanced Flutter architectures and state management.',
        hasUsedSimilarApps: true,
        similarAppsExperience: 'Used some other platforms but they lacked practical projects.',
      );

      final dto = OnboardingRequestDto.fromForm(state);
      final jsonOutput = dto.toJson();

      final fixtureFile = File('test/fixtures/contract/onboarding_request.json');
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync());

      expect(jsonOutput, equals(fixtureJson));
    });

    test('unrelated fields omitted', () {
      const state = OnboardingFormState(
        careerGoal: 'Learn fast',
        purpose: OnboardingPurpose.learnSkills,
        howHeard: OnboardingHowHeard.socialMedia,
        expectation: 'Just want to learn.',
        hasUsedSimilarApps: false,
      );

      final dto = OnboardingRequestDto.fromForm(state);
      final jsonOutput = dto.toJson();

      expect(jsonOutput.containsKey('influencerName'), isFalse);
      expect(jsonOutput.containsKey('referralCodeUsed'), isFalse);
      expect(jsonOutput.containsKey('similarAppsExperience'), isFalse);
    });
  });
}

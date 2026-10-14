import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/features/onboarding/onboarding_form.dart';

void main() {
  group('OnboardingFormState boundary tests', () {
    test('careerGoal boundaries', () {
      // 1 char
      var state = const OnboardingFormState(careerGoal: 'A');
      expect(state.validateCareerGoal(), isNotNull);
      
      // 2 chars
      state = const OnboardingFormState(careerGoal: 'AB');
      expect(state.validateCareerGoal(), isNull);

      // 100 chars
      state = OnboardingFormState(careerGoal: 'A' * 100);
      expect(state.validateCareerGoal(), isNull);

      // 101 chars
      state = OnboardingFormState(careerGoal: 'A' * 101);
      expect(state.validateCareerGoal(), isNotNull);
    });

    test('expectation boundaries', () {
      // 9 chars
      var state = const OnboardingFormState(expectation: '123456789');
      expect(state.validateExpectation(), isNotNull);
      
      // 10 chars
      state = const OnboardingFormState(expectation: '1234567890');
      expect(state.validateExpectation(), isNull);

      // 500 chars
      state = OnboardingFormState(expectation: 'A' * 500);
      expect(state.validateExpectation(), isNull);

      // 501 chars
      state = OnboardingFormState(expectation: 'A' * 501);
      expect(state.validateExpectation(), isNotNull);
    });

    test('influencer name required iff INFLUENCER', () {
      // Not INFLUENCER, name given -> rejected
      var state = const OnboardingFormState(
        howHeard: OnboardingHowHeard.socialMedia,
        influencerName: 'Bob',
      );
      expect(state.validateInfluencerName(), isNotNull);

      // INFLUENCER, no name -> rejected
      state = const OnboardingFormState(
        howHeard: OnboardingHowHeard.influencer,
        influencerName: ' ', // trimmed to empty
      );
      expect(state.validateInfluencerName(), isNotNull);

      // INFLUENCER, name given -> valid
      state = const OnboardingFormState(
        howHeard: OnboardingHowHeard.influencer,
        influencerName: 'Bob',
      );
      expect(state.validateInfluencerName(), isNull);
    });

    test('referral code charset', () {
      // Valid charset: letters digits dash underscore
      var state = const OnboardingFormState(
        howHeard: OnboardingHowHeard.influencer,
        referralCodeUsed: 'abc-123_DEF',
      );
      expect(state.validateReferralCode(), isNull);

      // Invalid charset
      state = const OnboardingFormState(
        howHeard: OnboardingHowHeard.influencer,
        referralCodeUsed: 'abc 123',
      );
      expect(state.validateReferralCode(), isNotNull);
    });

    test('experience text rejected when hasUsedSimilarApps is false', () {
      // False, but has text -> rejected
      var state = const OnboardingFormState(
        hasUsedSimilarApps: false,
        similarAppsExperience: 'I used an app.',
      );
      expect(state.validateSimilarAppsExperience(), isNotNull);

      // True, has text -> valid
      state = const OnboardingFormState(
        hasUsedSimilarApps: true,
        similarAppsExperience: 'I used an app.',
      );
      expect(state.validateSimilarAppsExperience(), isNull);
    });
  });
}

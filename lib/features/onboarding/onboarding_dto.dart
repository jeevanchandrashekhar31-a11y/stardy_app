import 'onboarding_form.dart';

class OnboardingRequestDto {
  final String careerGoal;
  final String purpose;
  final String howHeard;
  final String? influencerName;
  final String? referralCodeUsed;
  final String expectation;
  final bool hasUsedSimilarApps;
  final String? similarAppsExperience;

  OnboardingRequestDto({
    required this.careerGoal,
    required this.purpose,
    required this.howHeard,
    this.influencerName,
    this.referralCodeUsed,
    required this.expectation,
    required this.hasUsedSimilarApps,
    this.similarAppsExperience,
  });

  factory OnboardingRequestDto.fromForm(OnboardingFormState state) {
    if (!state.isValid) throw Exception('Form is invalid');

    return OnboardingRequestDto(
      careerGoal: state.normalizedCareerGoal,
      purpose: state.purpose!.value,
      howHeard: state.howHeard!.value,
      influencerName: state.howHeard == OnboardingHowHeard.influencer 
          ? state.normalizedInfluencerName 
          : null,
      referralCodeUsed: (state.howHeard == OnboardingHowHeard.influencer && state.normalizedReferralCodeUsed.isNotEmpty)
          ? state.normalizedReferralCodeUsed 
          : null,
      expectation: state.normalizedExpectation,
      hasUsedSimilarApps: state.hasUsedSimilarApps,
      similarAppsExperience: (state.hasUsedSimilarApps && state.normalizedSimilarAppsExperience.isNotEmpty)
          ? state.normalizedSimilarAppsExperience
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    final map = <String, dynamic>{
      'careerGoal': careerGoal,
      'purpose': purpose,
      'howHeard': howHeard,
      'expectation': expectation,
      'hasUsedSimilarApps': hasUsedSimilarApps,
    };
    if (influencerName != null) {
      map['influencerName'] = influencerName;
    }
    if (referralCodeUsed != null) {
      map['referralCodeUsed'] = referralCodeUsed;
    }
    if (similarAppsExperience != null) {
      map['similarAppsExperience'] = similarAppsExperience;
    }
    return map;
  }
}

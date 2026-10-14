import 'package:equatable/equatable.dart';

enum OnboardingPurpose {
  learnSkills('Learn Skills', 'LEARN_SKILLS'),
  levelUp('Level Up', 'LEVEL_UP'),
  growCareer('Grow Career', 'GROW_CAREER'),
  freelancing('Freelancing', 'FREELANCING'),
  internship('Internship', 'INTERNSHIP');

  final String label;
  final String value;
  const OnboardingPurpose(this.label, this.value);
}

enum OnboardingHowHeard {
  socialMedia('Social Media', 'SOCIAL_MEDIA'),
  google('Google', 'GOOGLE'),
  influencer('Influencer', 'INFLUENCER'),
  school('School', 'SCHOOL');

  final String label;
  final String value;
  const OnboardingHowHeard(this.label, this.value);
}

class OnboardingFormState extends Equatable {
  final String careerGoal;
  final OnboardingPurpose? purpose;
  final OnboardingHowHeard? howHeard;
  final String influencerName;
  final String referralCodeUsed;
  final String expectation;
  final bool hasUsedSimilarApps;
  final String similarAppsExperience;

  const OnboardingFormState({
    this.careerGoal = '',
    this.purpose,
    this.howHeard,
    this.influencerName = '',
    this.referralCodeUsed = '',
    this.expectation = '',
    this.hasUsedSimilarApps = false,
    this.similarAppsExperience = '',
  });

  OnboardingFormState copyWith({
    String? careerGoal,
    OnboardingPurpose? purpose,
    OnboardingHowHeard? howHeard,
    String? influencerName,
    String? referralCodeUsed,
    String? expectation,
    bool? hasUsedSimilarApps,
    String? similarAppsExperience,
  }) {
    return OnboardingFormState(
      careerGoal: careerGoal ?? this.careerGoal,
      purpose: purpose ?? this.purpose,
      howHeard: howHeard ?? this.howHeard,
      influencerName: influencerName ?? this.influencerName,
      referralCodeUsed: referralCodeUsed ?? this.referralCodeUsed,
      expectation: expectation ?? this.expectation,
      hasUsedSimilarApps: hasUsedSimilarApps ?? this.hasUsedSimilarApps,
      similarAppsExperience: similarAppsExperience ?? this.similarAppsExperience,
    );
  }

  @override
  List<Object?> get props => [
        careerGoal,
        purpose,
        howHeard,
        influencerName,
        referralCodeUsed,
        expectation,
        hasUsedSimilarApps,
        similarAppsExperience,
      ];
      
  String _normalize(String input) {
    // trim, collapse repeated whitespace, strip control characters
    return input
        .replaceAll(RegExp(r'[\x00-\x1F\x7F-\x9F]'), '') // strip control chars
        .replaceAll(RegExp(r'\s+'), ' ') // collapse whitespace
        .trim();
  }

  String get normalizedCareerGoal => _normalize(careerGoal);
  String get normalizedInfluencerName => _normalize(influencerName);
  String get normalizedReferralCodeUsed => _normalize(referralCodeUsed);
  String get normalizedExpectation => _normalize(expectation);
  String get normalizedSimilarAppsExperience => _normalize(similarAppsExperience);

  String? validateCareerGoal() {
    final val = normalizedCareerGoal;
    if (val.length < 2 || val.length > 100) return 'Career goal must be between 2 and 100 characters';
    return null;
  }

  String? validatePurpose() {
    if (purpose == null) return 'Please select a purpose';
    return null;
  }

  String? validateHowHeard() {
    if (howHeard == null) return 'Please select how you heard about us';
    return null;
  }

  String? validateInfluencerName() {
    final val = normalizedInfluencerName;
    if (howHeard == OnboardingHowHeard.influencer) {
      if (val.isEmpty) return 'Influencer name is required';
      if (val.length > 80) return 'Influencer name cannot exceed 80 characters';
    } else {
      if (val.isNotEmpty) return 'Influencer name should be empty if you did not hear from an influencer';
    }
    return null;
  }

  String? validateReferralCode() {
    final val = normalizedReferralCodeUsed;
    if (howHeard == OnboardingHowHeard.influencer) {
      if (val.isNotEmpty) {
        if (val.length > 32) return 'Referral code cannot exceed 32 characters';
        if (!RegExp(r'^[a-zA-Z0-9\-_]+$').hasMatch(val)) {
          return 'Referral code can only contain letters, numbers, hyphens, and underscores';
        }
      }
    } else {
      if (val.isNotEmpty) return 'Referral code should be empty if you did not hear from an influencer';
    }
    return null;
  }

  String? validateExpectation() {
    final val = normalizedExpectation;
    if (val.length < 10 || val.length > 500) return 'Expectation must be between 10 and 500 characters';
    return null;
  }

  String? validateSimilarAppsExperience() {
    final val = normalizedSimilarAppsExperience;
    if (hasUsedSimilarApps) {
      if (val.length > 500) return 'Experience cannot exceed 500 characters';
    } else {
      if (val.isNotEmpty) return 'Experience should be empty if you have not used similar apps';
    }
    return null;
  }

  bool get isValid =>
      validateCareerGoal() == null &&
      validatePurpose() == null &&
      validateHowHeard() == null &&
      validateInfluencerName() == null &&
      validateReferralCode() == null &&
      validateExpectation() == null &&
      validateSimilarAppsExperience() == null;
}

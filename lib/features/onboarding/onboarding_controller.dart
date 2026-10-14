import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../core/network/api_client.dart';
import 'onboarding_form.dart';
import 'onboarding_repository.dart';

final onboardingFormProvider = NotifierProvider<OnboardingFormNotifier, OnboardingFormState>(() {
  return OnboardingFormNotifier();
});

class OnboardingFormNotifier extends Notifier<OnboardingFormState> {
  @override
  OnboardingFormState build() {
    return const OnboardingFormState();
  }

  void updateCareerGoal(String value) {
    state = state.copyWith(careerGoal: value);
  }

  void updatePurpose(OnboardingPurpose? purpose) {
    state = state.copyWith(purpose: purpose);
  }

  void updateHowHeard(OnboardingHowHeard? howHeard) {
    state = state.copyWith(howHeard: howHeard);
  }

  void updateInfluencerName(String value) {
    state = state.copyWith(influencerName: value);
  }

  void updateReferralCode(String value) {
    state = state.copyWith(referralCodeUsed: value);
  }

  void updateExpectation(String value) {
    state = state.copyWith(expectation: value);
  }

  void updateHasUsedSimilarApps(bool value) {
    state = state.copyWith(hasUsedSimilarApps: value);
  }

  void updateSimilarAppsExperience(String value) {
    state = state.copyWith(similarAppsExperience: value);
  }
}

final onboardingSubmitProvider = StateNotifierProvider.autoDispose<OnboardingSubmitController, AsyncValue<void>>((ref) {
  return OnboardingSubmitController(ref.watch(onboardingRepositoryProvider));
});

class OnboardingSubmitController extends StateNotifier<AsyncValue<void>> {
  final OnboardingRepository _repository;
  String? _idempotencyKey;
  OnboardingFormState? _lastSubmittedFormState;

  OnboardingSubmitController(this._repository) : super(const AsyncData(null));

  Future<bool> submit(OnboardingFormState formState) async {
    if (state is AsyncLoading) return false;

    if (_lastSubmittedFormState != formState || _idempotencyKey == null) {
      _idempotencyKey = const Uuid().v4();
      _lastSubmittedFormState = formState;
    }

    state = const AsyncLoading();

    final result = await _repository.submitOnboarding(
      formState,
      idempotencyKey: _idempotencyKey!,
    );

    if (result is Ok) {
      state = const AsyncData(null);
      return true;
    } else {
      final error = (result as Err).error;
      state = AsyncError(error, StackTrace.current);
      return false;
    }
  }
}

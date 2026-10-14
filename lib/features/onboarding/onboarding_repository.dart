import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/network/api_client.dart';
import '../../core/logging/app_logger.dart';
import 'onboarding_dto.dart';
import 'onboarding_form.dart';

final onboardingRepositoryProvider = Provider<OnboardingRepository>((ref) {
  return OnboardingRepository(ref.watch(apiClientProvider));
});

class OnboardingRepository {
  final ApiClient _apiClient;

  OnboardingRepository(this._apiClient);

  Future<Result<void>> submitOnboarding(OnboardingFormState formState, {required String idempotencyKey}) async {
    final dto = OnboardingRequestDto.fromForm(formState);
    AppLogger.info('Submitting onboarding data');
    
    final result = await _apiClient.post<dynamic>(
      '/onboarding',
      body: dto.toJson(),
      idempotencyKey: idempotencyKey,
    );

    if (result is Ok) {
      return Ok(null);
    } else if (result is Err) {
      if (result.error is ConflictFailure) {
        // AlreadyCompleted, treat as success
        AppLogger.info('Onboarding already completed (409) - treating as success');
        return Ok(null);
      }
      return Err(result.error);
    }
    throw StateError('Unreachable');
  }
}

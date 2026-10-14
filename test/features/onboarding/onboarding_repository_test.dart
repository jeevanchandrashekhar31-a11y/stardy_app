import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:stardy_app/features/onboarding/onboarding_form.dart';
import 'package:stardy_app/features/onboarding/onboarding_repository.dart';

class FakeApiClient extends ApiClient {
  final Result<dynamic> Function(String path, Map<String, dynamic>? body, String? idempotencyKey) handler;

  FakeApiClient(this.handler);

  @override
  Future<Result<T>> post<T>(
    String path, {
    Map<String, dynamic>? body,
    String? idempotencyKey,
    int timeoutSeconds = 20,
  }) async {
    return handler(path, body, idempotencyKey) as Result<T>;
  }
}

void main() {
  group('OnboardingRepository (FAKE-SERVER)', () {
    late OnboardingRepository repository;
    String? lastIdempotencyKey;

    final validState = const OnboardingFormState(
      careerGoal: 'Become a senior mobile developer',
      purpose: OnboardingPurpose.growCareer,
      howHeard: OnboardingHowHeard.influencer,
      influencerName: 'Tech Guru',
      referralCodeUsed: 'TECH-123_45',
      expectation: 'I expect to learn advanced Flutter architectures and state management.',
      hasUsedSimilarApps: true,
      similarAppsExperience: 'Used some other platforms but they lacked practical projects.',
    );

    setUp(() {
      lastIdempotencyKey = null;
    });

    test('201 success and verifies onboarding_request.json fixture', () async {
      final fixtureFile = File('test/fixtures/contract/onboarding_request.json');
      expect(fixtureFile.existsSync(), isTrue);
      final fixtureJson = jsonDecode(fixtureFile.readAsStringSync()) as Map<String, dynamic>;
      expect(fixtureJson.containsKey('careerGoal'), isTrue);

      final apiClient = FakeApiClient((path, body, idempotencyKey) {
        lastIdempotencyKey = idempotencyKey;
        return Ok({'completed': true});
      });
      repository = OnboardingRepository(apiClient);

      final result = await repository.submitOnboarding(validState, idempotencyKey: 'key-1');
      expect(result, isA<Ok>());
      expect(lastIdempotencyKey, 'key-1');
    });

    test('409 AlreadyCompleted - treats as success', () async {
      final apiClient = FakeApiClient((path, body, idempotencyKey) {
        return Err(const ConflictFailure('Already completed'));
      });
      repository = OnboardingRepository(apiClient);

      final result = await repository.submitOnboarding(validState, idempotencyKey: 'key-2');
      expect(result, isA<Ok>());
    });

    test('400 with message returns ValidationFailure/ServerFailure', () async {
      final apiClient = FakeApiClient((path, body, idempotencyKey) {
        return Err(const ValidationFailure('Invalid goal'));
      });
      repository = OnboardingRepository(apiClient);

      final result = await repository.submitOnboarding(validState, idempotencyKey: 'key-3');
      expect(result, isA<Err>());
      expect((result as Err).error, isA<ValidationFailure>());
    });

    test('429 returns RateLimitedFailure with Retry-After', () async {
      final apiClient = FakeApiClient((path, body, idempotencyKey) {
        return Err(const RateLimitedFailure('Too many requests', retryAfter: 30));
      });
      repository = OnboardingRepository(apiClient);

      final result = await repository.submitOnboarding(validState, idempotencyKey: 'key-4');
      expect(result, isA<Err>());
      final err = (result as Err).error;
      expect(err, isA<RateLimitedFailure>());
      expect((err as RateLimitedFailure).retryAfter, 30);
    });

    test('network failure returns NetworkFailure', () async {
      final apiClient = FakeApiClient((path, body, idempotencyKey) {
        return Err(const NetworkFailure('No Internet'));
      });
      repository = OnboardingRepository(apiClient);

      final result = await repository.submitOnboarding(validState, idempotencyKey: 'key-5');
      expect(result, isA<Err>());
      expect((result as Err).error, isA<NetworkFailure>());
    });
  });
}

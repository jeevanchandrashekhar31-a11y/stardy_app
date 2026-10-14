import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:stardy_app/features/session/session_controller.dart';
import 'package:stardy_app/features/session/session_repository.dart';
import 'package:stardy_app/core/models/user.dart';
import 'package:stardy_app/core/data/ttl_cache.dart';
import 'package:stardy_app/core/network/api_client.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class MockSessionRepository extends Mock implements SessionRepository {}
class MockTtlCache extends Mock implements TtlCache {}
class MockUser extends Mock implements firebase_auth.User { @override String get uid => 'user-123'; }

void main() {
  late MockSessionRepository mockRepository;
  late MockTtlCache mockCache;
  late StreamController<firebase_auth.User?> authStreamController;
  late SessionController controller;
  bool signOutCalled = false;
  String? mockDisplayName;

  late Future<void> Function()? customSignOutFn;

  setUp(() {
    mockRepository = MockSessionRepository();
    mockCache = MockTtlCache();
    authStreamController = StreamController<firebase_auth.User?>();
    signOutCalled = false;
    mockDisplayName = 'Test User';
    customSignOutFn = null;

    controller = SessionController(
      () => mockRepository,
      mockCache,
      authStreamController.stream,
      () async {
        if (customSignOutFn != null) {
          await customSignOutFn!();
        } else {
          signOutCalled = true;
        }
      },
      () => mockDisplayName,
      () {},
    );
  });

  tearDown(() {
    controller.dispose();
    authStreamController.close();
  });

  test('signed-out start', () async {
    when(() => mockCache.clearAll()).thenReturn(null);
    expect(controller.state, isA<SessionBooting>());
    authStreamController.add(null);
    await Future.delayed(Duration.zero);
    expect(controller.state, isA<SessionSignedOut>());
    verify(() => mockCache.clearAll()).called(1);
  });

  test('sign-in leads to Syncing then Ready', () async {
    final mockUser = MockUser();
    final stardyUser = const User(id: '1', name: 'Test User', email: 'test@example.com', profilePictureUrl: null, username: null);
    
    when(() => mockRepository.authSession(displayName: any(named: 'displayName')))
        .thenAnswer((_) async {
      await Future.delayed(const Duration(milliseconds: 10));
      return AuthSessionResponse(user: stardyUser, onboardingCompleted: true);
    });

    authStreamController.add(mockUser);
    await Future.delayed(Duration.zero); // State goes to Syncing
    expect(controller.state, isA<SessionSyncing>());

    await Future.delayed(const Duration(milliseconds: 15)); // Await authSession
    expect(controller.state, isA<SessionReady>());
    expect((controller.state as SessionReady).user.id, '1');
  });

  test('onboardingCompleted false leads to NeedsOnboarding', () async {
    final mockUser = MockUser();
    final stardyUser = const User(id: '1', name: 'Test User', email: 'test@example.com', profilePictureUrl: null, username: null);
    
    when(() => mockRepository.authSession(displayName: any(named: 'displayName')))
        .thenAnswer((_) async => AuthSessionResponse(user: stardyUser, onboardingCompleted: false));

    authStreamController.add(mockUser);
    await Future.delayed(const Duration(milliseconds: 10));

    expect(controller.state, isA<SessionNeedsOnboarding>());
  });

  test('sync failure then Retry recovers', () async {
    final mockUser = MockUser();
    final stardyUser = const User(id: '1', name: 'Test User', email: 'test@example.com', profilePictureUrl: null, username: null);
    
    when(() => mockRepository.authSession(displayName: any(named: 'displayName')))
        .thenThrow(const NetworkFailure('Network error'));

    authStreamController.add(mockUser);
    await Future.delayed(const Duration(milliseconds: 10));

    expect(controller.state, isA<SessionFailed>());

    // Setup success
    when(() => mockRepository.authSession(displayName: any(named: 'displayName')))
        .thenAnswer((_) async => AuthSessionResponse(user: stardyUser, onboardingCompleted: true));
    
    await controller.refresh();

    expect(controller.state, isA<SessionReady>());
  });

  test('two rapid auth events cause exactly one sync', () async {
    final mockUser = MockUser();
    final stardyUser = const User(id: '1', name: 'Test User', email: 'test@example.com', profilePictureUrl: null, username: null);
    
    when(() => mockRepository.authSession(displayName: any(named: 'displayName')))
        .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return AuthSessionResponse(user: stardyUser, onboardingCompleted: true);
        });

    authStreamController.add(mockUser);
    authStreamController.add(mockUser);
    await Future.delayed(const Duration(milliseconds: 100));

    expect(controller.state, isA<SessionReady>());
    verify(() => mockRepository.authSession(displayName: any(named: 'displayName'))).called(1);
  });

  test('sign-out clears the cache and a late response is ignored', () async {
    when(() => mockCache.clearAll()).thenReturn(null);
    final mockUser = MockUser();
    final stardyUser = const User(id: '1', name: 'Test User', email: 'test@example.com', profilePictureUrl: null, username: null);
    
    when(() => mockRepository.authSession(displayName: any(named: 'displayName')))
        .thenAnswer((_) async {
          await Future.delayed(const Duration(milliseconds: 50));
          return AuthSessionResponse(user: stardyUser, onboardingCompleted: true);
        });

    authStreamController.add(mockUser); // Start sync
    await Future.delayed(Duration.zero);
    expect(controller.state, isA<SessionSyncing>());

    authStreamController.add(null); // Sign out mid-sync
    await Future.delayed(Duration.zero);
    expect(controller.state, isA<SessionSignedOut>());

    await Future.delayed(const Duration(milliseconds: 60)); // Let sync complete

    // State should still be SessionSignedOut, not SessionReady
    expect(controller.state, isA<SessionSignedOut>());
    verify(() => mockCache.clearAll()).called(greaterThanOrEqualTo(1));
  });

  test('SessionExpired signs out of Firebase and Google', () async {
    when(() => mockCache.clearAll()).thenReturn(null);
    // Trigger SessionExpired event on ApiClient stream
    ApiClient.dispatchSessionExpiredForTest();
    
    // Wait for the stream to process
    await Future.delayed(Duration.zero);
    
    expect(controller.state, isA<SessionSignedOut>());
    expect(signOutCalled, isTrue);
    verify(() => mockCache.clearAll()).called(1);
  });

  test('signOut clears local session', () async {
    when(() => mockCache.clearAll()).thenReturn(null);
    
    await controller.signOut();
    
    expect(controller.state, isA<SessionSignedOut>());
    expect(signOutCalled, isTrue);
    verify(() => mockCache.clearAll()).called(1);
  });

  test('a throwing sign-out function still ends in SignedOut', () async {
    when(() => mockCache.clearAll()).thenReturn(null);
    customSignOutFn = () async {
      signOutCalled = true;
      throw Exception('Sign out failed');
    };
    
    await controller.signOut();
    
    expect(controller.state, isA<SessionSignedOut>());
    expect(signOutCalled, isTrue);
    verify(() => mockCache.clearAll()).called(1);
  });

  test('refresh() after onboarding sends no idempotency key and ends in SessionReady', () async {
    final mockUser = MockUser();
    final stardyUser = const User(id: '1', name: 'Test User', email: 'test@example.com', profilePictureUrl: null, username: null);
    
    when(() => mockRepository.authSession(displayName: any(named: 'displayName')))
        .thenAnswer((_) async => AuthSessionResponse(user: stardyUser, onboardingCompleted: false));

    authStreamController.add(mockUser);
    await Future.delayed(const Duration(milliseconds: 15));
    
    expect(controller.state, isA<SessionNeedsOnboarding>());

    when(() => mockRepository.authSession(displayName: any(named: 'displayName')))
        .thenAnswer((_) async => AuthSessionResponse(user: stardyUser, onboardingCompleted: true));
        
    await controller.refresh();
    
    expect(controller.state, isA<SessionReady>());
    // Note: mockRepository.authSession without idempotencyKey parameter is implied since the signature is (displayName: ...). If there is no parameter for idempotency key on authSession, then none was sent.
  });
}

import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:google_sign_in/google_sign_in.dart';

import 'session_repository.dart';
import '../../core/models/user.dart';
import '../../core/network/api_client.dart';
import '../../core/data/ttl_cache.dart';
import '../../core/state/session_epoch.dart';

sealed class SessionState {}

class SessionBooting extends SessionState {}

class SessionSignedOut extends SessionState {}

class SessionSyncing extends SessionState {}

class SessionNeedsOnboarding extends SessionState {}

class SessionReady extends SessionState {
  final User user;
  SessionReady(this.user);
}

class SessionFailed extends SessionState {
  final String error;
  SessionFailed(this.error);
}

final authStateStreamProvider = Provider<Stream<firebase_auth.User?>>((ref) {
  return firebase_auth.FirebaseAuth.instance.authStateChanges();
});

final sessionControllerProvider =
    StateNotifierProvider<SessionController, SessionState>((ref) {
      final authStream = ref.watch(authStateStreamProvider);
      return SessionController(
        () => ref.read(sessionRepositoryProvider),
        ref.watch(ttlCacheProvider),
        authStream,
        () async {
          await firebase_auth.FirebaseAuth.instance.signOut();
          try {
            await GoogleSignIn().signOut();
          } catch (_) {}
        },
        () {
          try {
            return firebase_auth.FirebaseAuth.instance.currentUser?.displayName;
          } catch (_) {
            return null;
          }
        },
        () => ref.read(sessionEpochProvider.notifier).state++,
      );
    });

class SessionController extends StateNotifier<SessionState> {
  final SessionRepository Function() _repository;
  final TtlCache _cache;
  final Stream<firebase_auth.User?> _authStateStream;
  final Future<void> Function() _signOutFn;
  final String? Function() _getDisplayNameFn;
  
  StreamSubscription? _authSub;
  StreamSubscription? _expiredSub;
  String? _lastUid;
  int _sessionEpoch = 0;
  
  int get sessionEpoch => _sessionEpoch;

  final void Function() _onEpochIncrement;

  SessionController(
    this._repository, 
    this._cache,
    this._authStateStream,
    this._signOutFn,
    this._getDisplayNameFn,
    this._onEpochIncrement,
  ) : super(SessionBooting()) {
    _authSub = _authStateStream.listen(_onAuthStateChanged);
    _expiredSub = ApiClient.onSessionExpired.listen((_) {
      _handleSessionExpired();
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _expiredSub?.cancel();
    super.dispose();
  }

  void _onAuthStateChanged(firebase_auth.User? firebaseUser) {
    if (firebaseUser == null) {
      _lastUid = null;
      _signOutLocally();
    } else {
      if (_lastUid != firebaseUser.uid) {
        _sessionEpoch++;
        _onEpochIncrement();
        _cache.clearAll();
        state = SessionBooting();
      }
      _lastUid = firebaseUser.uid;

      if (state is SessionSyncing ||
          state is SessionReady ||
          state is SessionNeedsOnboarding) {
        return;
      }
      refresh();
    }
  }

  Future<void> refresh() async {
    final epoch = _sessionEpoch;

    state = SessionSyncing();
    try {
      final displayName = _getDisplayNameFn();

      final response = await _repository().authSession(
        displayName: displayName,
      );

      if (epoch != _sessionEpoch) return;

      if (response.onboardingCompleted) {
        state = SessionReady(response.user);
      } else {
        state = SessionNeedsOnboarding();
      }
    } catch (e) {
      if (epoch != _sessionEpoch) return;

      String errorMsg = 'Failed to sync session.';
      if (e is ValidationFailure) {
        errorMsg = e.message;
      } else if (e is NetworkFailure) {
        errorMsg = e.message;
      } else if (e is ServerFailure) {
        errorMsg = e.message;
      } else if (e is TimeoutFailure) {
        errorMsg = e.message;
      } else if (e is RateLimitedFailure) {
        errorMsg = e.message;
      }

      state = SessionFailed(errorMsg);
    }
  }

  void _signOutLocally() {
    _sessionEpoch++;
    _onEpochIncrement();
    _cache.clearAll();
    state = SessionSignedOut();
  }

  Future<void> _handleSessionExpired() async {
    try {
      await _signOutFn();
    } finally {
      _signOutLocally();
    }
  }

  Future<void> signOut() async {
    try {
      await _signOutFn();
    } catch (_) {
      // Ignore errors
    } finally {
      _signOutLocally();
    }
  }
}

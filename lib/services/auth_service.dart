import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

/// Thin wrapper around Firebase Auth + Google Sign-In.
///
/// Requires a real Firebase project connected via google-services.json
/// (Android) / GoogleService-Info.plist (iOS) — until that's set up these
/// calls throw, so callers should catch and show a friendly message rather
/// than assume success.
class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn();

  User? get currentUser => FirebaseAuth.instance.currentUser;

  Stream<User?> get authStateChanges =>
      FirebaseAuth.instance.authStateChanges();

  Future<UserCredential> signUpWithEmail(String email, String password) {
    return FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  Future<UserCredential> signInWithEmail(String email, String password) {
    return FirebaseAuth.instance.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Returns null if the user cancels the Google account picker.
  Future<UserCredential?> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) return null;

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<void> signOut() async {
    await FirebaseAuth.instance.signOut();
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }
  }
}

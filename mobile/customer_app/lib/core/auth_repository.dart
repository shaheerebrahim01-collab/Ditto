import 'package:firebase_auth/firebase_auth.dart' as fb;
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

import '../models/user.dart';
import 'api_client.dart';
import 'token_storage.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

// Owns the whole sign-in flow: Firebase proves identity, then we exchange
// that for our own JWT via ApiClient.loginWithFirebase and never touch
// Firebase again for the rest of the session (mirrors
// backend/src/modules/auth/auth.service.ts).
class AuthRepository extends ChangeNotifier {
  AuthRepository({ApiClient? apiClient, TokenStorage? tokenStorage, fb.FirebaseAuth? firebaseAuth})
    : _api = apiClient ?? ApiClient(),
      _tokenStorage = tokenStorage ?? TokenStorage(),
      _firebaseAuth = firebaseAuth ?? fb.FirebaseAuth.instance;

  final ApiClient _api;
  final TokenStorage _tokenStorage;
  final fb.FirebaseAuth _firebaseAuth;

  AuthStatus status = AuthStatus.unknown;
  DittoUser? currentUser;
  String? errorMessage;
  bool isLoading = false;

  String? _accessToken;
  String? get accessToken => _accessToken;

  // Call once at app start. If a token is already stored, validate it
  // against GET /users/me rather than trusting it blindly.
  Future<void> restoreSession() async {
    final token = await _tokenStorage.read();
    if (token == null) {
      status = AuthStatus.unauthenticated;
      notifyListeners();
      return;
    }
    try {
      final user = await _api.getMe(token);
      _accessToken = token;
      currentUser = user;
      status = AuthStatus.authenticated;
    } catch (_) {
      await _tokenStorage.clear();
      status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  Future<void> signInWithGoogle() => _runFirebaseSignIn(() async {
    final googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw StateError('Google sign-in cancelled');
    final googleAuth = await googleUser.authentication;
    final credential = fb.GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    await _firebaseAuth.signInWithCredential(credential);
  });

  Future<void> signInWithApple() => _runFirebaseSignIn(() async {
    final appleCredential = await SignInWithApple.getAppleIDCredential(
      scopes: [AppleIDAuthorizationScopes.email, AppleIDAuthorizationScopes.fullName],
    );
    final oauthCredential = fb.OAuthProvider('apple.com').credential(
      idToken: appleCredential.identityToken,
      accessToken: appleCredential.authorizationCode,
    );
    await _firebaseAuth.signInWithCredential(oauthCredential);
  });

  Future<void> signInWithEmail(String email, String password) => _runFirebaseSignIn(() async {
    await _firebaseAuth.signInWithEmailAndPassword(email: email, password: password);
  });

  Future<void> registerWithEmail(String email, String password) => _runFirebaseSignIn(() async {
    await _firebaseAuth.createUserWithEmailAndPassword(email: email, password: password);
  });

  // Phone sign-in is two steps. Step 1 triggers the SMS and hands back a
  // verificationId; step 2 (submitPhoneCode) completes it.
  Future<void> startPhoneVerification({
    required String phoneNumber,
    required void Function(String verificationId) onCodeSent,
    required void Function(String message) onError,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        await _runFirebaseSignIn(() => _firebaseAuth.signInWithCredential(credential));
      },
      verificationFailed: (e) => onError(e.message ?? 'Phone verification failed'),
      codeSent: (verificationId, _) => onCodeSent(verificationId),
      codeAutoRetrievalTimeout: (_) {},
    );
  }

  Future<void> submitPhoneCode(String verificationId, String smsCode) => _runFirebaseSignIn(() async {
    final credential = fb.PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );
    await _firebaseAuth.signInWithCredential(credential);
  });

  Future<void> signOut() async {
    await Future.wait([
      _firebaseAuth.signOut(),
      GoogleSignIn().signOut(),
    ]);
    await _tokenStorage.clear();
    _accessToken = null;
    currentUser = null;
    status = AuthStatus.unauthenticated;
    notifyListeners();
  }

  // Runs a Firebase sign-in step, then exchanges the resulting Firebase ID
  // token for our backend JWT via POST /auth/firebase.
  Future<void> _runFirebaseSignIn(Future<void> Function() firebaseStep) async {
    isLoading = true;
    errorMessage = null;
    notifyListeners();
    try {
      await firebaseStep();
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) throw StateError('Firebase sign-in did not produce a user');
      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) throw StateError('Firebase did not return an ID token');

      final result = await _api.loginWithFirebase(idToken);
      await _tokenStorage.save(result.accessToken);
      _accessToken = result.accessToken;
      currentUser = result.user;
      status = AuthStatus.authenticated;
    } catch (e) {
      errorMessage = e.toString();
      status = AuthStatus.unauthenticated;
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }
}

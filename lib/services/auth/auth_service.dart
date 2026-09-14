import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../models/app_user.dart';
import 'user_role_service.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, UserRoleService? userRoleService})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _userRoleService = userRoleService ?? UserRoleService();

  final FirebaseAuth _firebaseAuth;
  final UserRoleService _userRoleService;

  static Future<void>? _googleInitialization;

  User? get currentUser => _firebaseAuth.currentUser;

  bool get isSignedIn => currentUser != null;

  Stream<User?> get authStateChanges => _firebaseAuth.userChanges();

  bool get supportsGoogleSignIn {
    if (kIsWeb) {
      return true;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.windows;
  }

  bool get supportsPhoneSignIn {
    if (kIsWeb) {
      return true;
    }

    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS;
  }

  Future<UserCredential> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> createUserWithEmailAndPassword({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential?> signInWithGoogle() async {
    if (!supportsGoogleSignIn) {
      throw UnsupportedError(
        'Google sign-in is not supported on this platform.',
      );
    }

    final provider = GoogleAuthProvider();

    if (kIsWeb) {
      return _firebaseAuth.signInWithPopup(provider);
    }

    if (defaultTargetPlatform == TargetPlatform.windows) {
      return _firebaseAuth.signInWithProvider(provider);
    }

    _googleInitialization ??= GoogleSignIn.instance.initialize();
    await _googleInitialization;

    if (!GoogleSignIn.instance.supportsAuthenticate()) {
      throw UnsupportedError(
        'Interactive Google sign-in is unavailable on this platform.',
      );
    }

    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final idToken = googleAuth.idToken;

      if (idToken == null || idToken.isEmpty) {
        throw FirebaseAuthException(
          code: 'missing-google-id-token',
          message: 'Google sign-in did not return an ID token.',
        );
      }

      final credential = GoogleAuthProvider.credential(idToken: idToken);
      return _firebaseAuth.signInWithCredential(credential);
    } on GoogleSignInException catch (error) {
      if (error.code == GoogleSignInExceptionCode.canceled) {
        return null;
      }
      rethrow;
    }
  }

  Future<ConfirmationResult> startWebPhoneSignIn({
    required String phoneNumber,
  }) {
    if (!kIsWeb) {
      throw UnsupportedError(
        'Web phone authentication can only run in a web build.',
      );
    }

    return _firebaseAuth.signInWithPhoneNumber(phoneNumber);
  }

  Future<void> startNativePhoneVerification({
    required String phoneNumber,
    required PhoneVerificationCompleted verificationCompleted,
    required PhoneVerificationFailed verificationFailed,
    required PhoneCodeSent codeSent,
    required PhoneCodeAutoRetrievalTimeout codeAutoRetrievalTimeout,
    int? forceResendingToken,
  }) {
    if (kIsWeb ||
        (defaultTargetPlatform != TargetPlatform.android &&
            defaultTargetPlatform != TargetPlatform.iOS)) {
      throw UnsupportedError(
        'Native phone authentication is supported on Android and iOS.',
      );
    }

    return _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: verificationCompleted,
      verificationFailed: verificationFailed,
      codeSent: codeSent,
      codeAutoRetrievalTimeout: codeAutoRetrievalTimeout,
      forceResendingToken: forceResendingToken,
      timeout: const Duration(seconds: 60),
    );
  }

  Future<UserCredential> signInWithPhoneCredential(
    PhoneAuthCredential credential,
  ) {
    return _firebaseAuth.signInWithCredential(credential);
  }

  Future<UserCredential> confirmNativePhoneCode({
    required String verificationId,
    required String smsCode,
  }) {
    final credential = PhoneAuthProvider.credential(
      verificationId: verificationId,
      smsCode: smsCode,
    );

    return signInWithPhoneCredential(credential);
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<void> sendVerificationEmail() async {
    final user = currentUser;
    if (user == null) {
      throw StateError('No signed-in user is available for verification.');
    }
    if (!user.emailVerified) {
      await user.sendEmailVerification();
    }
  }

  Future<bool> reloadAndCheckEmailVerified() async {
    final user = currentUser;
    if (user == null) {
      return false;
    }

    await user.reload();
    return _firebaseAuth.currentUser?.emailVerified ?? false;
  }

  Future<AppUser?> getCurrentAppUser() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    final role = await _userRoleService.getRole(user.uid);

    return AppUser.fromFirebaseUser(user, role: role);
  }

  Future<AppUser> getAppUser(UserCredential credential) async {
    final user = credential.user;

    if (user == null) {
      throw StateError('Firebase authentication returned no user.');
    }

    final role = await _userRoleService.getRole(user.uid);

    return AppUser.fromFirebaseUser(user, role: role);
  }

  Future<AppUser> signInAndGetAppUser({
    required String email,
    required String password,
  }) async {
    final credential = await signInWithEmailAndPassword(
      email: email,
      password: password,
    );

    return getAppUser(credential);
  }

  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }
}

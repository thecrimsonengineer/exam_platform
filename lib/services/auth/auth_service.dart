import 'package:firebase_auth/firebase_auth.dart';

import '../../models/app_user.dart';
import 'user_role_service.dart';

class AuthService {
  AuthService({FirebaseAuth? firebaseAuth, UserRoleService? userRoleService})
    : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
      _userRoleService = userRoleService ?? UserRoleService();

  final FirebaseAuth _firebaseAuth;
  final UserRoleService _userRoleService;

  User? get currentUser => _firebaseAuth.currentUser;

  bool get isSignedIn => currentUser != null;

  Stream<User?> get authStateChanges => _firebaseAuth.userChanges();

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

import 'package:firebase_auth/firebase_auth.dart';

import '../../models/app_user.dart';
import 'user_role_service.dart';

class AuthService {
  AuthService({
    FirebaseAuth? firebaseAuth,
    UserRoleService? userRoleService,
  }) : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
       _userRoleService = userRoleService ?? UserRoleService();

  final FirebaseAuth _firebaseAuth;
  final UserRoleService _userRoleService;

  User? get currentUser => _firebaseAuth.currentUser;

  bool get isSignedIn => currentUser != null;

  Stream<User?> get authStateChanges => _firebaseAuth.authStateChanges();

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

  Future<AppUser?> getCurrentAppUser() async {
    final user = currentUser;

    if (user == null) {
      return null;
    }

    final role = await _userRoleService.getRole(user.uid);

    return AppUser.fromFirebaseUser(
      user,
      role: role,
    );
  }

  Future<AppUser> getAppUser(UserCredential credential) async {
    final user = credential.user;

    if (user == null) {
      throw StateError('Firebase authentication returned no user.');
    }

    final role = await _userRoleService.getRole(user.uid);

    return AppUser.fromFirebaseUser(
      user,
      role: role,
    );
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
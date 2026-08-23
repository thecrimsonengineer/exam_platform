import 'package:firebase_auth/firebase_auth.dart';

enum AppUserRole {
  admin,
  student,
}

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
  });

  final String uid;
  final String email;
  final AppUserRole role;

  bool get isAdmin => role == AppUserRole.admin;
  bool get isStudent => role == AppUserRole.student;

  factory AppUser.fromFirebaseUser(
    User user, {
    required AppUserRole role,
  }) {
    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      role: role,
    );
  }
}
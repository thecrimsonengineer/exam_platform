import 'package:firebase_auth/firebase_auth.dart';

enum AppUserRole { admin, student }

class AppUser {
  const AppUser({
    required this.uid,
    required this.email,
    required this.role,
    this.emailVerified = true,
  });

  final String uid;
  final String email;
  final AppUserRole role;
  final bool emailVerified;

  bool get isAdmin => role == AppUserRole.admin;
  bool get isStudent => role == AppUserRole.student;

  factory AppUser.fromFirebaseUser(User user, {required AppUserRole role}) {
    final providerIds = user.providerData
        .map((provider) => provider.providerId)
        .toSet();

    final hasTrustedVerifiedProvider =
        providerIds.contains('google.com') || providerIds.contains('phone');

    return AppUser(
      uid: user.uid,
      email: user.email ?? '',
      role: role,
      // Email/password learners must still verify their email. Google and phone
      // providers already verify control of the identity used to authenticate.
      emailVerified: user.emailVerified || hasTrustedVerifiedProvider,
    );
  }
}

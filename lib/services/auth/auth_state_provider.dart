import '../../models/app_user.dart';

abstract interface class AuthStateProvider {
  Stream<AppUser?> get appUserChanges;

  Future<AppUser?> get currentAppUser;

  bool get isSignedIn;

  Future<void> signOut();
}
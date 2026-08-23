import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';

import '../../models/app_user.dart';
import 'auth_service.dart';
import 'auth_state_provider.dart';

class AuthStateService implements AuthStateProvider {
  AuthStateService({
    AuthService? authService,
  }) : _authService = authService ?? AuthService();

  final AuthService _authService;

  Stream<AppUser?> get appUserChanges async* {
    await for (final user in _authService.authStateChanges) {
      if (user == null) {
        yield null;
        continue;
      }

      yield await _authService.getCurrentAppUser();
    }
  }

  Future<AppUser?> get currentAppUser {
    return _authService.getCurrentAppUser();
  }

  bool get isSignedIn => _authService.isSignedIn;

  Future<void> signOut() {
    return _authService.signOut();
  }
}
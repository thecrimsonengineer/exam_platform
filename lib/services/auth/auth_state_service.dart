import 'dart:async';

import '../../models/app_user.dart';
import 'auth_service.dart';
import 'auth_state_provider.dart';

class AuthStateService implements AuthStateProvider {
  AuthStateService({AuthService? authService})
    : _authService = authService ?? AuthService();

  final AuthService _authService;

  @override
  Stream<AppUser?> get appUserChanges async* {
    await for (final user in _authService.authStateChanges) {
      if (user == null) {
        yield null;
        continue;
      }

      yield await _authService.getCurrentAppUser();
    }
  }

  @override
  Future<AppUser?> get currentAppUser {
    return _authService.getCurrentAppUser();
  }

  @override
  bool get isSignedIn => _authService.isSignedIn;

  @override
  Future<void> signOut() {
    return _authService.signOut();
  }
}

import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth/auth_state_provider.dart';
import '../../services/auth/auth_state_service.dart';
import '../admin/admin_home_screen.dart';
import '../navigation/bottom_navigation.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key, this.authStateService, this.loginScreen});

  final AuthStateProvider? authStateService;
  final Widget? loginScreen;

  @override
  Widget build(BuildContext context) {
    final AuthStateProvider service = authStateService ?? AuthStateService();

    return StreamBuilder<AppUser?>(
      stream: service.appUserChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AuthLoadingScreen();
        }

        if (snapshot.hasError) {
          return const _AuthErrorScreen(
            message: 'Unable to determine the current user.',
          );
        }

        final appUser = snapshot.data;

        if (appUser == null) {
          return loginScreen ?? const LoginScreen();
        }

        if (appUser.isAdmin) {
          return const AdminHomeScreen();
        }

        return const BottomNavigationScreen();
      },
    );
  }
}

class _AuthLoadingScreen extends StatelessWidget {
  const _AuthLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: CircularProgressIndicator()));
  }
}

class _AuthErrorScreen extends StatelessWidget {
  const _AuthErrorScreen({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(message, textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

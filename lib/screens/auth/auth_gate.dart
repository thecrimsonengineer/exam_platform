import 'package:flutter/material.dart';

import '../../app/theme.dart';

import '../../models/app_user.dart';
import '../../services/auth/auth_state_provider.dart';
import '../../services/auth/auth_state_service.dart';
import '../../services/auth/learner_local_identity.dart';
import '../../services/online_access/learner_online_access_runtime.dart';
import '../../services/online_access/learner_online_access_session_controller.dart';
import '../admin/admin_home_screen.dart';
import 'learner_authorized_shell.dart';
import 'login_screen.dart';
import 'verify_email_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({
    super.key,
    this.authStateService,
    this.loginScreen,
    this.verificationScreen,
    this.learnerOnlineAccessController,
  });

  final AuthStateProvider? authStateService;
  final Widget? loginScreen;
  final Widget? verificationScreen;
  final LearnerOnlineAccessSessionController? learnerOnlineAccessController;

  @override
  Widget build(BuildContext context) {
    final AuthStateProvider service = authStateService ?? AuthStateService();

    return StreamBuilder<AppUser?>(
      stream: service.appUserChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          LearnerOnlineAccessRuntime.handleAuthUserChanged(null);
          LearnerLocalIdentity.clear();
          return const _AuthLoadingScreen();
        }

        if (snapshot.hasError) {
          LearnerOnlineAccessRuntime.handleAuthUserChanged(null);
          LearnerLocalIdentity.clear();
          return const _AuthErrorScreen(
            message: 'Unable to determine the current user.',
          );
        }

        final appUser = snapshot.data;

        if (appUser == null) {
          LearnerOnlineAccessRuntime.handleAuthUserChanged(null);
          LearnerLocalIdentity.clear();
          return loginScreen ?? const LoginScreen();
        }

        if (appUser.isAdmin) {
          LearnerOnlineAccessRuntime.handleAuthUserChanged(null);
          LearnerLocalIdentity.clear();
          return Theme(
            data: AppTheme.lightTheme,
            child: AdminHomeScreen(
              adminUserId: appUser.uid,
              authStateProvider: service,
            ),
          );
        }

        if (!appUser.emailVerified) {
          LearnerOnlineAccessRuntime.handleAuthUserChanged(null);
          LearnerLocalIdentity.clear();
          return verificationScreen ?? const VerifyEmailScreen();
        }

        LearnerOnlineAccessRuntime.handleAuthUserChanged(appUser.uid);
        LearnerLocalIdentity.activate(appUser.uid);

        return LearnerAuthorizedShell(
          key: ValueKey('student-shell-${appUser.uid}'),
          userId: appUser.uid,
          controller: learnerOnlineAccessController,
        );
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

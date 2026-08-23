import 'package:flutter/material.dart';

import '../../models/app_user.dart';
import '../../services/auth/auth_state_provider.dart';
import '../../services/auth/auth_state_service.dart';
import '../admin/admin_home_screen.dart';
import '../app/app_root_screen.dart';

class AdminGate extends StatelessWidget {
  const AdminGate({
    super.key,
    this.authStateProvider,
  });

  final AuthStateProvider? authStateProvider;

  @override
  Widget build(BuildContext context) {
    final AuthStateProvider service =
        authStateProvider ?? AuthStateService();

    return StreamBuilder<AppUser?>(
      stream: service.appUserChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const _AdminGateLoadingScreen();
        }

        if (snapshot.hasError) {
          return const _AdminGateErrorScreen();
        }

        final appUser = snapshot.data;

        if (appUser == null) {
          return const AppRootScreen();
        }

        if (!appUser.isAdmin) {
          return const _AccessDeniedScreen();
        }

        return const AdminHomeScreen();
      },
    );
  }
}

class _AdminGateLoadingScreen extends StatelessWidget {
  const _AdminGateLoadingScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
}

class _AdminGateErrorScreen extends StatelessWidget {
  const _AdminGateErrorScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Unable to verify administrator access.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

class _AccessDeniedScreen extends StatelessWidget {
  const _AccessDeniedScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Access denied',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Administrator access is required for this area.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),
              FilledButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (_) => const AppRootScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('Return to Portal'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
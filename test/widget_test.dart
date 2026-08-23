import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/models/app_user.dart';
import 'package:exam_platform/screens/auth/auth_gate.dart';
import 'package:exam_platform/services/auth/auth_state_provider.dart';

void main() {
  testWidgets(
    'AuthGate shows login when user is signed out',
    (tester) async {
      final authStateProvider = _FakeAuthStateProvider(
        appUser: null,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            authStateService: authStateProvider,
            loginScreen: const Scaffold(
              body: Center(
                child: Text('Sign in'),
              ),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Sign in'), findsOneWidget);
    },
  );

  testWidgets(
    'AuthGate shows admin home for an admin user',
    (tester) async {
      const adminUser = AppUser(
        uid: 'admin-1',
        email: 'admin@example.com',
        role: AppUserRole.admin,
      );

      final authStateProvider = _FakeAuthStateProvider(
        appUser: adminUser,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            authStateService: authStateProvider,
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Command Center'), findsOneWidget);
    },
  );

  testWidgets(
    'AuthGate shows student platform for a student user',
    (tester) async {
      const studentUser = AppUser(
        uid: 'student-1',
        email: 'student@example.com',
        role: AppUserRole.student,
      );

      final authStateProvider = _FakeAuthStateProvider(
        appUser: studentUser,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: AuthGate(
            authStateService: authStateProvider,
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Student platform'), findsOneWidget);
    },
  );
}

class _FakeAuthStateProvider implements AuthStateProvider {
  const _FakeAuthStateProvider({
    required this.appUser,
  });

  final AppUser? appUser;

  @override
  Stream<AppUser?> get appUserChanges async* {
    yield appUser;
  }

  @override
  Future<AppUser?> get currentAppUser async {
    return appUser;
  }

  @override
  bool get isSignedIn => appUser != null;

  @override
  Future<void> signOut() async {}
}
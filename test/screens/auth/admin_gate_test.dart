import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/models/app_user.dart';
import 'package:exam_platform/screens/admin/admin_home_screen.dart';
import 'package:exam_platform/screens/auth/admin_gate.dart';
import 'package:exam_platform/services/auth/auth_state_provider.dart';

void main() {
  testWidgets(
    'AdminGate denies access when user is signed out',
    (tester) async {
      const provider = _FakeAuthStateProvider(
        appUser: null,
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminGate(
            authStateProvider: provider,
          ),
        ),
      );

      await tester.pump();

      expect(find.text('CSP11'), findsOneWidget);
      expect(find.byType(AdminHomeScreen), findsNothing);
    },
  );

  testWidgets(
    'AdminGate denies access to a student',
    (tester) async {
      const provider = _FakeAuthStateProvider(
        appUser: AppUser(
          uid: 'student-001',
          email: 'student@example.com',
          role: AppUserRole.student,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminGate(
            authStateProvider: provider,
          ),
        ),
      );

      await tester.pump();

      expect(find.text('Access denied'), findsOneWidget);
      expect(
        find.text('Administrator access is required for this area.'),
        findsOneWidget,
      );
      expect(find.byType(AdminHomeScreen), findsNothing);
    },
  );

  testWidgets(
    'AdminGate allows an administrator into Admin Home',
    (tester) async {
      const provider = _FakeAuthStateProvider(
        appUser: AppUser(
          uid: 'admin-001',
          email: 'admin@example.com',
          role: AppUserRole.admin,
        ),
      );

      await tester.pumpWidget(
        const MaterialApp(
          home: AdminGate(
            authStateProvider: provider,
          ),
        ),
      );

      await tester.pump();

      expect(find.byType(AdminHomeScreen), findsOneWidget);
      expect(find.text('Access denied'), findsNothing);
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
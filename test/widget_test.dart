import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:exam_platform/models/app_user.dart';
import 'package:exam_platform/screens/auth/auth_gate.dart';
import 'package:exam_platform/services/auth/auth_state_provider.dart';
import 'package:exam_platform/services/auth/learner_local_identity.dart';
import 'package:exam_platform/services/online_access/learner_online_access_gate.dart';
import 'package:exam_platform/services/online_access/learner_online_access_session_controller.dart';

void main() {
  setUp(LearnerLocalIdentity.clear);
  tearDown(LearnerLocalIdentity.clear);

  testWidgets('AuthGate shows login when user is signed out', (tester) async {
    LearnerLocalIdentity.activate('stale-user');

    final authStateProvider = _FakeAuthStateProvider(appUser: null);

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          authStateService: authStateProvider,
          loginScreen: const Scaffold(body: Center(child: Text('Sign in'))),
        ),
      ),
    );

    await tester.pump();

    expect(find.text('Sign in'), findsOneWidget);
    expect(LearnerLocalIdentity.currentUserId, isNull);
  });

  testWidgets('AuthGate shows admin home for an admin user', (tester) async {
    LearnerLocalIdentity.activate('stale-user');

    const adminUser = AppUser(
      uid: 'admin-1',
      email: 'admin@example.com',
      role: AppUserRole.admin,
    );

    final authStateProvider = _FakeAuthStateProvider(appUser: adminUser);

    await tester.pumpWidget(
      MaterialApp(home: AuthGate(authStateService: authStateProvider)),
    );

    await tester.pump();

    expect(find.text('Command Center'), findsOneWidget);
    expect(LearnerLocalIdentity.currentUserId, isNull);
  });

  testWidgets('AuthGate scopes student platform to the Firebase UID', (
    tester,
  ) async {
    const studentUser = AppUser(
      uid: 'student-1',
      email: 'student@example.com',
      role: AppUserRole.student,
    );

    final authStateProvider = _FakeAuthStateProvider(appUser: studentUser);
    final accessController = LearnerOnlineAccessSessionController(
      validator: _AuthorizedValidator(),
      currentUserId: () => LearnerLocalIdentity.currentUserId,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          authStateService: authStateProvider,
          learnerOnlineAccessController: accessController,
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Home'), findsOneWidget);
    expect(LearnerLocalIdentity.currentUserId, 'student-1');
    expect(
      find.byKey(const ValueKey('student-shell-student-1')),
      findsOneWidget,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    accessController.dispose();
  });
}

class _AuthorizedValidator implements LearnerOnlineAccessValidator {
  @override
  Future<LearnerOnlineAccessResult> validate({
    bool forceRefreshToken = false,
  }) async {
    return LearnerOnlineAccessResult(
      status: LearnerOnlineAccessStatus.authorized,
      checkedAt: DateTime.utc(2026),
    );
  }
}

class _FakeAuthStateProvider implements AuthStateProvider {
  const _FakeAuthStateProvider({required this.appUser});

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

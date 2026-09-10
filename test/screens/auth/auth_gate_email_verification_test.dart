import 'package:exam_platform/models/app_user.dart';
import 'package:exam_platform/screens/auth/auth_gate.dart';
import 'package:exam_platform/services/auth/auth_state_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAuthStateProvider implements AuthStateProvider {
  _FakeAuthStateProvider(this.user);

  final AppUser? user;

  @override
  Stream<AppUser?> get appUserChanges => Stream.value(user);

  @override
  Future<AppUser?> get currentAppUser async => user;

  @override
  bool get isSignedIn => user != null;

  @override
  Future<void> signOut() async {}
}

void main() {
  testWidgets('unverified student is stopped at verification gate', (
    tester,
  ) async {
    const learner = AppUser(
      uid: 'student-1',
      email: 'student@example.com',
      role: AppUserRole.student,
      emailVerified: false,
    );

    const verificationMarker = Key('verification-gate-marker');

    await tester.pumpWidget(
      MaterialApp(
        home: AuthGate(
          authStateService: _FakeAuthStateProvider(learner),
          verificationScreen: const Scaffold(
            body: Center(
              child: Text('Verify your email', key: verificationMarker),
            ),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(verificationMarker), findsOneWidget);
    expect(find.text('Verify your email'), findsOneWidget);
  });
}

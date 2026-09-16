import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'admin auth and student-portal preview preserve learner identity boundary',
    () async {
      final authGate = await File(
        'lib/screens/auth/auth_gate.dart',
      ).readAsString();
      final adminGate = await File(
        'lib/screens/auth/admin_gate.dart',
      ).readAsString();
      final adminHome = await File(
        'lib/screens/admin/admin_home_screen.dart',
      ).readAsString();

      expect(authGate, contains('adminUserId: appUser.uid'));
      expect(authGate, contains('authStateProvider: service'));

      expect(adminGate, contains('adminUserId: appUser.uid'));
      expect(adminGate, contains('authStateProvider: service'));

      expect(
        adminHome,
        contains('LearnerLocalIdentity.activate(adminUserId);'),
      );
      expect(adminHome, contains('LearnerLocalIdentity.clear();'));
      expect(adminHome, contains('await Navigator.of(context).push('));
      expect(adminHome, contains('await _authStateProvider.signOut();'));

      final activateIndex = adminHome.indexOf(
        'LearnerLocalIdentity.activate(adminUserId);',
      );
      final navigationIndex = adminHome.indexOf(
        'await Navigator.of(context).push(',
      );

      expect(activateIndex, greaterThanOrEqualTo(0));
      expect(navigationIndex, greaterThan(activateIndex));
    },
  );

  test('admin hotfix keeps logout visible on desktop and mobile', () async {
    final adminHome = await File(
      'lib/screens/admin/admin_home_screen.dart',
    ).readAsString();

    expect(
      RegExp("tooltip: 'Sign out'").allMatches(adminHome).length,
      greaterThanOrEqualTo(2),
    );
    expect(adminHome, contains('Icons.logout_rounded'));
  });

  test(
    'student portal preview still uses the existing learner shell',
    () async {
      final adminHome = await File(
        'lib/screens/admin/admin_home_screen.dart',
      ).readAsString();

      expect(adminHome, contains('const BottomNavigationScreen()'));
      expect(adminHome, isNot(contains('FirebaseAuth.instance')));
    },
  );
}

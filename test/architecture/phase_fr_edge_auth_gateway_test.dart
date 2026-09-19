import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FR2 Edge auth gateway verifies only the CSP11 Firebase project', () {
    final source = File(
      'supabase/functions/firebase-auth-probe/index.ts',
    ).readAsStringSync();

    expect(source, contains('csp11-exam-platform'));
    expect(source, contains('securetoken.google.com'));
    expect(source, contains('service_accounts/v1/jwk'));
    expect(source, contains('jwtVerify'));
    expect(source, contains('algorithms: ["RS256"]'));
    expect(source, contains('audience: firebaseProjectId'));
    expect(source, contains('issuer: firebaseIssuer'));
  });

  test('FR2 Edge auth gateway does not embed privileged Supabase credentials', () {
    final source = File(
      'supabase/functions/firebase-auth-probe/index.ts',
    ).readAsStringSync();

    expect(source, isNot(contains('SUPABASE_SERVICE_ROLE_KEY')));
    expect(source, isNot(contains('sb_secret_')));
    expect(source, isNot(contains('service_role')));
  });

  test('FR2 excludes Firebase Cloud Functions from the free-tier path', () {
    expect(Directory('functions').existsSync(), isFalse);
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FCC Edge Function exposes protected Flashcard operations', () {
    final source = File(
      'supabase/functions/learner-question-packages/index.ts',
    ).readAsStringSync();

    expect(source, contains('operation === "flashcard_catalog"'));
    expect(source, contains('operation === "flashcard_competency"'));
    expect(source, contains('.eq("package_kind", "flashcards")'));
    expect(source, contains('.eq("is_current", true)'));
    expect(source, contains('knownFlashcardVersion'));
    expect(source, contains('knownFlashcardChecksumSha256'));
    expect(source, contains('signedUrlTtlSeconds'));
    expect(source, contains('verifyFirebaseUid(req)'));
  });

  test('FCC publication RPC is invoker-secured and service-role only', () {
    final source = File(
      'supabase/migrations/20260925112000_fcc_flashcard_publication_rpc.sql',
    ).readAsStringSync();

    expect(source, contains("package_kind = 'flashcards'"));
    expect(source, contains("'csp11-published-packages'"));
    expect(source, contains('pg_advisory_xact_lock'));
    expect(source, contains('revoke all on function'));
    expect(source, contains('from public, anon, authenticated'));
    expect(source, contains('to service_role'));
    expect(source.toLowerCase(), isNot(contains('security definer')));
  });
}

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const corePath = 'tool/fr5_shadow_parity/fr5_shadow_parity_core.dart';
  const cliPath = 'tool/fr5_shadow_parity/fr5_shadow_parity.dart';
  const workflowPath =
      '.github/workflows/phase_fr_firestore_read_reduction.yml';

  late String core;
  late String cli;
  late String workflow;

  setUpAll(() {
    core = File(corePath).readAsStringSync();
    cli = File(cliPath).readAsStringSync();
    workflow = File(workflowPath).readAsStringSync();
  });

  test('FR5 tooling stays outside learner runtime', () {
    expect(core, isNot(contains('package:flutter/')));
    expect(cli, isNot(contains('package:flutter/')));
    expect(cli, isNot(contains('firebase_core')));
    expect(cli, isNot(contains('supabase_flutter')));
  });

  test('FR5 apply remains explicit shadow-only and non-destructive', () {
    expect(cli, contains('FR5_SHADOW_ONLY'));
    expect(cli, contains('--apply-shadow'));
    expect(cli, contains('unexpectedTargetKeys'));
    expect(cli, isNot(contains("_request('DELETE'")));
    expect(cli, isNot(contains('_request("DELETE"')));
  });

  test('FR5 prefers current Supabase secret keys server-side', () {
    expect(cli, contains('SUPABASE_SECRET_KEY'));
    expect(cli, contains('SUPABASE_SERVICE_ROLE_KEY'));
    expect(cli, contains("request.headers.set('apikey', apiKey)"));
    expect(cli, contains("credentialKind: 'secret_key'"));
  });

  test('FR5 parity proves IDs, checksums, learner projection and ledger', () {
    expect(core, contains("'missing_target'"));
    expect(core, contains("'checksum_mismatch'"));
    expect(core, contains("'learner_visible_mismatch'"));
    expect(core, contains("'extra_target'"));
    expect(core, contains("'duplicate_target'"));
    expect(core, contains("'missing_ledger'"));
    expect(core, contains("'ledger_mismatch'"));
    expect(core, contains("'extra_ledger'"));
    expect(core, contains('fr5LearnerVisibleMatches'));
  });

  test('FR5 CI preserves FR4, frozen L4 and full repository gates', () {
    expect(workflow, contains('FR4 deterministic fixture plan gate'));
    expect(workflow, contains('FR5 shadow parity unit tests'));
    expect(workflow, contains('FR5 deterministic fixture parity gate'));
    expect(workflow, contains('Preserve frozen Phase L4 learner regressions'));
    expect(workflow, contains('Preserve frozen Phase L4 quality gates'));
    expect(workflow, contains('Preserve exact frozen Phase L engine suite'));
    expect(workflow, contains('Full repository regression'));
  });
}

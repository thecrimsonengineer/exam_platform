import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const phasePath = 'docs/firestore/PHASE_FR9_QUESTION_DELIVERY_CUTOVER.md';
  const packagePath = 'lib/services/questions/published_question_package.dart';
  const fr7BuilderPath =
      'tool/fr7_package_publish/fr7_package_publish_core.dart';
  const workflowPath =
      '.github/workflows/phase_fr_firestore_read_reduction.yml';

  late String phase;
  late String packageSource;
  late String fr7Builder;
  late String workflow;

  setUpAll(() {
    phase = File(phasePath).readAsStringSync();
    packageSource = File(packagePath).readAsStringSync();
    fr7Builder = File(fr7BuilderPath).readAsStringSync();
    workflow = File(workflowPath).readAsStringSync();
  });

  test('FR9 starts only from the exact frozen FR8 checkpoint', () {
    expect(phase, contains('phase-fr8-closed'));
    expect(phase, contains('a55dd91c25df2f3e1b9f59298130d2bd72a929f3'));
  });

  test('FR9 keeps direct learner Supabase Data API access forbidden', () {
    expect(phase, contains('direct learner Data API access remains forbidden'));
    expect(phase, contains('private Storage objects are never made public'));
    expect(phase, contains('short-lived signed URL'));
  });

  test('FR9 decoder is pinned to the frozen FR7 question envelope', () {
    expect(fr7Builder, contains("'schemaVersion': 1"));
    expect(fr7Builder, contains("'kind': 'questions'"));
    expect(fr7Builder, contains("'questionCount': payloads.length"));
    expect(fr7Builder, contains("'questions': payloads"));

    expect(packageSource, contains("_requiredInt(envelope, 'schemaVersion')"));
    expect(packageSource, contains("_requiredString(envelope, 'kind')"));
    expect(packageSource, contains("'questionCount'"));
    expect(packageSource, contains("envelope['questions']"));
  });

  test('FR9 verifies protected package bytes before question decoding', () {
    final byteCountIndex = packageSource.indexOf(
      'compressedBytes.length != descriptor.compressedBytes',
    );
    final checksumIndex = packageSource.indexOf(
      'sha256.convert(compressed).toString()',
    );
    final gzipIndex = packageSource.indexOf(
      'GZipDecoder().decodeBytes(compressed)',
    );
    final jsonIndex = packageSource.indexOf(
      'jsonDecode(utf8.decode(decodedBytes))',
    );

    expect(byteCountIndex, greaterThanOrEqualTo(0));
    expect(checksumIndex, greaterThan(byteCountIndex));
    expect(gzipIndex, greaterThan(checksumIndex));
    expect(jsonIndex, greaterThan(gzipIndex));
  });

  test(
    'FR9 package validation remains competency-scoped and published-only',
    () {
      expect(packageSource, contains('Question package competency mismatch'));
      expect(
        packageSource,
        contains('Question package contains a cross-competency question'),
      );
      expect(
        packageSource,
        contains('Question package contains a non-published question'),
      );
      expect(packageSource, contains('exactly four options'));
    },
  );

  test('FR9 freezes the protected question cache budget below whole bank', () {
    expect(phase, contains('512 KiB'));
    expect(phase, contains('1,040,943'));
    expect(phase, contains('below the complete current question bank'));
  });

  test('FR9 is wired into the main FR validation workflow', () {
    expect(workflow, contains('phase-fr9-question-delivery-cutover'));
    expect(workflow, contains('FR9 question delivery foundation tests'));
  });
}

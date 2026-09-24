import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_idle_asset_contract.dart';

const _rolloutPath =
    'lib/features/learning_twin/ui/learning_twin_motion_rollout.dart';
const _evidencePath =
    'docs/learning_twin/evidence/LTAM_5_HERO_IDLE_ASSET_ADMISSION.json';

Future<void> main(List<String> args) async {
  final options = _AdmissionOptions.parse(args);

  if (options.showHelp) {
    _printUsage();
    return;
  }

  if (options.error != null) {
    stderr.writeln(options.error);
    _printUsage();
    exitCode = 64;
    return;
  }

  final candidatePath = options.candidatePath!;
  final candidateFile = File(candidatePath);
  if (!candidateFile.existsSync()) {
    stderr.writeln('LTAM-5 asset intake blocked: candidate not found.');
    stderr.writeln('Candidate: $candidatePath');
    exitCode = 2;
    return;
  }

  final bytes = candidateFile.readAsBytesSync();
  final String source;
  try {
    source = utf8.decode(bytes);
  } on FormatException {
    stderr.writeln('LTAM-5 asset intake blocked: candidate is not UTF-8 JSON.');
    exitCode = 2;
    return;
  }

  final validation = LearningTwinIdleAssetContract.validateJson(source);
  if (!validation.isValid) {
    stderr.writeln('LTAM-5 idle candidate INVALID.');
    for (final issue in validation.errors) {
      stderr.writeln(' - $issue');
    }
    exitCode = 1;
    return;
  }

  final digest = sha256.convert(bytes).toString();

  stdout.writeln('LTAM-5 IDLE CANDIDATE VALID');
  stdout.writeln('Candidate: $candidatePath');
  stdout.writeln('Canonical: ${LearningTwinIdleAssetContract.canonicalPath}');
  stdout.writeln('SHA-256: $digest');
  stdout.writeln('Frame rate: ${LearningTwinIdleAssetContract.frameRate}');
  stdout.writeln(
    'Frames: ${LearningTwinIdleAssetContract.inPoint.toInt()}-'
    '${LearningTwinIdleAssetContract.outPoint.toInt()}',
  );
  stdout.writeln(
    'Duration: ${LearningTwinIdleAssetContract.durationSeconds.toStringAsFixed(1)} s',
  );

  if (!options.apply) {
    stdout.writeln(
      'Dry run only. No production asset or rollout state was changed.',
    );
    stdout.writeln(
      'After asset-level human review, rerun with '
      '--apply --reviewed --review-date YYYY-MM-DD.',
    );
    return;
  }

  if (!options.reviewed) {
    stderr.writeln(
      'LTAM-5 promotion blocked: --apply requires explicit --reviewed.',
    );
    exitCode = 65;
    return;
  }

  final reviewDate = options.reviewDate;
  if (reviewDate == null || !_isStrictIsoDate(reviewDate)) {
    stderr.writeln(
      'LTAM-5 promotion blocked: --apply requires '
      '--review-date YYYY-MM-DD.',
    );
    exitCode = 65;
    return;
  }

  final rolloutFile = File(_rolloutPath);
  if (!rolloutFile.existsSync()) {
    stderr.writeln('LTAM-5 promotion blocked: rollout policy file is missing.');
    exitCode = 2;
    return;
  }

  final rolloutSource = rolloutFile.readAsStringSync();
  const expectedAdmitted =
      'static const bool canonicalIdleClipAdmitted = false;';
  const expectedSha = 'static const String? canonicalIdleClipSha256 = null;';

  if (!rolloutSource.contains(expectedAdmitted) ||
      !rolloutSource.contains(expectedSha)) {
    stderr.writeln(
      'LTAM-5 promotion blocked: rollout policy is not in the expected '
      'fail-closed state.',
    );
    exitCode = 3;
    return;
  }

  final canonicalFile = File(LearningTwinIdleAssetContract.canonicalPath);
  if (canonicalFile.existsSync()) {
    stderr.writeln(
      'LTAM-5 promotion blocked: canonical idle asset already exists. '
      'Use a fresh branch or reconcile the existing admission first.',
    );
    exitCode = 3;
    return;
  }

  canonicalFile.parent.createSync(recursive: true);
  canonicalFile.writeAsBytesSync(bytes, flush: true);

  final promotedRollout = rolloutSource
      .replaceFirst(
        expectedAdmitted,
        'static const bool canonicalIdleClipAdmitted = true;',
      )
      .replaceFirst(
        expectedSha,
        "static const String? canonicalIdleClipSha256 = '$digest';",
      );
  rolloutFile.writeAsStringSync(promotedRollout, flush: true);

  final evidenceFile = File(_evidencePath);
  evidenceFile.parent.createSync(recursive: true);
  final evidence = <String, dynamic>{
    'schemaVersion': 1,
    'phase': 'LTAM-5',
    'status': 'asset_admitted_for_hero_runtime_pilot',
    'reviewDate': reviewDate,
    'candidatePath': candidatePath,
    'canonicalPath': LearningTwinIdleAssetContract.canonicalPath,
    'sha256': digest,
    'frameRate': LearningTwinIdleAssetContract.frameRate,
    'inPoint': LearningTwinIdleAssetContract.inPoint,
    'outPoint': LearningTwinIdleAssetContract.outPoint,
    'durationSeconds': LearningTwinIdleAssetContract.durationSeconds,
    'finalRuntimeAcceptance': 'pending',
    'allowedFinalOutcomes': <String>['ACCEPT', 'TUNE', 'REJECT_TO_STATIC'],
  };
  evidenceFile.writeAsStringSync(
    const JsonEncoder.withIndent('  ').convert(evidence) + '\n',
    flush: true,
  );

  stdout.writeln('LTAM-5 idle asset PROMOTED FOR HERO RUNTIME PILOT');
  stdout.writeln('Production Hero motion gate is now enabled on this branch.');
  stdout.writeln('Admission evidence: $_evidencePath');
  stdout.writeln(
    'This is not final runtime acceptance. Android, Web and Windows '
    'visual/lifecycle review is still required.',
  );
}

bool _isStrictIsoDate(String value) {
  if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
    return false;
  }

  final parsed = DateTime.tryParse(value);
  if (parsed == null) {
    return false;
  }

  final normalized =
      '${parsed.year.toString().padLeft(4, '0')}-'
      '${parsed.month.toString().padLeft(2, '0')}-'
      '${parsed.day.toString().padLeft(2, '0')}';
  return normalized == value;
}

void _printUsage() {
  stdout.writeln(
    'LTAM-5 canonical idle asset admission\n'
    '\n'
    'Dry-run validation:\n'
    '  dart run tool/learning_twin/ltam5_idle_asset_admission.dart '
    '--candidate <path>\n'
    '\n'
    'Promote an already reviewed candidate for the real Hero pilot:\n'
    '  dart run tool/learning_twin/ltam5_idle_asset_admission.dart '
    '--candidate <path> --apply --reviewed --review-date YYYY-MM-DD\n'
    '\n'
    'The apply path copies the candidate to '
    'assets/learning_twin/motion/twin_idle.json, freezes its SHA-256, '
    'enables only the Hero idle pilot and writes admission evidence.\n'
    'It does not record final ACCEPT, TUNE or REJECT_TO_STATIC.',
  );
}

class _AdmissionOptions {
  const _AdmissionOptions({
    required this.candidatePath,
    required this.apply,
    required this.reviewed,
    required this.reviewDate,
    required this.showHelp,
    required this.error,
  });

  factory _AdmissionOptions.parse(List<String> args) {
    String? candidatePath;
    String? reviewDate;
    var apply = false;
    var reviewed = false;
    var showHelp = false;
    String? error;

    for (var index = 0; index < args.length; index++) {
      final arg = args[index];

      switch (arg) {
        case '--help':
        case '-h':
          showHelp = true;
        case '--apply':
          apply = true;
        case '--reviewed':
          reviewed = true;
        case '--candidate':
          if (index + 1 >= args.length) {
            error = '--candidate requires a path.';
            break;
          }
          candidatePath = args[++index];
        case '--review-date':
          if (index + 1 >= args.length) {
            error = '--review-date requires YYYY-MM-DD.';
            break;
          }
          reviewDate = args[++index];
        default:
          error = 'Unknown argument: $arg';
      }

      if (error != null) {
        break;
      }
    }

    if (!showHelp && error == null && candidatePath == null) {
      error = '--candidate is required.';
    }

    return _AdmissionOptions(
      candidatePath: candidatePath,
      apply: apply,
      reviewed: reviewed,
      reviewDate: reviewDate,
      showHelp: showHelp,
      error: error,
    );
  }

  final String? candidatePath;
  final bool apply;
  final bool reviewed;
  final String? reviewDate;
  final bool showHelp;
  final String? error;
}

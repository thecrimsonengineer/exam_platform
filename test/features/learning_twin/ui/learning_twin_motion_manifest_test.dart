import 'dart:io';

import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_error.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_manifest.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_state.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late String validManifest;

  setUpAll(() async {
    validManifest = await File(
      LearningTwinMotionManifest.assetPath,
    ).readAsString();
  });

  test('canonical bundled manifest parses and covers every V1 state', () {
    final result = LearningTwinMotionManifest.parse(validManifest);

    expect(result.isValid, isTrue);
    expect(result.failure, isNull);
    expect(
      result.manifest!.descriptors.keys.toSet(),
      canonicalLearningTwinMotionStates.toSet(),
    );
    expect(result.manifest!.defaultState, LearningTwinMotionState.idle);
  });

  test('malformed JSON fails closed', () {
    final result = LearningTwinMotionManifest.parse('{broken');

    expect(result.isValid, isFalse);
    expect(result.failure!.code, LearningTwinMotionErrorCode.malformedJson);
  });

  test('unsupported schema fails closed', () {
    final result = LearningTwinMotionManifest.parse(
      validManifest.replaceFirst('"schema_version": 1', '"schema_version": 2'),
    );

    expect(result.isValid, isFalse);
    expect(result.failure!.code, LearningTwinMotionErrorCode.unsupportedSchema);
  });

  test('missing default state fails closed', () {
    final result = LearningTwinMotionManifest.parse(
      validManifest.replaceFirst(
        '"default_state": "idle"',
        '"default_state": "missing"',
      ),
    );

    expect(result.isValid, isFalse);
    expect(
      result.failure!.code,
      LearningTwinMotionErrorCode.invalidDefaultState,
    );
  });

  test('missing canonical state fails closed', () {
    final result = LearningTwinMotionManifest.parse(
      validManifest.replaceFirst(
        '"result_review": {',
        '"result_review_removed": {',
      ),
    );

    expect(result.isValid, isFalse);
    expect(
      result.failure!.code,
      LearningTwinMotionErrorCode.missingCanonicalState,
    );
  });

  test('invalid duration fails closed', () {
    final result = LearningTwinMotionManifest.parse(
      validManifest.replaceFirst('"duration_ms": 6000', '"duration_ms": 0'),
    );

    expect(result.isValid, isFalse);
    expect(result.failure!.code, LearningTwinMotionErrorCode.invalidDescriptor);
  });

  test('invalid intensity fails closed', () {
    final result = LearningTwinMotionManifest.parse(
      validManifest.replaceFirst(
        '"motion_intensity": 1',
        '"motion_intensity": 4',
      ),
    );

    expect(result.isValid, isFalse);
    expect(result.failure!.code, LearningTwinMotionErrorCode.invalidDescriptor);
  });

  test('remote motion asset path is rejected', () {
    final result = LearningTwinMotionManifest.parse(
      validManifest.replaceFirst(
        'assets/learning_twin/motion/twin_idle.json',
        'https://example.invalid/twin_idle.json',
      ),
    );

    expect(result.isValid, isFalse);
    expect(result.failure!.code, LearningTwinMotionErrorCode.remoteAssetPath);
  });

  test('path traversal is rejected', () {
    final result = LearningTwinMotionManifest.parse(
      validManifest.replaceFirst(
        'assets/learning_twin/motion/twin_idle.json',
        'assets/learning_twin/../escape.json',
      ),
    );

    expect(result.isValid, isFalse);
    expect(result.failure!.code, LearningTwinMotionErrorCode.pathTraversal);
  });

  test('duplicate canonical state key is rejected', () {
    final duplicate = validManifest.replaceFirst(
      '"states": {',
      '"states": {"idle": {"asset": "assets/learning_twin/motion/twin_idle.json", "fallback": "assets/learning_twin/naveed_twin.svg", "loop": true, "duration_ms": 6000, "priority": 0, "motion_intensity": 1},',
    );
    final result = LearningTwinMotionManifest.parse(duplicate);

    expect(result.isValid, isFalse);
    expect(result.failure!.code, LearningTwinMotionErrorCode.duplicateState);
  });
}

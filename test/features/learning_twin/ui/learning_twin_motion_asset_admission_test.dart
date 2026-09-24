import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_idle_asset_contract.dart';
import 'package:exam_platform/features/learning_twin/ui/learning_twin_motion_rollout.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('canonical idle clip presence matches the LTAM-5 admission switch', () {
    final idleClip = File(LearningTwinIdleAssetContract.canonicalPath);

    expect(
      idleClip.existsSync(),
      LearningTwinMotionRollout.canonicalIdleClipAdmitted,
      reason:
          'The canonical idle clip must not silently enter or leave production. '
          'Asset presence and the reviewed LTAM-5 admission switch must change '
          'together after visual/device acceptance.',
    );

    if (!idleClip.existsSync()) {
      expect(LearningTwinMotionRollout.canonicalIdleClipSha256, isNull);
      return;
    }

    final bytes = idleClip.readAsBytesSync();
    final source = utf8.decode(bytes);
    final validation = LearningTwinIdleAssetContract.validateJson(source);

    expect(
      validation.isValid,
      isTrue,
      reason: 'Idle Lottie failed contract: ${validation.errors.join(', ')}',
    );

    expect(
      LearningTwinMotionRollout.canonicalIdleClipSha256,
      isNotNull,
      reason: 'An admitted idle clip must freeze its SHA-256.',
    );
    expect(
      sha256.convert(bytes).toString(),
      LearningTwinMotionRollout.canonicalIdleClipSha256,
      reason: 'The admitted idle clip bytes differ from the frozen SHA-256.',
    );
  });
}

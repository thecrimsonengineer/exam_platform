import 'dart:convert';

import 'package:crypto/crypto.dart';

abstract final class LabSnapshotFingerprint {
  static const String schema = 'csp11.lab.snapshot.sha256.v1';

  static String compute(String publishedJson) {
    final digest = sha256.convert(utf8.encode(publishedJson));
    return schema + ':' + digest.toString();
  }

  static bool matches({
    required String publishedJson,
    required String fingerprint,
  }) {
    return fingerprint == compute(publishedJson);
  }
}

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_governance/release_version.dart';

void main() {
  group('ReleaseVersion.parse', () {
    test('parses valid governed versions', () {
      final version = ReleaseVersion.parse('1.2.3+45');

      expect(version.major, 1);
      expect(version.minor, 2);
      expect(version.patch, 3);
      expect(version.buildNumber, 45);
      expect(version.versionName, '1.2.3');
      expect(version.fullVersion, '1.2.3+45');
      expect(version.toString(), '1.2.3+45');
    });

    test('accepts zero-valued components', () {
      expect(ReleaseVersion.parse('0.0.0+0').fullVersion, '0.0.0+0');
    });

    for (final invalid in <String>[
      '1.0',
      '1',
      'v1.0.0+1',
      '1.0.0',
      '1.0.0+',
      '1.0.0+abc',
      '01.0.0+1',
      '1.01.0+1',
      '1.0.01+1',
      '1.0.0+01',
      '-1.0.0+1',
      '1.-1.0+1',
      '1.0.-1+1',
      '1.0.0+-1',
      ' 1.0.0+1',
      '1.0.0+1 ',
      '1.0.0+1\n',
    ]) {
      test('rejects invalid version: $invalid', () {
        expect(
          () => ReleaseVersion.parse(invalid),
          throwsA(isA<FormatException>()),
        );
      });
    }
  });

  group('releaseCandidateId', () {
    test('generates deterministic candidate identity', () {
      final version = ReleaseVersion.parse('1.2.0+37');

      expect(version.releaseCandidateId(1), 'csp11-1.2.0-rc.1');
      expect(version.releaseCandidateId(7), 'csp11-1.2.0-rc.7');
    });

    test('rejects non-positive candidate ordinals', () {
      final version = ReleaseVersion.parse('1.2.0+37');

      expect(() => version.releaseCandidateId(0), throwsArgumentError);
      expect(() => version.releaseCandidateId(-1), throwsArgumentError);
    });
  });

  group('build progression', () {
    test('requires a strictly increasing build number', () {
      final previous = ReleaseVersion.parse('1.1.9+36');

      expect(
        ReleaseVersion.parse('1.2.0+37').isValidSuccessorOf(previous),
        isTrue,
      );
      expect(
        ReleaseVersion.parse('1.2.0+36').isValidSuccessorOf(previous),
        isFalse,
      );
      expect(
        ReleaseVersion.parse('2.0.0+35').isValidSuccessorOf(previous),
        isFalse,
      );
    });
  });

  test('supports value equality', () {
    expect(
      ReleaseVersion.parse('1.2.3+45'),
      ReleaseVersion.parse('1.2.3+45'),
    );
  });
}

class ReleaseVersion {
  const ReleaseVersion({
    required this.major,
    required this.minor,
    required this.patch,
    required this.buildNumber,
  });

  final int major;
  final int minor;
  final int patch;
  final int buildNumber;

  String get versionName => '$major.$minor.$patch';

  String get fullVersion => '$versionName+$buildNumber';

  static final RegExp _pattern = RegExp(
    r'^(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\.(0|[1-9][0-9]*)\+(0|[1-9][0-9]*)$',
  );

  static ReleaseVersion parse(String input) {
    final match = _pattern.firstMatch(input);
    if (match == null) {
      throw FormatException(
        'Invalid governed version. Expected MAJOR.MINOR.PATCH+BUILD.',
        input,
      );
    }

    return ReleaseVersion(
      major: int.parse(match.group(1)!),
      minor: int.parse(match.group(2)!),
      patch: int.parse(match.group(3)!),
      buildNumber: int.parse(match.group(4)!),
    );
  }

  String releaseCandidateId(int candidateOrdinal) {
    if (candidateOrdinal < 1) {
      throw ArgumentError.value(
        candidateOrdinal,
        'candidateOrdinal',
        'Release candidate ordinal must be at least 1.',
      );
    }

    return 'csp11-$versionName-rc.$candidateOrdinal';
  }

  bool isValidSuccessorOf(ReleaseVersion previous) {
    return buildNumber > previous.buildNumber;
  }

  @override
  bool operator ==(Object other) {
    return other is ReleaseVersion &&
        other.major == major &&
        other.minor == minor &&
        other.patch == patch &&
        other.buildNumber == buildNumber;
  }

  @override
  int get hashCode => Object.hash(major, minor, patch, buildNumber);

  @override
  String toString() => fullVersion;
}

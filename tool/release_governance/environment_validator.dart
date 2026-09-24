import 'dart:convert';
import 'dart:io';

import 'checksum_service.dart';

class EnvironmentCommandResult {
  const EnvironmentCommandResult({
    required this.exitCode,
    required this.stdout,
    required this.stderr,
  });

  final int exitCode;
  final String stdout;
  final String stderr;
}

typedef EnvironmentCommandRunner =
    Future<EnvironmentCommandResult> Function(
      String executable,
      List<String> arguments,
      String workingDirectory,
    );

class BuildEnvironmentSnapshot {
  const BuildEnvironmentSnapshot({
    required this.flutterVersion,
    required this.dartVersion,
    required this.javaVersion,
    required this.gradleVersion,
    required this.androidGradlePluginVersion,
    required this.kotlinVersion,
    required this.javaTargetVersion,
    required this.kotlinJvmTarget,
    required this.runnerOs,
    required this.runnerOsVersion,
    required this.runnerArchitecture,
    required this.pubspecYamlSha256,
    required this.pubspecLockSha256,
  });

  final String flutterVersion;
  final String dartVersion;
  final String javaVersion;
  final String gradleVersion;
  final String? androidGradlePluginVersion;
  final String? kotlinVersion;
  final String? javaTargetVersion;
  final String? kotlinJvmTarget;
  final String runnerOs;
  final String runnerOsVersion;
  final String runnerArchitecture;
  final String pubspecYamlSha256;
  final String pubspecLockSha256;

  Map<String, Object?> toJson() => <String, Object?>{
    'flutterVersion': flutterVersion,
    'dartVersion': dartVersion,
    'javaVersion': javaVersion,
    'gradleVersion': gradleVersion,
    'androidGradlePluginVersion': androidGradlePluginVersion,
    'kotlinVersion': kotlinVersion,
    'javaTargetVersion': javaTargetVersion,
    'kotlinJvmTarget': kotlinJvmTarget,
    'runnerOs': runnerOs,
    'runnerOsVersion': runnerOsVersion,
    'runnerArchitecture': runnerArchitecture,
    'pubspecYamlSha256': pubspecYamlSha256,
    'pubspecLockSha256': pubspecLockSha256,
  };
}

class BuildEnvironmentExpectation {
  const BuildEnvironmentExpectation({
    required this.flutterVersion,
    required this.dartVersion,
    required this.javaVersion,
    required this.gradleVersion,
    required this.runnerOs,
    required this.pubspecYamlSha256,
    required this.pubspecLockSha256,
    this.androidGradlePluginVersion,
    this.kotlinVersion,
    this.javaTargetVersion,
    this.kotlinJvmTarget,
    this.runnerOsVersion,
    this.runnerArchitecture,
  });

  factory BuildEnvironmentExpectation.exact(BuildEnvironmentSnapshot snapshot) {
    return BuildEnvironmentExpectation(
      flutterVersion: snapshot.flutterVersion,
      dartVersion: snapshot.dartVersion,
      javaVersion: snapshot.javaVersion,
      gradleVersion: snapshot.gradleVersion,
      androidGradlePluginVersion: snapshot.androidGradlePluginVersion,
      kotlinVersion: snapshot.kotlinVersion,
      javaTargetVersion: snapshot.javaTargetVersion,
      kotlinJvmTarget: snapshot.kotlinJvmTarget,
      runnerOs: snapshot.runnerOs,
      runnerOsVersion: snapshot.runnerOsVersion,
      runnerArchitecture: snapshot.runnerArchitecture,
      pubspecYamlSha256: snapshot.pubspecYamlSha256,
      pubspecLockSha256: snapshot.pubspecLockSha256,
    );
  }

  final String flutterVersion;
  final String dartVersion;
  final String javaVersion;
  final String gradleVersion;
  final String? androidGradlePluginVersion;
  final String? kotlinVersion;
  final String? javaTargetVersion;
  final String? kotlinJvmTarget;
  final String runnerOs;
  final String? runnerOsVersion;
  final String? runnerArchitecture;
  final String pubspecYamlSha256;
  final String pubspecLockSha256;
}

class BuildEnvironmentIssue {
  const BuildEnvironmentIssue({
    required this.code,
    required this.field,
    required this.message,
    this.expected,
    this.actual,
  });

  final String code;
  final String field;
  final String message;
  final String? expected;
  final String? actual;

  Map<String, Object?> toJson() => <String, Object?>{
    'code': code,
    'field': field,
    'expected': expected,
    'actual': actual,
    'message': message,
  };
}

class BuildEnvironmentValidationResult {
  const BuildEnvironmentValidationResult({required this.issues});

  final List<BuildEnvironmentIssue> issues;

  bool get pass => issues.isEmpty;

  Map<String, Object?> toJson() => <String, Object?>{
    'pass': pass,
    'blockingFailureCount': issues.length,
    'issues': issues.map((issue) => issue.toJson()).toList(),
  };
}

class BuildEnvironmentValidator {
  const BuildEnvironmentValidator();

  static final RegExp _sha256Pattern = RegExp(r'^[0-9a-f]{64}$');

  BuildEnvironmentValidationResult evaluate({
    required BuildEnvironmentExpectation expected,
    required BuildEnvironmentSnapshot actual,
  }) {
    final issues = <BuildEnvironmentIssue>[];

    _compare(
      issues,
      code: 'ENV001_FLUTTER_VERSION_DRIFT',
      field: 'flutterVersion',
      expected: expected.flutterVersion,
      actual: actual.flutterVersion,
    );
    _compare(
      issues,
      code: 'ENV002_DART_VERSION_DRIFT',
      field: 'dartVersion',
      expected: expected.dartVersion,
      actual: actual.dartVersion,
    );
    _compare(
      issues,
      code: 'ENV003_JAVA_VERSION_DRIFT',
      field: 'javaVersion',
      expected: expected.javaVersion,
      actual: actual.javaVersion,
    );
    _compare(
      issues,
      code: 'ENV004_GRADLE_VERSION_DRIFT',
      field: 'gradleVersion',
      expected: expected.gradleVersion,
      actual: actual.gradleVersion,
    );
    _compareOptional(
      issues,
      code: 'ENV005_ANDROID_GRADLE_PLUGIN_DRIFT',
      field: 'androidGradlePluginVersion',
      expected: expected.androidGradlePluginVersion,
      actual: actual.androidGradlePluginVersion,
    );
    _compareOptional(
      issues,
      code: 'ENV006_KOTLIN_VERSION_DRIFT',
      field: 'kotlinVersion',
      expected: expected.kotlinVersion,
      actual: actual.kotlinVersion,
    );
    _compareOptional(
      issues,
      code: 'ENV007_JAVA_TARGET_DRIFT',
      field: 'javaTargetVersion',
      expected: expected.javaTargetVersion,
      actual: actual.javaTargetVersion,
    );
    _compareOptional(
      issues,
      code: 'ENV008_KOTLIN_JVM_TARGET_DRIFT',
      field: 'kotlinJvmTarget',
      expected: expected.kotlinJvmTarget,
      actual: actual.kotlinJvmTarget,
    );
    _compare(
      issues,
      code: 'ENV009_RUNNER_OS_DRIFT',
      field: 'runnerOs',
      expected: expected.runnerOs,
      actual: actual.runnerOs,
    );
    _compareOptional(
      issues,
      code: 'ENV010_RUNNER_OS_VERSION_DRIFT',
      field: 'runnerOsVersion',
      expected: expected.runnerOsVersion,
      actual: actual.runnerOsVersion,
    );
    _compareOptional(
      issues,
      code: 'ENV011_RUNNER_ARCHITECTURE_DRIFT',
      field: 'runnerArchitecture',
      expected: expected.runnerArchitecture,
      actual: actual.runnerArchitecture,
    );

    if (!_sha256Pattern.hasMatch(actual.pubspecYamlSha256)) {
      issues.add(
        BuildEnvironmentIssue(
          code: 'ENV012_PUBSPEC_YAML_HASH_INVALID',
          field: 'pubspecYamlSha256',
          expected: expected.pubspecYamlSha256,
          actual: actual.pubspecYamlSha256,
          message: 'Actual pubspec.yaml SHA-256 is malformed.',
        ),
      );
    } else {
      _compare(
        issues,
        code: 'ENV013_PUBSPEC_YAML_DRIFT',
        field: 'pubspecYamlSha256',
        expected: expected.pubspecYamlSha256,
        actual: actual.pubspecYamlSha256,
      );
    }

    if (!_sha256Pattern.hasMatch(actual.pubspecLockSha256)) {
      issues.add(
        BuildEnvironmentIssue(
          code: 'ENV014_PUBSPEC_LOCK_HASH_INVALID',
          field: 'pubspecLockSha256',
          expected: expected.pubspecLockSha256,
          actual: actual.pubspecLockSha256,
          message: 'Actual pubspec.lock SHA-256 is malformed.',
        ),
      );
    } else {
      _compare(
        issues,
        code: 'ENV015_PUBSPEC_LOCK_DRIFT',
        field: 'pubspecLockSha256',
        expected: expected.pubspecLockSha256,
        actual: actual.pubspecLockSha256,
      );
    }

    issues.sort((left, right) => left.code.compareTo(right.code));
    return BuildEnvironmentValidationResult(
      issues: List<BuildEnvironmentIssue>.unmodifiable(issues),
    );
  }

  static void _compare(
    List<BuildEnvironmentIssue> issues, {
    required String code,
    required String field,
    required String expected,
    required String actual,
  }) {
    if (expected != actual) {
      issues.add(
        BuildEnvironmentIssue(
          code: code,
          field: field,
          expected: expected,
          actual: actual,
          message: 'Build environment value differs from the frozen value.',
        ),
      );
    }
  }

  static void _compareOptional(
    List<BuildEnvironmentIssue> issues, {
    required String code,
    required String field,
    required String? expected,
    required String? actual,
  }) {
    if (expected == null) {
      return;
    }

    if (actual != expected) {
      issues.add(
        BuildEnvironmentIssue(
          code: code,
          field: field,
          expected: expected,
          actual: actual,
          message: actual == null
              ? 'Required build environment value is missing.'
              : 'Build environment value differs from the frozen value.',
        ),
      );
    }
  }
}

class BuildEnvironmentInspector {
  BuildEnvironmentInspector({
    ChecksumService checksumService = const ChecksumService(),
    EnvironmentCommandRunner? commandRunner,
  }) : _checksumService = checksumService,
       _commandRunner = commandRunner ?? _runCommand;

  final ChecksumService _checksumService;
  final EnvironmentCommandRunner _commandRunner;

  Future<BuildEnvironmentSnapshot> inspect({String rootDirectory = '.'}) async {
    final flutter = await _requiredCommand('flutter', const <String>[
      '--version',
      '--machine',
    ], rootDirectory);
    final flutterInfo = parseFlutterMachine(flutter.stdout);

    final dart = await _requiredCommand('dart', const <String>[
      '--version',
    ], rootDirectory);
    final dartVersion = parseDartVersion('${dart.stdout}\n${dart.stderr}');
    if (dartVersion != flutterInfo.dartVersion) {
      throw StateError(
        'Flutter-reported Dart SDK does not match the active dart executable.',
      );
    }

    final java = await _requiredCommand('java', const <String>[
      '-version',
    ], rootDirectory);
    final javaVersion = parseJavaVersion('${java.stdout}\n${java.stderr}');

    final wrapper = await File(
      _path(rootDirectory, 'android/gradle/wrapper/gradle-wrapper.properties'),
    ).readAsString();
    final settings = await File(
      _path(rootDirectory, 'android/settings.gradle.kts'),
    ).readAsString();
    final appGradle = await File(
      _path(rootDirectory, 'android/app/build.gradle.kts'),
    ).readAsString();

    final pubspecYaml = File(_path(rootDirectory, 'pubspec.yaml'));
    final pubspecLock = File(_path(rootDirectory, 'pubspec.lock'));

    if (!pubspecYaml.existsSync()) {
      throw StateError('Required dependency file pubspec.yaml is missing.');
    }
    if (!pubspecLock.existsSync()) {
      throw StateError('Required dependency file pubspec.lock is missing.');
    }

    return BuildEnvironmentSnapshot(
      flutterVersion: flutterInfo.flutterVersion,
      dartVersion: dartVersion,
      javaVersion: javaVersion,
      gradleVersion: parseGradleWrapperVersion(wrapper),
      androidGradlePluginVersion: parsePluginVersion(
        settings,
        'com.android.application',
      ),
      kotlinVersion: parsePluginVersion(
        settings,
        'org.jetbrains.kotlin.android',
      ),
      javaTargetVersion: parseJavaTargetVersion(appGradle),
      kotlinJvmTarget: parseKotlinJvmTarget(appGradle),
      runnerOs: Platform.operatingSystem,
      runnerOsVersion: Platform.operatingSystemVersion,
      runnerArchitecture: await _runnerArchitecture(rootDirectory),
      pubspecYamlSha256: await _checksumService.sha256File(pubspecYaml),
      pubspecLockSha256: await _checksumService.sha256File(pubspecLock),
    );
  }

  static FlutterMachineVersion parseFlutterMachine(String raw) {
    final decoded = jsonDecode(raw) as Map<String, Object?>;
    final flutterVersion = decoded['frameworkVersion'];
    final dartVersion = decoded['dartSdkVersion'];

    if (flutterVersion is! String || flutterVersion.trim().isEmpty) {
      throw const FormatException(
        'Flutter machine output does not contain frameworkVersion.',
      );
    }
    if (dartVersion is! String || dartVersion.trim().isEmpty) {
      throw const FormatException(
        'Flutter machine output does not contain dartSdkVersion.',
      );
    }

    return FlutterMachineVersion(
      flutterVersion: flutterVersion.trim(),
      dartVersion: _normalizeVersionToken(dartVersion),
    );
  }

  static String parseDartVersion(String raw) {
    final match = RegExp(
      r'Dart SDK version:\s*([^\s]+)',
      caseSensitive: false,
    ).firstMatch(raw);
    if (match == null) {
      throw FormatException('Unable to parse Dart SDK version.', raw);
    }
    return _normalizeVersionToken(match.group(1)!);
  }

  static String parseJavaVersion(String raw) {
    final quoted = RegExp(r'version\s+"([^"]+)"').firstMatch(raw);
    if (quoted != null) {
      return quoted.group(1)!;
    }

    final openJdk = RegExp(
      r'openjdk\s+([^\s]+)',
      caseSensitive: false,
    ).firstMatch(raw);
    if (openJdk != null) {
      return openJdk.group(1)!.replaceAll('"', '');
    }

    throw FormatException('Unable to parse Java runtime version.', raw);
  }

  static String parseGradleWrapperVersion(String raw) {
    final match = RegExp(
      r'gradle-([0-9][A-Za-z0-9.+_-]*)-(?:all|bin)\.zip',
    ).firstMatch(raw);
    if (match == null) {
      throw FormatException(
        'Unable to parse Gradle wrapper distribution version.',
        raw,
      );
    }
    return match.group(1)!;
  }

  static String? parsePluginVersion(String raw, String pluginId) {
    final escapedId = RegExp.escape(pluginId);
    final match = RegExp(
      'id\\s*\\(?"$escapedId"\\)?\\s*version\\s*\\(?'
      '"([^"]+)"\\)?',
    ).firstMatch(raw);
    return match?.group(1);
  }

  static String? parseJavaTargetVersion(String raw) {
    final match = RegExp(
      r'targetCompatibility\s*=\s*JavaVersion\.VERSION_([0-9_]+)',
    ).firstMatch(raw);
    return match?.group(1)?.replaceAll('_', '.');
  }

  static String? parseKotlinJvmTarget(String raw) {
    final match = RegExp(r'JvmTarget\.JVM_([0-9_]+)').firstMatch(raw);
    return match?.group(1)?.replaceAll('_', '.');
  }

  Future<String> _runnerArchitecture(String rootDirectory) async {
    final environmentArchitecture =
        Platform.environment['RUNNER_ARCH'] ??
        Platform.environment['PROCESSOR_ARCHITECTURE'];

    if (environmentArchitecture != null &&
        environmentArchitecture.trim().isNotEmpty) {
      return environmentArchitecture.trim();
    }

    if (Platform.isWindows) {
      throw StateError('Unable to determine Windows runner architecture.');
    }

    final result = await _requiredCommand('uname', const <String>[
      '-m',
    ], rootDirectory);
    final architecture = result.stdout.trim();
    if (architecture.isEmpty) {
      throw StateError('Unable to determine runner architecture.');
    }
    return architecture;
  }

  Future<EnvironmentCommandResult> _requiredCommand(
    String executable,
    List<String> arguments,
    String workingDirectory,
  ) async {
    final result = await _commandRunner(
      executable,
      arguments,
      workingDirectory,
    );
    if (result.exitCode != 0) {
      throw StateError(
        'Required environment command failed: '
        '$executable ${arguments.join(' ')}',
      );
    }
    return result;
  }

  static Future<EnvironmentCommandResult> _runCommand(
    String executable,
    List<String> arguments,
    String workingDirectory,
  ) async {
    final result = await Process.run(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: false,
    );

    return EnvironmentCommandResult(
      exitCode: result.exitCode,
      stdout: result.stdout as String,
      stderr: result.stderr as String,
    );
  }

  static String _path(String rootDirectory, String relativePath) {
    final nativeRelative = relativePath.replaceAll('/', Platform.pathSeparator);
    return '${Directory(rootDirectory).absolute.path}'
        '${Platform.pathSeparator}$nativeRelative';
  }

  static String _normalizeVersionToken(String value) {
    return value.trim().split(' ').first;
  }
}

class FlutterMachineVersion {
  const FlutterMachineVersion({
    required this.flutterVersion,
    required this.dartVersion,
  });

  final String flutterVersion;
  final String dartVersion;
}

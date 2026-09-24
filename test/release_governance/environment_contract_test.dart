import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../tool/release_governance/checksum_service.dart';
import '../../tool/release_governance/environment_validator.dart';

void main() {
  group('BuildEnvironmentInspector parsers', () {
    test('parses Flutter machine output', () {
      final parsed = BuildEnvironmentInspector.parseFlutterMachine(
        '{"frameworkVersion":"3.44.9","dartSdkVersion":"3.12.2"}',
      );

      expect(parsed.flutterVersion, '3.44.9');
      expect(parsed.dartVersion, '3.12.2');
    });

    test('parses Dart SDK version output', () {
      expect(
        BuildEnvironmentInspector.parseDartVersion(
          'Dart SDK version: 3.12.2 (stable) on "linux_x64"',
        ),
        '3.12.2',
      );
    });

    test('parses Java runtime versions', () {
      expect(
        BuildEnvironmentInspector.parseJavaVersion(
          'openjdk version "17.0.16" 2025-07-15',
        ),
        '17.0.16',
      );
      expect(
        BuildEnvironmentInspector.parseJavaVersion(
          'openjdk 21.0.8 2025-07-15',
        ),
        '21.0.8',
      );
    });

    test('parses Gradle wrapper distribution', () {
      expect(
        BuildEnvironmentInspector.parseGradleWrapperVersion(
          'distributionUrl=https\\://services.gradle.org/distributions/'
          'gradle-9.1.0-all.zip',
        ),
        '9.1.0',
      );
    });

    test('parses Android Gradle Plugin and Kotlin plugin versions', () {
      const settings = '''
plugins {
    id("com.android.application") version "9.0.1" apply false
    id("org.jetbrains.kotlin.android") version "2.3.20" apply false
}
''';

      expect(
        BuildEnvironmentInspector.parsePluginVersion(
          settings,
          'com.android.application',
        ),
        '9.0.1',
      );
      expect(
        BuildEnvironmentInspector.parsePluginVersion(
          settings,
          'org.jetbrains.kotlin.android',
        ),
        '2.3.20',
      );
    });

    test('returns null when an optional plugin is absent', () {
      expect(
        BuildEnvironmentInspector.parsePluginVersion(
          'plugins {}',
          'org.jetbrains.kotlin.android',
        ),
        isNull,
      );
    });

    test('parses Java and Kotlin bytecode targets', () {
      const appGradle = '''
sourceCompatibility = JavaVersion.VERSION_17
targetCompatibility = JavaVersion.VERSION_17
jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
''';

      expect(
        BuildEnvironmentInspector.parseJavaTargetVersion(appGradle),
        '17',
      );
      expect(
        BuildEnvironmentInspector.parseKotlinJvmTarget(appGradle),
        '17',
      );
    });
  });

  group('BuildEnvironmentInspector integration', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('rel_gov_environment_');
      await Directory(
        '${root.path}/android/gradle/wrapper',
      ).create(recursive: true);
      await Directory(
        '${root.path}/android/app',
      ).create(recursive: true);

      await File(
        '${root.path}/android/gradle/wrapper/gradle-wrapper.properties',
      ).writeAsString(
        'distributionUrl=https\\://services.gradle.org/distributions/'
        'gradle-9.1.0-all.zip\n',
      );
      await File(
        '${root.path}/android/settings.gradle.kts',
      ).writeAsString(
        'plugins {\n'
        '  id("com.android.application") version "9.0.1" apply false\n'
        '  id("org.jetbrains.kotlin.android") version "2.3.20" apply false\n'
        '}\n',
      );
      await File(
        '${root.path}/android/app/build.gradle.kts',
      ).writeAsString(
        'targetCompatibility = JavaVersion.VERSION_17\n'
        'jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17\n',
      );
      await File(
        '${root.path}/pubspec.yaml',
      ).writeAsString('name: synthetic\n');
      await File(
        '${root.path}/pubspec.lock',
      ).writeAsString('packages: {}\n');
    });

    tearDown(() async {
      if (root.existsSync()) {
        await root.delete(recursive: true);
      }
    });

    test('captures versions and dependency file identities', () async {
      final inspector = BuildEnvironmentInspector(
        commandRunner: _fakeCommandRunner,
      );
      final snapshot = await inspector.inspect(rootDirectory: root.path);
      const checksums = ChecksumService();

      expect(snapshot.flutterVersion, '3.44.9');
      expect(snapshot.dartVersion, '3.12.2');
      expect(snapshot.javaVersion, '17.0.16');
      expect(snapshot.gradleVersion, '9.1.0');
      expect(snapshot.androidGradlePluginVersion, '9.0.1');
      expect(snapshot.kotlinVersion, '2.3.20');
      expect(snapshot.javaTargetVersion, '17');
      expect(snapshot.kotlinJvmTarget, '17');
      expect(snapshot.runnerOs, Platform.operatingSystem);
      expect(snapshot.runnerOsVersion, Platform.operatingSystemVersion);
      expect(snapshot.runnerArchitecture, isNotEmpty);
      expect(
        snapshot.pubspecYamlSha256,
        await checksums.sha256File(File('${root.path}/pubspec.yaml')),
      );
      expect(
        snapshot.pubspecLockSha256,
        await checksums.sha256File(File('${root.path}/pubspec.lock')),
      );
    });

    test('fails closed when Flutter and Dart disagree', () async {
      final inspector = BuildEnvironmentInspector(
        commandRunner: (
          String executable,
          List<String> arguments,
          String workingDirectory,
        ) async {
          if (executable == 'flutter') {
            return const EnvironmentCommandResult(
              exitCode: 0,
              stdout:
                  '{"frameworkVersion":"3.44.9",'
                  '"dartSdkVersion":"3.12.2"}',
              stderr: '',
            );
          }
          if (executable == 'dart') {
            return const EnvironmentCommandResult(
              exitCode: 0,
              stdout: '',
              stderr: 'Dart SDK version: 3.13.0 (stable)',
            );
          }
          return _fakeCommandRunner(executable, arguments, workingDirectory);
        },
      );

      expect(
        () => inspector.inspect(rootDirectory: root.path),
        throwsStateError,
      );
    });

    test('fails closed when pubspec.lock is missing', () async {
      await File('${root.path}/pubspec.lock').delete();
      final inspector = BuildEnvironmentInspector(
        commandRunner: _fakeCommandRunner,
      );

      expect(
        () => inspector.inspect(rootDirectory: root.path),
        throwsStateError,
      );
    });
  });

  group('BuildEnvironmentValidator', () {
    const validator = BuildEnvironmentValidator();

    test('passes an exact frozen environment', () {
      const actual = _snapshot;
      final expected = BuildEnvironmentExpectation.exact(actual);
      final result = validator.evaluate(expected: expected, actual: actual);

      expect(result.pass, isTrue);
      expect(result.issues, isEmpty);
    });

    test('blocks material toolchain drift', () {
      final expected = BuildEnvironmentExpectation.exact(_snapshot);
      const actual = BuildEnvironmentSnapshot(
        flutterVersion: '3.45.0',
        dartVersion: '3.13.0',
        javaVersion: '21.0.8',
        gradleVersion: '9.2.0',
        androidGradlePluginVersion: '9.1.0',
        kotlinVersion: '2.4.0',
        javaTargetVersion: '21',
        kotlinJvmTarget: '21',
        runnerOs: 'windows',
        runnerOsVersion: 'Windows 11',
        runnerArchitecture: 'ARM64',
        pubspecYamlSha256:
            'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
        pubspecLockSha256:
            'cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc',
      );

      final result = validator.evaluate(expected: expected, actual: actual);
      final codes = result.issues.map((issue) => issue.code).toList();

      expect(result.pass, isFalse);
      expect(codes, contains('ENV001_FLUTTER_VERSION_DRIFT'));
      expect(codes, contains('ENV002_DART_VERSION_DRIFT'));
      expect(codes, contains('ENV003_JAVA_VERSION_DRIFT'));
      expect(codes, contains('ENV004_GRADLE_VERSION_DRIFT'));
      expect(codes, contains('ENV005_ANDROID_GRADLE_PLUGIN_DRIFT'));
      expect(codes, contains('ENV006_KOTLIN_VERSION_DRIFT'));
      expect(codes, contains('ENV007_JAVA_TARGET_DRIFT'));
      expect(codes, contains('ENV008_KOTLIN_JVM_TARGET_DRIFT'));
      expect(codes, contains('ENV009_RUNNER_OS_DRIFT'));
      expect(codes, contains('ENV010_RUNNER_OS_VERSION_DRIFT'));
      expect(codes, contains('ENV011_RUNNER_ARCHITECTURE_DRIFT'));
      expect(codes, contains('ENV013_PUBSPEC_YAML_DRIFT'));
      expect(codes, contains('ENV015_PUBSPEC_LOCK_DRIFT'));
    });

    test('blocks missing expected Android plugin evidence', () {
      final expected = BuildEnvironmentExpectation.exact(_snapshot);
      const actual = BuildEnvironmentSnapshot(
        flutterVersion: '3.44.9',
        dartVersion: '3.12.2',
        javaVersion: '17.0.16',
        gradleVersion: '9.1.0',
        androidGradlePluginVersion: null,
        kotlinVersion: null,
        javaTargetVersion: null,
        kotlinJvmTarget: null,
        runnerOs: 'linux',
        runnerOsVersion: 'Ubuntu 24.04',
        runnerArchitecture: 'X64',
        pubspecYamlSha256:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        pubspecLockSha256:
            'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
      );

      final result = validator.evaluate(expected: expected, actual: actual);
      final codes = result.issues.map((issue) => issue.code).toList();

      expect(codes, contains('ENV005_ANDROID_GRADLE_PLUGIN_DRIFT'));
      expect(codes, contains('ENV006_KOTLIN_VERSION_DRIFT'));
      expect(codes, contains('ENV007_JAVA_TARGET_DRIFT'));
      expect(codes, contains('ENV008_KOTLIN_JVM_TARGET_DRIFT'));
    });

    test('allows runner version and architecture to be intentionally unpinned', () {
      const expected = BuildEnvironmentExpectation(
        flutterVersion: '3.44.9',
        dartVersion: '3.12.2',
        javaVersion: '17.0.16',
        gradleVersion: '9.1.0',
        androidGradlePluginVersion: '9.0.1',
        kotlinVersion: '2.3.20',
        javaTargetVersion: '17',
        kotlinJvmTarget: '17',
        runnerOs: 'linux',
        pubspecYamlSha256:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        pubspecLockSha256:
            'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
      );

      final result = validator.evaluate(
        expected: expected,
        actual: _snapshot,
      );

      expect(result.pass, isTrue);
    });

    test('blocks malformed dependency hashes', () {
      final expected = BuildEnvironmentExpectation.exact(_snapshot);
      const actual = BuildEnvironmentSnapshot(
        flutterVersion: '3.44.9',
        dartVersion: '3.12.2',
        javaVersion: '17.0.16',
        gradleVersion: '9.1.0',
        androidGradlePluginVersion: '9.0.1',
        kotlinVersion: '2.3.20',
        javaTargetVersion: '17',
        kotlinJvmTarget: '17',
        runnerOs: 'linux',
        runnerOsVersion: 'Ubuntu 24.04',
        runnerArchitecture: 'X64',
        pubspecYamlSha256: 'bad',
        pubspecLockSha256: 'also-bad',
      );

      final result = validator.evaluate(expected: expected, actual: actual);
      final codes = result.issues.map((issue) => issue.code).toList();

      expect(codes, contains('ENV012_PUBSPEC_YAML_HASH_INVALID'));
      expect(codes, contains('ENV014_PUBSPEC_LOCK_HASH_INVALID'));
    });
  });
}

Future<EnvironmentCommandResult> _fakeCommandRunner(
  String executable,
  List<String> arguments,
  String workingDirectory,
) async {
  if (executable == 'flutter') {
    return const EnvironmentCommandResult(
      exitCode: 0,
      stdout:
          '{"frameworkVersion":"3.44.9",'
          '"dartSdkVersion":"3.12.2"}',
      stderr: '',
    );
  }
  if (executable == 'dart') {
    return const EnvironmentCommandResult(
      exitCode: 0,
      stdout: '',
      stderr: 'Dart SDK version: 3.12.2 (stable) on "linux_x64"',
    );
  }
  if (executable == 'java') {
    return const EnvironmentCommandResult(
      exitCode: 0,
      stdout: '',
      stderr: 'openjdk version "17.0.16" 2025-07-15',
    );
  }
  if (executable == 'uname') {
    return const EnvironmentCommandResult(
      exitCode: 0,
      stdout: 'x86_64\n',
      stderr: '',
    );
  }

  return const EnvironmentCommandResult(
    exitCode: 127,
    stdout: '',
    stderr: 'not found',
  );
}

const BuildEnvironmentSnapshot _snapshot = BuildEnvironmentSnapshot(
  flutterVersion: '3.44.9',
  dartVersion: '3.12.2',
  javaVersion: '17.0.16',
  gradleVersion: '9.1.0',
  androidGradlePluginVersion: '9.0.1',
  kotlinVersion: '2.3.20',
  javaTargetVersion: '17',
  kotlinJvmTarget: '17',
  runnerOs: 'linux',
  runnerOsVersion: 'Ubuntu 24.04',
  runnerArchitecture: 'X64',
  pubspecYamlSha256:
      'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
  pubspecLockSha256:
      'dddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd',
);

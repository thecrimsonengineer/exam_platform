# CSP11 REL-GOV-6 Build Environment Contract

Status: IMPLEMENTED CANDIDATE
Phase: REL-GOV-6
Repository: thecrimsonengineer/exam_platform
Base checkpoint: phase-rel-gov5-artifact-integrity-closed
Base commit: 25123c97c8d9daef904ab1d52e8f4f7e7604e736
Date: 2026-09-24

## 1. Purpose

REL-GOV-6 makes the build environment part of governed release evidence.

A candidate cannot be treated as reproducibly identified by source and artifacts alone. The toolchain and dependency inputs that produced those artifacts must also be recorded and checked for material drift.

## 2. Captured environment identity

The canonical environment snapshot captures:

```
flutterVersion
dartVersion
javaVersion
gradleVersion
androidGradlePluginVersion
kotlinVersion
javaTargetVersion
kotlinJvmTarget
runnerOs
runnerOsVersion
runnerArchitecture
pubspecYamlSha256
pubspecLockSha256
```

The repository currently declares:

```
Flutter CI pin            3.44.9
Gradle                    9.1.0
Android Gradle Plugin     9.0.1
Kotlin Android plugin     2.3.20
Java source/target        17
Kotlin JVM target         17
```

Runtime Dart and Java are captured from the active executables rather than inferred from source configuration.

## 3. Evidence sources

REL-GOV-6 derives environment evidence from:

```
flutter --version --machine
dart --version
java -version
android/gradle/wrapper/gradle-wrapper.properties
android/settings.gradle.kts
android/app/build.gradle.kts
Platform.operatingSystem
Platform.operatingSystemVersion
runner architecture
pubspec.yaml bytes
pubspec.lock bytes
```

The dependency file identities use the REL-GOV-5 SHA-256 service.

## 4. Fail-closed discovery

The inspector blocks environment capture when required evidence cannot be obtained.

Examples include:

- Flutter command failure
- Dart command failure
- Java command failure
- Flutter-reported Dart SDK differing from the active Dart executable
- malformed Gradle wrapper identity
- missing pubspec.yaml
- missing pubspec.lock
- unreadable required environment files
- undetectable runner architecture

Unknown is not silently converted into PASS.

## 5. Android toolchain discovery

Android Gradle Plugin and Kotlin versions are discovered from the plugin declarations in:

```
android/settings.gradle.kts
```

Java target and Kotlin JVM target are discovered from:

```
android/app/build.gradle.kts
```

These fields are nullable in the generic data model because REL-GOV may later validate a non-Android component. For CSP11 Android candidates they are expected and therefore become blocking when the frozen expectation contains them.

## 6. Frozen expectation model

A BuildEnvironmentExpectation contains required exact values for:

```
Flutter
Dart
Java runtime
Gradle
runner OS
pubspec.yaml SHA-256
pubspec.lock SHA-256
```

It may additionally pin:

```
Android Gradle Plugin
Kotlin
Java target
Kotlin JVM target
runner OS version
runner architecture
```

BuildEnvironmentExpectation.exact(snapshot) freezes every captured field.

Runner OS version and architecture can be intentionally left unpinned when a release policy wishes to permit patch-level hosted-runner movement while still pinning the OS family and toolchain. That relaxation must be explicit.

## 7. Material drift

Unexpected differences are blocking.

REL-GOV-6 defines:

```
ENV001_FLUTTER_VERSION_DRIFT
ENV002_DART_VERSION_DRIFT
ENV003_JAVA_VERSION_DRIFT
ENV004_GRADLE_VERSION_DRIFT
ENV005_ANDROID_GRADLE_PLUGIN_DRIFT
ENV006_KOTLIN_VERSION_DRIFT
ENV007_JAVA_TARGET_DRIFT
ENV008_KOTLIN_JVM_TARGET_DRIFT
ENV009_RUNNER_OS_DRIFT
ENV010_RUNNER_OS_VERSION_DRIFT
ENV011_RUNNER_ARCHITECTURE_DRIFT
ENV012_PUBSPEC_YAML_HASH_INVALID
ENV013_PUBSPEC_YAML_DRIFT
ENV014_PUBSPEC_LOCK_HASH_INVALID
ENV015_PUBSPEC_LOCK_DRIFT
```

All emitted REL-GOV-6 issues are blocking.

## 8. Dependency identity

The dependency contract does not trust package names alone.

It freezes the exact bytes of:

```
pubspec.yaml
pubspec.lock
```

using SHA-256.

This allows the release process to detect:

- dependency declaration edits
- lockfile regeneration
- transitive version drift
- source changes
- checksum changes
- dependency substitution

## 9. Flutter and Dart consistency

Flutter machine output includes the Dart SDK version bundled with Flutter.

REL-GOV-6 independently executes Dart and compares the active Dart SDK version.

If they disagree, environment capture fails before admission evidence is generated.

This prevents a mixed PATH/toolchain state from being represented as a coherent candidate environment.

## 10. Admission integration

REL-GOV-4 already reserves:

```
RG005 dependency_lock
RG006 environment_valid
```

REL-GOV-6 provides deterministic evidence for those gates.

REL-GOV-6 does not modify or weaken the admission engine.

## 11. Phase boundary

REL-GOV-6 owns:

- environment discovery
- environment snapshot serialization
- environment expectation model
- exact drift comparison
- dependency-file SHA-256 identity
- Flutter/Dart consistency check
- Android toolchain version discovery

REL-GOV-6 does not yet own:

- final evidence-package layout
- release-governance CLI
- release-candidate GitHub workflow
- artifact building
- rollback execution
- public publication

Those remain in later frozen REL-GOV phases.

## 12. Exit criteria

REL-GOV-6 may close only when:

```
base checkpoint exact
build environment contract present
environment inspector present
environment validator present
Flutter/Dart consistency test green
Gradle discovery green
AGP discovery green
Kotlin discovery green
Java target discovery green
dependency hash identity green
material drift tests green
missing evidence tests green
format green
analyzer green
full REL-GOV regression green
repository diff limited to REL-GOV-6
blocking implementation failures = 0
```

Closure checkpoint:

```
phase-rel-gov6-build-environment-closed
```

Next frozen phase:

```
REL-GOV-7 -> Evidence Generator and CLI
```

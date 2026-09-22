import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('INT-R4 dependencies assets and platform wiring', () {
    test(
      'Startup dependencies and asset registration are frozen exactly once',
      () {
        final pubspec = File('pubspec.yaml').readAsStringSync();

        expect(_occurrences(pubspec, '  lottie: ^3.6.1'), 1);
        expect(_occurrences(pubspec, '  flutter_animate: ^4.5.2'), 1);
        expect(_occurrences(pubspec, '    - assets/startup/'), 1);

        expect(
          pubspec,
          contains('    - assets/learning_twin/'),
          reason: 'Startup integration must preserve existing learner assets.',
        );
        expect(
          pubspec,
          contains('    - assets/learning_twin/candidates/'),
          reason:
              'Startup integration must preserve existing candidate assets.',
        );
      },
    );

    test('lockfile resolves both frozen Startup direct dependencies', () {
      final lock = File('pubspec.lock').readAsStringSync();

      expect(lock, contains('  lottie:'));
      expect(lock, contains('    dependency: "direct main"'));
      expect(lock, contains('    version: "3.6.1"'));

      final flutterAnimateSection = _packageSection(lock, 'flutter_animate');
      expect(flutterAnimateSection, contains('dependency: "direct main"'));
      expect(flutterAnimateSection, contains('version: "4.5.2"'));

      final lottieSection = _packageSection(lock, 'lottie');
      expect(lottieSection, contains('dependency: "direct main"'));
      expect(lottieSection, contains('version: "3.6.1"'));
    });

    test('Startup Lottie asset preserves frozen production contract', () {
      final file = File('assets/startup/csp11_startup_master.json');

      expect(file.existsSync(), isTrue);

      final decoded =
          jsonDecode(file.readAsStringSync()) as Map<String, dynamic>;

      expect(decoded['nm'], 'CSP11 Startup Master SM-1');
      expect(decoded['w'], 512);
      expect(decoded['h'], 512);
      expect(decoded['fr'], 30);
      expect(decoded['ip'], 0);
      expect(decoded['op'], 144);
      expect(decoded['assets'], isEmpty);

      final markers = (decoded['markers'] as List<dynamic>)
          .cast<Map<String, dynamic>>()
          .map((marker) => marker['cm'])
          .toSet();

      expect(
        markers,
        containsAll(<String>{
          'ignite',
          'learn',
          'practice',
          'lab',
          'remember',
          'converge',
        }),
      );
    });

    test('Android remains wired through Flutter asset packaging', () {
      final gradle = File('android/app/build.gradle.kts').readAsStringSync();

      expect(gradle, contains('id("dev.flutter.flutter-gradle-plugin")'));
      expect(gradle, contains('flutter {'));
      expect(gradle, contains('source = "../.."'));

      // Frozen SM-5 boundary: R4 proves packaging, not Play Store signing.
      expect(
        gradle,
        contains('signingConfig = signingConfigs.getByName("debug")'),
      );
    });

    test('Web remains wired through the Flutter bootstrap loader', () {
      final index = File('web/index.html').readAsStringSync();

      expect(index, contains(r'<base href="$FLUTTER_BASE_HREF">'));
      expect(index, contains('flutter_bootstrap.js'));
    });

    test('Windows installation copies the generated Flutter asset bundle', () {
      final cmake = File('windows/CMakeLists.txt').readAsStringSync();

      expect(cmake, contains('set(FLUTTER_ASSET_DIR_NAME "flutter_assets")'));
      expect(
        cmake,
        contains(
          r'install(DIRECTORY "${PROJECT_BUILD_DIR}/${FLUTTER_ASSET_DIR_NAME}"',
        ),
      );
    });

    test('Startup runtime references the same registered production asset', () {
      final startup = File(
        'lib/screens/startup/csp11_startup_screen.dart',
      ).readAsStringSync();

      expect(
        startup,
        contains(
          "this.startupAssetPath = "
          "'assets/startup/csp11_startup_master.json'",
        ),
      );
      expect(startup, contains('Lottie.asset('));
    });
  });
}

String _packageSection(String lock, String packageName) {
  final marker = '  $packageName:\n';
  final start = lock.indexOf(marker);

  if (start < 0) {
    return '';
  }

  final next = lock.indexOf('\n  ', start + marker.length);
  return next < 0 ? lock.substring(start) : lock.substring(start, next);
}

int _occurrences(String source, String needle) {
  if (needle.isEmpty) {
    return 0;
  }

  var count = 0;
  var start = 0;

  while (true) {
    final index = source.indexOf(needle, start);
    if (index < 0) {
      return count;
    }
    count += 1;
    start = index + needle.length;
  }
}

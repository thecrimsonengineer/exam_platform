import 'dart:convert';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('M1.5 twin manifest exists and is frozen', () async {
    final manifestText = await rootBundle.loadString(
      'assets/learning_twin/twin_manifest.json',
    );
    final manifest = jsonDecode(manifestText) as Map<String, dynamic>;

    expect(manifest['phase'], 'M1.5');
    expect(manifest['approved_from_phase'], 'M1.4');
    expect(manifest['canonical_identity_frozen'], isTrue);
    expect(manifest['default_state'], 'default');
    expect(manifest['asset_type'], 'raster_backed_svg');

    final states = manifest['states'] as Map<String, dynamic>;
    expect(
      states.keys,
      containsAll(<String>['default', 'explain', 'success', 'hero']),
    );

    for (final key in states.keys) {
      final state = states[key] as Map<String, dynamic>;
      final svgPath = state['svg_path'] as String;
      expect(
        File(svgPath).existsSync(),
        isTrue,
        reason: 'Missing canonical asset for $key',
      );
    }
  });

  test('M1.5 twin metadata points to the canonical asset family', () async {
    final metadataText = await rootBundle.loadString(
      'assets/learning_twin/naveed_twin.json',
    );
    final metadata = jsonDecode(metadataText) as Map<String, dynamic>;

    expect(metadata['twin_id'], 'naveed_learning_guide');
    expect(metadata['canonical_identity_frozen'], isTrue);
    expect(metadata['default_asset'], 'assets/learning_twin/naveed_twin.svg');

    final states = metadata['states'] as Map<String, dynamic>;
    expect(
      (states['default'] as Map<String, dynamic>)['svg_path'],
      'assets/learning_twin/naveed_twin.svg',
    );
    expect(
      (states['explain'] as Map<String, dynamic>)['svg_path'],
      'assets/learning_twin/naveed_twin_explain.svg',
    );
    expect(
      (states['success'] as Map<String, dynamic>)['svg_path'],
      'assets/learning_twin/naveed_twin_success.svg',
    );
    expect(
      (states['hero'] as Map<String, dynamic>)['svg_path'],
      'assets/learning_twin/naveed_twin_fullbody.svg',
    );
  });

  test(
    'Phase M freeze remains isolated from production entry points',
    () async {
      final main = await File('lib/main.dart').readAsString();
      final navigation = await File(
        'lib/screens/navigation/bottom_navigation.dart',
      ).readAsString();

      expect(main, isNot(contains('twin_identity_studio')));
      expect(navigation, isNot(contains('twin_identity_studio')));
    },
  );
}

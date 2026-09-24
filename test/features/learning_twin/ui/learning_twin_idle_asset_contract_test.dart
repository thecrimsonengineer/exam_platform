import 'package:exam_platform/features/learning_twin/ui/learning_twin_idle_asset_contract.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Map<String, dynamic> validIdle() {
    return <String, dynamic>{
      'v': '5.12.2',
      'fr': 30,
      'ip': 0,
      'op': 180,
      'w': 1024,
      'h': 1024,
      'assets': <Object>[],
      'layers': <Object>[
        <String, dynamic>{
          'ty': 4,
          'nm': 'body_root',
          'ks': <String, dynamic>{},
        },
      ],
    };
  }

  test('accepts the frozen LTAM-2 vector idle contract', () {
    final result = LearningTwinIdleAssetContract.validateMap(validIdle());

    expect(result.isValid, isTrue);
    expect(result.errors, isEmpty);
  });

  test('rejects wrong frame rate and duration', () {
    final candidate = validIdle()
      ..['fr'] = 60
      ..['op'] = 120;

    final result = LearningTwinIdleAssetContract.validateMap(candidate);

    expect(result.isValid, isFalse);
    expect(result.errors, contains('frame_rate_must_be_30'));
    expect(result.errors, contains('out_point_must_be_180'));
    expect(result.errors, contains('duration_must_be_6_seconds'));
  });

  test('rejects text layers', () {
    final candidate = validIdle();
    candidate['layers'] = <Object>[
      <String, dynamic>{'ty': 5, 'nm': 'learner_text'},
    ];

    final result = LearningTwinIdleAssetContract.validateMap(candidate);

    expect(result.isValid, isFalse);
    expect(result.errors, contains('text_layers_forbidden'));
  });

  test('rejects remote references', () {
    final candidate = validIdle();
    candidate['assets'] = <Object>[
      <String, dynamic>{'id': 'external', 'u': 'https://example.com/'},
    ];

    final result = LearningTwinIdleAssetContract.validateMap(candidate);

    expect(result.isValid, isFalse);
    expect(result.errors, contains('remote_references_forbidden'));
  });

  test('rejects raster and embedded image assets', () {
    final raster = validIdle();
    raster['assets'] = <Object>[
      <String, dynamic>{'id': 'image_0', 'p': 'avatar.png'},
    ];

    final embedded = validIdle();
    embedded['assets'] = <Object>[
      <String, dynamic>{'id': 'image_0', 'e': 1},
    ];

    expect(
      LearningTwinIdleAssetContract.validateMap(raster).errors,
      contains('raster_assets_forbidden'),
    );
    expect(
      LearningTwinIdleAssetContract.validateMap(embedded).errors,
      contains('raster_assets_forbidden'),
    );
  });

  test('rejects invalid JSON', () {
    final result = LearningTwinIdleAssetContract.validateJson('{not-json}');

    expect(result.isValid, isFalse);
    expect(result.errors, contains('invalid_json'));
  });
}

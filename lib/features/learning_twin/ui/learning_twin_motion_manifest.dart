import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'learning_twin_motion_descriptor.dart';
import 'learning_twin_motion_error.dart';
import 'learning_twin_motion_state.dart';

final class LearningTwinMotionManifest {
  LearningTwinMotionManifest._({
    required this.schemaVersion,
    required this.twinId,
    required this.defaultState,
    required Map<LearningTwinMotionState, LearningTwinMotionDescriptor>
    descriptors,
  }) : descriptors = Map.unmodifiable(descriptors);

  static const int supportedSchemaVersion = 1;
  static const String canonicalTwinId = 'naveed_learning_guide';
  static const String assetPath =
      'assets/learning_twin/manifest/twin_motion_manifest.json';

  final int schemaVersion;
  final String twinId;
  final LearningTwinMotionState defaultState;
  final Map<LearningTwinMotionState, LearningTwinMotionDescriptor> descriptors;

  LearningTwinMotionDescriptor? descriptorFor(LearningTwinMotionState state) =>
      descriptors[state];

  static LearningTwinMotionManifestResult parse(String raw) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return const LearningTwinMotionManifestResult.invalid(
          LearningTwinMotionFailure(
            LearningTwinMotionErrorCode.malformedJson,
            'Manifest root must be an object.',
          ),
        );
      }

      final schemaVersion = decoded['schema_version'];
      if (schemaVersion != supportedSchemaVersion) {
        return LearningTwinMotionManifestResult.invalid(
          LearningTwinMotionFailure(
            LearningTwinMotionErrorCode.unsupportedSchema,
            'Unsupported schema_version: $schemaVersion.',
          ),
        );
      }

      final twinId = decoded['twin_id'];
      if (twinId != canonicalTwinId) {
        return LearningTwinMotionManifestResult.invalid(
          LearningTwinMotionFailure(
            LearningTwinMotionErrorCode.invalidTwinId,
            'Unexpected twin_id: $twinId.',
          ),
        );
      }

      final statesRaw = decoded['states'];
      if (statesRaw is! Map<String, dynamic>) {
        return const LearningTwinMotionManifestResult.invalid(
          LearningTwinMotionFailure(
            LearningTwinMotionErrorCode.invalidDescriptor,
            'states must be an object.',
          ),
        );
      }

      for (final state in canonicalLearningTwinMotionStates) {
        final key = state.manifestKey;
        final count = RegExp(
          '"${RegExp.escape(key)}"\\s*:',
        ).allMatches(raw).length;
        if (count > 1) {
          return LearningTwinMotionManifestResult.invalid(
            LearningTwinMotionFailure(
              LearningTwinMotionErrorCode.duplicateState,
              'Duplicate state key: $key.',
            ),
          );
        }
        if (!statesRaw.containsKey(key)) {
          return LearningTwinMotionManifestResult.invalid(
            LearningTwinMotionFailure(
              LearningTwinMotionErrorCode.missingCanonicalState,
              'Missing canonical state: $key.',
            ),
          );
        }
      }

      for (final key in statesRaw.keys) {
        if (learningTwinMotionStateFromManifestKey(key) == null) {
          return LearningTwinMotionManifestResult.invalid(
            LearningTwinMotionFailure(
              LearningTwinMotionErrorCode.unsupportedState,
              'Unsupported manifest state: $key.',
            ),
          );
        }
      }

      final defaultStateRaw = decoded['default_state'];
      if (defaultStateRaw is! String) {
        return const LearningTwinMotionManifestResult.invalid(
          LearningTwinMotionFailure(
            LearningTwinMotionErrorCode.invalidDefaultState,
            'default_state must be a string.',
          ),
        );
      }
      final defaultState = learningTwinMotionStateFromManifestKey(
        defaultStateRaw,
      );
      if (defaultState == null || !statesRaw.containsKey(defaultStateRaw)) {
        return LearningTwinMotionManifestResult.invalid(
          LearningTwinMotionFailure(
            LearningTwinMotionErrorCode.invalidDefaultState,
            'Invalid default_state: $defaultStateRaw.',
          ),
        );
      }

      final descriptors =
          <LearningTwinMotionState, LearningTwinMotionDescriptor>{};

      for (final state in canonicalLearningTwinMotionStates) {
        final value = statesRaw[state.manifestKey];
        if (value is! Map<String, dynamic>) {
          return LearningTwinMotionManifestResult.invalid(
            LearningTwinMotionFailure(
              LearningTwinMotionErrorCode.invalidDescriptor,
              'Descriptor for ${state.manifestKey} must be an object.',
            ),
          );
        }

        final asset = value['asset'];
        final fallback = value['fallback'];
        final loop = value['loop'];
        final durationMs = value['duration_ms'];
        final priority = value['priority'];
        final intensity = value['motion_intensity'];

        if (asset is! String ||
            fallback is! String ||
            loop is! bool ||
            durationMs is! int ||
            durationMs <= 0 ||
            priority is! int ||
            priority < 0 ||
            intensity is! int ||
            intensity < 0 ||
            intensity > 3) {
          return LearningTwinMotionManifestResult.invalid(
            LearningTwinMotionFailure(
              LearningTwinMotionErrorCode.invalidDescriptor,
              'Invalid descriptor values for ${state.manifestKey}.',
            ),
          );
        }

        final assetFailure = _validatePath(asset, requireJson: true);
        if (assetFailure != null) {
          return LearningTwinMotionManifestResult.invalid(assetFailure);
        }

        final fallbackFailure = _validatePath(fallback, requireJson: false);
        if (fallbackFailure != null) {
          return LearningTwinMotionManifestResult.invalid(fallbackFailure);
        }

        if (priority != state.defaultPriority) {
          return LearningTwinMotionManifestResult.invalid(
            LearningTwinMotionFailure(
              LearningTwinMotionErrorCode.invalidDescriptor,
              'Priority drift for ${state.manifestKey}: $priority.',
            ),
          );
        }

        descriptors[state] = LearningTwinMotionDescriptor(
          state: state,
          assetPath: asset,
          fallbackSvgPath: fallback,
          loop: loop,
          duration: Duration(milliseconds: durationMs),
          priority: priority,
          motionIntensity: intensity,
        );
      }

      return LearningTwinMotionManifestResult.valid(
        LearningTwinMotionManifest._(
          schemaVersion: schemaVersion,
          twinId: twinId as String,
          defaultState: defaultState,
          descriptors: descriptors,
        ),
      );
    } on FormatException catch (error) {
      return LearningTwinMotionManifestResult.invalid(
        LearningTwinMotionFailure(
          LearningTwinMotionErrorCode.malformedJson,
          error.message,
        ),
      );
    } catch (error) {
      return LearningTwinMotionManifestResult.invalid(
        LearningTwinMotionFailure(
          LearningTwinMotionErrorCode.malformedJson,
          error.toString(),
        ),
      );
    }
  }

  static LearningTwinMotionFailure? _validatePath(
    String value, {
    required bool requireJson,
  }) {
    final normalized = value.trim().toLowerCase();
    if (normalized.startsWith('http://') ||
        normalized.startsWith('https://') ||
        normalized.contains('://')) {
      return LearningTwinMotionFailure(
        LearningTwinMotionErrorCode.remoteAssetPath,
        'Remote asset paths are not allowed: $value.',
      );
    }

    if (value.contains('..') || value.contains('\\')) {
      return LearningTwinMotionFailure(
        LearningTwinMotionErrorCode.pathTraversal,
        'Unsafe asset path: $value.',
      );
    }

    if (!value.startsWith('assets/learning_twin/')) {
      return LearningTwinMotionFailure(
        LearningTwinMotionErrorCode.invalidDescriptor,
        'Asset must remain inside assets/learning_twin/: $value.',
      );
    }

    if (requireJson && !normalized.endsWith('.json')) {
      return LearningTwinMotionFailure(
        LearningTwinMotionErrorCode.invalidDescriptor,
        'Motion asset must be JSON: $value.',
      );
    }

    if (!requireJson && !normalized.endsWith('.svg')) {
      return LearningTwinMotionFailure(
        LearningTwinMotionErrorCode.invalidDescriptor,
        'Fallback asset must be SVG: $value.',
      );
    }

    return null;
  }
}

final class LearningTwinMotionManifestResult {
  const LearningTwinMotionManifestResult.valid(this.manifest) : failure = null;

  const LearningTwinMotionManifestResult.invalid(this.failure)
    : manifest = null;

  final LearningTwinMotionManifest? manifest;
  final LearningTwinMotionFailure? failure;

  bool get isValid => manifest != null && failure == null;
}

final class LearningTwinMotionManifestLoader {
  const LearningTwinMotionManifestLoader({AssetBundle? bundle})
    : _bundle = bundle;

  final AssetBundle? _bundle;

  static Future<LearningTwinMotionManifestResult>? _rootBundleCache;

  Future<LearningTwinMotionManifestResult> load() {
    final bundle = _bundle;
    if (bundle != null) {
      return _loadFrom(bundle);
    }

    return _rootBundleCache ??= _loadFrom(rootBundle);
  }

  Future<LearningTwinMotionManifestResult> _loadFrom(AssetBundle bundle) async {
    try {
      final raw = await bundle.loadString(LearningTwinMotionManifest.assetPath);
      return LearningTwinMotionManifest.parse(raw);
    } catch (error) {
      return LearningTwinMotionManifestResult.invalid(
        LearningTwinMotionFailure(
          LearningTwinMotionErrorCode.manifestMissing,
          error.toString(),
        ),
      );
    }
  }

  @visibleForTesting
  static void clearCacheForTesting() {
    _rootBundleCache = null;
  }
}

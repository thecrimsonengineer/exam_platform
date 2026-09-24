import 'dart:convert';

class LearningTwinIdleAssetValidation {
  const LearningTwinIdleAssetValidation._({
    required this.isValid,
    required this.errors,
  });

  factory LearningTwinIdleAssetValidation.valid() {
    return const LearningTwinIdleAssetValidation._(
      isValid: true,
      errors: <String>[],
    );
  }

  factory LearningTwinIdleAssetValidation.invalid(List<String> errors) {
    return LearningTwinIdleAssetValidation._(
      isValid: false,
      errors: List<String>.unmodifiable(errors),
    );
  }

  final bool isValid;
  final List<String> errors;
}

abstract final class LearningTwinIdleAssetContract {
  static const String canonicalPath =
      'assets/learning_twin/motion/twin_idle.json';
  static const double frameRate = 30;
  static const double inPoint = 0;
  static const double outPoint = 180;
  static const double durationSeconds = 6;

  static LearningTwinIdleAssetValidation validateJson(String source) {
    final dynamic decoded;
    try {
      decoded = jsonDecode(source);
    } on FormatException {
      return LearningTwinIdleAssetValidation.invalid(
        const <String>['invalid_json'],
      );
    }

    if (decoded is! Map<String, dynamic>) {
      return LearningTwinIdleAssetValidation.invalid(
        const <String>['root_not_object'],
      );
    }

    return validateMap(decoded);
  }

  static LearningTwinIdleAssetValidation validateMap(
    Map<String, dynamic> root,
  ) {
    final errors = <String>[];

    final version = root['v'];
    if (version is! String || version.trim().isEmpty) {
      errors.add('missing_lottie_version');
    }

    final fr = _number(root['fr']);
    final ip = _number(root['ip']);
    final op = _number(root['op']);

    if (fr != frameRate) {
      errors.add('frame_rate_must_be_30');
    }
    if (ip != inPoint) {
      errors.add('in_point_must_be_0');
    }
    if (op != outPoint) {
      errors.add('out_point_must_be_180');
    }
    if (fr != null && ip != null && op != null && fr > 0) {
      final duration = (op - ip) / fr;
      if ((duration - durationSeconds).abs() > 0.000001) {
        errors.add('duration_must_be_6_seconds');
      }
    }

    final width = _number(root['w']);
    final height = _number(root['h']);
    if (width == null || width <= 0 || height == null || height <= 0) {
      errors.add('composition_bounds_required');
    }

    final layers = root['layers'];
    if (layers is! List || layers.isEmpty) {
      errors.add('layers_required');
    }

    if (_containsTextLayer(root)) {
      errors.add('text_layers_forbidden');
    }

    if (_containsRemoteReference(root)) {
      errors.add('remote_references_forbidden');
    }

    if (_containsRasterAsset(root)) {
      errors.add('raster_assets_forbidden');
    }

    return errors.isEmpty
        ? LearningTwinIdleAssetValidation.valid()
        : LearningTwinIdleAssetValidation.invalid(errors);
  }

  static double? _number(dynamic value) {
    return value is num ? value.toDouble() : null;
  }

  static bool _containsTextLayer(dynamic value) {
    if (value is Map) {
      if (value['ty'] == 5) {
        return true;
      }
      for (final nested in value.values) {
        if (_containsTextLayer(nested)) {
          return true;
        }
      }
      return false;
    }

    if (value is List) {
      return value.any(_containsTextLayer);
    }

    return false;
  }

  static bool _containsRemoteReference(dynamic value) {
    if (value is String) {
      final normalized = value.trim().toLowerCase();
      return normalized.startsWith('http://') ||
          normalized.startsWith('https://');
    }

    if (value is Map) {
      return value.values.any(_containsRemoteReference);
    }

    if (value is List) {
      return value.any(_containsRemoteReference);
    }

    return false;
  }

  static bool _containsRasterAsset(Map<String, dynamic> root) {
    final assets = root['assets'];
    if (assets is! List) {
      return false;
    }

    for (final asset in assets) {
      if (asset is! Map) {
        continue;
      }

      final path = asset['p'];
      if (path is String && path.trim().isNotEmpty) {
        return true;
      }

      final embedded = asset['e'];
      if (embedded == 1 || embedded == true) {
        return true;
      }
    }

    return false;
  }
}

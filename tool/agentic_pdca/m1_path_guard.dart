final class M1RepositoryPathGuard {
  const M1RepositoryPathGuard();

  bool isKnownGeneratedSideEffect(String path) =>
      canonicalize(path) != null &&
      const {
        'linux/flutter/generated_plugin_registrant.cc',
        'linux/flutter/generated_plugin_registrant.h',
        'linux/flutter/generated_plugins.cmake',
        'macos/Flutter/GeneratedPluginRegistrant.swift',
        'windows/flutter/generated_plugin_registrant.cc',
        'windows/flutter/generated_plugin_registrant.h',
        'windows/flutter/generated_plugins.cmake',
      }.contains(path);
  String? canonicalize(String path) {
    if (path.isEmpty || path.contains('\u0000')) {
      return null;
    }
    if (path.startsWith('/') ||
        path.startsWith('\\') ||
        RegExp(r'^[A-Za-z]:').hasMatch(path)) {
      return null;
    }
    if (path.contains('\\') ||
        path.contains(RegExp(r'[\u0001-\u001f\u007f]'))) {
      return null;
    }
    final segments = path.split('/');
    if (segments.any(
      (segment) => segment.isEmpty || segment == '.' || segment == '..',
    )) {
      return null;
    }
    return segments.join('/');
  }

  bool isAllowed(String path, List<String> allowedPatterns) {
    final canonicalPath = canonicalize(path);
    if (canonicalPath == null) {
      return false;
    }
    for (final pattern in allowedPatterns) {
      final canonicalPattern = _canonicalPattern(pattern);
      if (canonicalPattern == null) {
        return false;
      }
      if (canonicalPattern.endsWith('/**') &&
          canonicalPath.startsWith(
            canonicalPattern.substring(0, canonicalPattern.length - 2),
          )) {
        return true;
      }
      if (canonicalPath == canonicalPattern) {
        return true;
      }
    }
    return false;
  }

  bool isProtected(String path) {
    final canonicalPath = canonicalize(path);
    if (canonicalPath == null) {
      return true;
    }
    return canonicalPath.startsWith('lib/') ||
        canonicalPath.startsWith('content/') ||
        canonicalPath.startsWith('firebase/') ||
        canonicalPath.startsWith('docs/agentic/v1/') ||
        canonicalPath.startsWith('.github/') ||
        canonicalPath == 'pubspec.yaml' ||
        canonicalPath == 'pubspec.lock';
  }

  String? _canonicalPattern(String pattern) {
    if (pattern.endsWith('/**')) {
      final prefix = canonicalize(pattern.substring(0, pattern.length - 3));
      return prefix == null ? null : '$prefix/**';
    }
    return canonicalize(pattern);
  }
}

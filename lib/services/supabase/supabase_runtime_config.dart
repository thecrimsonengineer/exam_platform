class SupabaseRuntimeConfig {
  const SupabaseRuntimeConfig._({
    required this.url,
    required this.publishableKey,
  });

  final Uri url;
  final String publishableKey;

  static const String _environmentUrl = String.fromEnvironment('SUPABASE_URL');
  static const String _environmentPublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static SupabaseRuntimeConfig? fromEnvironment() {
    return tryParse(
      url: _environmentUrl,
      publishableKey: _environmentPublishableKey,
    );
  }

  static SupabaseRuntimeConfig? tryParse({
    required String url,
    required String publishableKey,
  }) {
    final normalizedUrl = url.trim();
    final normalizedKey = publishableKey.trim();

    if (normalizedUrl.isEmpty || normalizedKey.isEmpty) {
      return null;
    }

    final uri = Uri.tryParse(normalizedUrl);
    if (uri == null || uri.host.isEmpty || !_isAllowedScheme(uri)) {
      return null;
    }

    if (!normalizedKey.startsWith('sb_publishable_')) {
      return null;
    }

    return SupabaseRuntimeConfig._(
      url: uri,
      publishableKey: normalizedKey,
    );
  }

  static bool _isAllowedScheme(Uri uri) {
    if (uri.scheme == 'https') {
      return true;
    }

    if (uri.scheme != 'http') {
      return false;
    }

    return uri.host == 'localhost' ||
        uri.host == '127.0.0.1' ||
        uri.host == '::1';
  }
}

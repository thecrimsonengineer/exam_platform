import 'package:exam_platform/services/supabase/supabase_runtime_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FR2 accepts a hosted Supabase URL and publishable key', () {
    final config = SupabaseRuntimeConfig.tryParse(
      url: 'https://example.supabase.co',
      publishableKey: 'sb_publishable_test_key',
    );

    expect(config, isNotNull);
    expect(config!.url.host, 'example.supabase.co');
    expect(config.publishableKey, 'sb_publishable_test_key');
  });

  test('FR2 rejects missing configuration', () {
    expect(
      SupabaseRuntimeConfig.tryParse(url: '', publishableKey: ''),
      isNull,
    );
  });

  test('FR2 rejects secret and service-role style client keys', () {
    expect(
      SupabaseRuntimeConfig.tryParse(
        url: 'https://example.supabase.co',
        publishableKey: 'sb_secret_do_not_ship',
      ),
      isNull,
    );
    expect(
      SupabaseRuntimeConfig.tryParse(
        url: 'https://example.supabase.co',
        publishableKey: 'legacy-service-role-key',
      ),
      isNull,
    );
  });

  test('FR2 requires HTTPS except for local development hosts', () {
    expect(
      SupabaseRuntimeConfig.tryParse(
        url: 'http://example.supabase.co',
        publishableKey: 'sb_publishable_test_key',
      ),
      isNull,
    );

    expect(
      SupabaseRuntimeConfig.tryParse(
        url: 'http://127.0.0.1:54321',
        publishableKey: 'sb_publishable_test_key',
      ),
      isNotNull,
    );
  });
}

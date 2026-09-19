import 'package:exam_platform/services/supabase/supabase_bootstrap_service.dart';
import 'package:exam_platform/services/supabase/supabase_runtime_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('FR2 bootstrap remains inert when Supabase is not configured', () async {
    final initialized = await SupabaseBootstrapService.initializeIfConfigured();

    expect(initialized, isFalse);
    expect(SupabaseBootstrapService.isInitialized, isFalse);
  });

  test('FR2 runtime config accepts only publishable client credentials', () {
    final config = SupabaseRuntimeConfig.tryParse(
      url: 'https://example.supabase.co',
      publishableKey: 'sb_publishable_test_key',
    );

    expect(config, isNotNull);
    expect(config!.publishableKey, startsWith('sb_publishable_'));
  });
}

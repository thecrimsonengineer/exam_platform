import 'dart:io';

import 'package:exam_platform/services/supabase/supabase_runtime_config.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('INT-R9A3 Supabase bootstrap verification', () {
    test('release dart-defines resolve the production public client config', () {
      final config = SupabaseRuntimeConfig.fromEnvironment();

      expect(config, isNotNull);
      expect(config!.url.scheme, 'https');
      expect(config.url.host, 'esfycnmfywxczfillioj.supabase.co');
      expect(config.publishableKey, startsWith('sb_publishable_'));
      expect(config.publishableKey, isNot(startsWith('sb_secret_')));
    });

    test('startup initializes Firebase before Supabase and before runApp', () {
      final source = File('lib/main.dart').readAsStringSync();

      final firebaseIndex = source.indexOf('Firebase.initializeApp');
      final supabaseIndex = source.indexOf(
        'SupabaseBootstrapService.initializeIfConfigured',
      );
      final localRepositoryIndex = source.indexOf(
        'LocalQuestionRepository.instance.initialize',
      );
      final runAppIndex = source.indexOf('runApp(const ExamPlatformApp())');

      expect(firebaseIndex, greaterThanOrEqualTo(0));
      expect(supabaseIndex, greaterThan(firebaseIndex));
      expect(localRepositoryIndex, greaterThan(supabaseIndex));
      expect(runAppIndex, greaterThan(localRepositoryIndex));
    });

    test('bootstrap initializes Supabase from public config and Firebase token', () {
      final source = File(
        'lib/services/supabase/supabase_bootstrap_service.dart',
      ).readAsStringSync();

      expect(source, contains('SupabaseRuntimeConfig.fromEnvironment()'));
      expect(source, contains('Supabase.initialize('));
      expect(source, contains('url: resolvedConfig.url.toString()'));
      expect(
        source,
        contains('publishableKey: resolvedConfig.publishableKey'),
      );
      expect(
        source,
        contains('accessToken: () async => auth.currentUser?.getIdToken()'),
      );
      expect(source, contains('_initialized = true'));
    });

    test('learner runtime selects remote probe only after bootstrap succeeds', () {
      final source = File(
        'lib/services/online_access/learner_online_access_runtime.dart',
      ).readAsStringSync();

      expect(source, contains('SupabaseBootstrapService.isInitialized'));
      expect(source, contains('SupabaseLearnerRemoteAuthorizationProbe()'));
      expect(
        source,
        contains('_UnavailableLearnerRemoteAuthorizationProbe()'),
      );
      expect(
        source,
        contains(
          'Supabase is not configured, so protected learner access remains locked.',
        ),
      );
    });

    test('remote authorization targets firebase-auth-probe with bearer token', () {
      final source = File(
        'lib/services/supabase/supabase_learner_remote_authorization_probe.dart',
      ).readAsStringSync();

      expect(
        source,
        contains("static const String functionName = 'firebase-auth-probe'"),
      );
      expect(
        source,
        contains("'Authorization': 'Bearer \\$normalizedToken'"),
      );
      expect(source, contains("return data['authorized'] == true"));
    });

    test('client bootstrap surface contains no privileged Supabase key contract', () {
      final files = <String>[
        'lib/services/supabase/supabase_runtime_config.dart',
        'lib/services/supabase/supabase_bootstrap_service.dart',
        'lib/services/supabase/supabase_learner_remote_authorization_probe.dart',
        'lib/services/online_access/learner_online_access_runtime.dart',
        'lib/main.dart',
      ];

      final combined = files.map((path) => File(path).readAsStringSync()).join();

      expect(combined, isNot(contains('SUPABASE_SECRET_KEY')));
      expect(combined, isNot(contains('SUPABASE_SERVICE_ROLE_KEY')));
      expect(combined, isNot(contains('sb_secret_')));
      expect(combined, isNot(contains('service_role')));
    });
  });
}

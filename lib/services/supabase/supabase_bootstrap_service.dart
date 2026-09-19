import 'package:firebase_auth/firebase_auth.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'supabase_runtime_config.dart';

class SupabaseBootstrapService {
  SupabaseBootstrapService._();

  static bool _initialized = false;

  static bool get isInitialized => _initialized;

  static Future<bool> initializeIfConfigured({
    SupabaseRuntimeConfig? config,
    FirebaseAuth? firebaseAuth,
  }) async {
    if (_initialized) {
      return true;
    }

    final resolvedConfig = config ?? SupabaseRuntimeConfig.fromEnvironment();
    if (resolvedConfig == null) {
      return false;
    }

    final auth = firebaseAuth ?? FirebaseAuth.instance;

    await Supabase.initialize(
      url: resolvedConfig.url.toString(),
      publishableKey: resolvedConfig.publishableKey,
      debug: false,
      accessToken: () async => auth.currentUser?.getIdToken(),
    );

    _initialized = true;
    return true;
  }
}

import 'package:supabase_flutter/supabase_flutter.dart';

import '../online_access/learner_online_access_gate.dart';

abstract interface class LearnerAuthorizationFunctionInvoker {
  Future<Object?> invoke({
    required String functionName,
    required Map<String, String> headers,
  });
}

class SupabaseLearnerAuthorizationFunctionInvoker
    implements LearnerAuthorizationFunctionInvoker {
  SupabaseLearnerAuthorizationFunctionInvoker({SupabaseClient? client})
    : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<Object?> invoke({
    required String functionName,
    required Map<String, String> headers,
  }) async {
    final response = await _client.functions.invoke(
      functionName,
      headers: headers,
    );
    return response.data;
  }
}

class SupabaseLearnerRemoteAuthorizationProbe
    implements LearnerRemoteAuthorizationProbe {
  SupabaseLearnerRemoteAuthorizationProbe({
    LearnerAuthorizationFunctionInvoker? invoker,
  }) : _invoker = invoker ?? SupabaseLearnerAuthorizationFunctionInvoker();

  static const String functionName = 'firebase-auth-probe';

  final LearnerAuthorizationFunctionInvoker _invoker;

  @override
  Future<bool> authorize({required String accessToken}) async {
    final normalizedToken = accessToken.trim();
    if (normalizedToken.isEmpty) {
      return false;
    }

    final data = await _invoker.invoke(
      functionName: functionName,
      headers: <String, String>{'Authorization': 'Bearer $normalizedToken'},
    );

    if (data is! Map) {
      return false;
    }

    return data['authorized'] == true;
  }
}

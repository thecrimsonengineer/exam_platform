import 'package:exam_platform/services/supabase/supabase_learner_remote_authorization_probe.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'FR2 probe sends Firebase token only to the auth Edge Function',
    () async {
      final invoker = _FakeInvoker(
        response: <String, Object?>{'authorized': true},
      );
      final probe = SupabaseLearnerRemoteAuthorizationProbe(invoker: invoker);

      final result = await probe.authorize(accessToken: ' firebase-token ');

      expect(result, isTrue);
      expect(
        invoker.lastFunctionName,
        SupabaseLearnerRemoteAuthorizationProbe.functionName,
      );
      expect(invoker.lastHeaders, <String, String>{
        'Authorization': 'Bearer firebase-token',
      });
    },
  );

  test('FR2 probe fails closed for malformed responses', () async {
    final probe = SupabaseLearnerRemoteAuthorizationProbe(
      invoker: _FakeInvoker(response: 'unexpected'),
    );

    expect(await probe.authorize(accessToken: 'token'), isFalse);
  });

  test('FR2 probe fails closed when authorized is not true', () async {
    final probe = SupabaseLearnerRemoteAuthorizationProbe(
      invoker: _FakeInvoker(response: <String, Object?>{'authorized': false}),
    );

    expect(await probe.authorize(accessToken: 'token'), isFalse);
  });

  test('FR2 probe refuses an empty token before network invocation', () async {
    final invoker = _FakeInvoker(
      response: <String, Object?>{'authorized': true},
    );
    final probe = SupabaseLearnerRemoteAuthorizationProbe(invoker: invoker);

    expect(await probe.authorize(accessToken: '   '), isFalse);
    expect(invoker.calls, 0);
  });
}

class _FakeInvoker implements LearnerAuthorizationFunctionInvoker {
  _FakeInvoker({required this.response});

  final Object? response;
  int calls = 0;
  String? lastFunctionName;
  Map<String, String>? lastHeaders;

  @override
  Future<Object?> invoke({
    required String functionName,
    required Map<String, String> headers,
  }) async {
    calls += 1;
    lastFunctionName = functionName;
    lastHeaders = Map<String, String>.from(headers);
    return response;
  }
}

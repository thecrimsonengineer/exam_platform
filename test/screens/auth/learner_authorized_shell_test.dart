import 'dart:async';

import 'package:exam_platform/screens/auth/learner_authorized_shell.dart';
import 'package:exam_platform/services/online_access/learner_connectivity_signal_source.dart';
import 'package:exam_platform/services/online_access/learner_online_access_gate.dart';
import 'package:exam_platform/services/online_access/learner_online_access_session_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'FR8C keeps protected learner UI hidden until authorization succeeds',
    (tester) async {
      final validator = _ControlledValidator();
      final controller = LearnerOnlineAccessSessionController(
        validator: validator,
        currentUserId: () => 'student-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LearnerAuthorizedShell(
            userId: 'student-1',
            controller: controller,
            connectivitySignalSource: _AlwaysOnlineConnectivitySource(),
            authorizedChild: const Text(
              'Protected learner UI',
              key: ValueKey('protected-learner-ui'),
            ),
          ),
        ),
      );

      await tester.pump();

      expect(find.byKey(const ValueKey('protected-learner-ui')), findsNothing);
      expect(find.text('Verifying secure online access...'), findsOneWidget);

      validator.completeNext(LearnerOnlineAccessStatus.authorized);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('protected-learner-ui')),
        findsOneWidget,
      );
    },
  );

  testWidgets('FR8C rejected authorization keeps protected UI locked', (
    tester,
  ) async {
    final controller = LearnerOnlineAccessSessionController(
      validator: _ImmediateValidator(LearnerOnlineAccessStatus.rejected),
      currentUserId: () => 'student-1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LearnerAuthorizedShell(
          userId: 'student-1',
          controller: controller,
          authorizedChild: const Text(
            'Protected learner UI',
            key: ValueKey('protected-learner-ui'),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('protected-learner-ui')), findsNothing);
    expect(
      find.byKey(const ValueKey('fr8-retry-online-authorization')),
      findsOneWidget,
    );
  });
}

class _ControlledValidator implements LearnerOnlineAccessValidator {
  Completer<LearnerOnlineAccessResult> _next =
      Completer<LearnerOnlineAccessResult>();

  @override
  Future<LearnerOnlineAccessResult> validate({bool forceRefreshToken = false}) {
    return _next.future;
  }

  void completeNext(LearnerOnlineAccessStatus status) {
    _next.complete(
      LearnerOnlineAccessResult(status: status, checkedAt: DateTime.utc(2026)),
    );
    _next = Completer<LearnerOnlineAccessResult>();
  }
}

class _ImmediateValidator implements LearnerOnlineAccessValidator {
  _ImmediateValidator(this.status);

  final LearnerOnlineAccessStatus status;

  @override
  Future<LearnerOnlineAccessResult> validate({
    bool forceRefreshToken = false,
  }) async {
    return LearnerOnlineAccessResult(
      status: status,
      checkedAt: DateTime.utc(2026),
    );
  }
}

class _AlwaysOnlineConnectivitySource
    implements LearnerConnectivitySignalSource {
  @override
  Future<bool> hasConnectivity() async => true;

  @override
  Stream<bool> get changes => const Stream<bool>.empty();
}

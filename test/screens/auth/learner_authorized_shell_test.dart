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
      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

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
          connectivitySignalSource: _AlwaysOnlineConnectivitySource(),
          authorizedChild: const Text(
            'Protected learner UI',
            key: ValueKey('protected-learner-ui'),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 800));
    await tester.pump();

    expect(find.byKey(const ValueKey('protected-learner-ui')), findsNothing);
    expect(
      find.byKey(const ValueKey('fr8-retry-online-authorization')),
      findsOneWidget,
    );
  });
  testWidgets('FR8E offline launch never renders protected learner UI', (
    tester,
  ) async {
    final validator = _CountingValidator(
      LearnerOnlineAccessStatus.backendUnavailable,
    );
    final controller = LearnerOnlineAccessSessionController(
      validator: validator,
      currentUserId: () => 'student-1',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LearnerAuthorizedShell(
          userId: 'student-1',
          controller: controller,
          connectivitySignalSource: _AlwaysOfflineConnectivitySource(),
          authorizedChild: const Text(
            'Protected learner UI',
            key: ValueKey('protected-learner-ui'),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('protected-learner-ui')), findsNothing);
    expect(
      find.byKey(const ValueKey('fr8-retry-online-authorization')),
      findsOneWidget,
    );
    expect(controller.snapshot.status, LearnerOnlineSessionStatus.locked);
    expect(
      controller.snapshot.lockReason,
      LearnerOnlineLockReason.backendUnavailable,
    );
    expect(validator.calls, 2);
  });

  testWidgets(
    'FR8E stale offline transport hint does not suppress remote authorization',
    (tester) async {
      final validator = _CountingValidator(
        LearnerOnlineAccessStatus.authorized,
      );
      final controller = LearnerOnlineAccessSessionController(
        validator: validator,
        currentUserId: () => 'student-1',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: LearnerAuthorizedShell(
            userId: 'student-1',
            controller: controller,
            connectivitySignalSource: _AlwaysOfflineConnectivitySource(),
            authorizedChild: const Text(
              'Protected learner UI',
              key: ValueKey('protected-learner-ui'),
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(
        find.byKey(const ValueKey('protected-learner-ui')),
        findsOneWidget,
      );
      expect(validator.calls, 1);
    },
  );

  testWidgets('FR8E app resume locks protected UI until reauthorization', (
    tester,
  ) async {
    final validator = _ResumeValidator();
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
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    expect(find.byKey(const ValueKey('protected-learner-ui')), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.byKey(const ValueKey('protected-learner-ui')), findsNothing);
    expect(find.text('Verifying secure online access...'), findsOneWidget);
    expect(validator.lastForceRefresh, isTrue);

    validator.completeResume();
    await tester.pump();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.byKey(const ValueKey('protected-learner-ui')), findsOneWidget);
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

class _CountingValidator implements LearnerOnlineAccessValidator {
  _CountingValidator(this.status);

  final LearnerOnlineAccessStatus status;
  int calls = 0;

  @override
  Future<LearnerOnlineAccessResult> validate({
    bool forceRefreshToken = false,
  }) async {
    calls++;
    return LearnerOnlineAccessResult(
      status: status,
      checkedAt: DateTime.utc(2026, 9, 22),
    );
  }
}

class _ResumeValidator implements LearnerOnlineAccessValidator {
  int calls = 0;
  bool? lastForceRefresh;
  final Completer<LearnerOnlineAccessResult> _resume =
      Completer<LearnerOnlineAccessResult>();

  @override
  Future<LearnerOnlineAccessResult> validate({
    bool forceRefreshToken = false,
  }) async {
    calls++;
    lastForceRefresh = forceRefreshToken;

    if (calls == 1) {
      return LearnerOnlineAccessResult(
        status: LearnerOnlineAccessStatus.authorized,
        checkedAt: DateTime.utc(2026, 9, 22),
      );
    }

    return _resume.future;
  }

  void completeResume() {
    if (_resume.isCompleted) {
      return;
    }

    _resume.complete(
      LearnerOnlineAccessResult(
        status: LearnerOnlineAccessStatus.authorized,
        checkedAt: DateTime.utc(2026, 9, 22, 1),
      ),
    );
  }
}

class _AlwaysOfflineConnectivitySource
    implements LearnerConnectivitySignalSource {
  @override
  Future<bool> hasConnectivity() async => false;

  @override
  Stream<bool> get changes => const Stream<bool>.empty();
}

class _AlwaysOnlineConnectivitySource
    implements LearnerConnectivitySignalSource {
  @override
  Future<bool> hasConnectivity() async => true;

  @override
  Stream<bool> get changes => const Stream<bool>.empty();
}

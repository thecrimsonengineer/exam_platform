import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/online_access/learner_online_access_runtime.dart';
import '../../services/online_access/learner_online_access_session_controller.dart';
import '../navigation/bottom_navigation.dart';

class LearnerAuthorizedShell extends StatefulWidget {
  const LearnerAuthorizedShell({
    super.key,
    required this.userId,
    this.controller,
    this.authorizedChild,
  });

  final String userId;
  final LearnerOnlineAccessSessionController? controller;
  final Widget? authorizedChild;

  @override
  State<LearnerAuthorizedShell> createState() =>
      _LearnerAuthorizedShellState();
}

class _LearnerAuthorizedShellState extends State<LearnerAuthorizedShell>
    with WidgetsBindingObserver {
  late final LearnerOnlineAccessSessionController _controller;
  late final bool _ownsController;
  StreamSubscription<LearnerOnlineAccessSessionSnapshot>? _subscription;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _ownsController = widget.controller == null;
    _controller =
        widget.controller ?? LearnerOnlineAccessRuntime.createDefaultController();

    LearnerOnlineAccessRuntime.bind(
      userId: widget.userId,
      controller: _controller,
    );

    _subscription = _controller.changes.listen((snapshot) {
      if (!snapshot.isAuthorizedFor(widget.userId)) {
        LearnerOnlineAccessRuntime.clearProtectedProcessMemory();
      }

      if (mounted) {
        setState(() {});
      }
    });

    unawaited(_authorize());
  }

  Future<void> _authorize({bool forceRefreshToken = false}) async {
    await _controller.authorizeForUser(
      widget.userId,
      forceRefreshToken: forceRefreshToken,
    );

    if (mounted) {
      setState(() {});
    }
  }

  Future<void> _revalidateAfterResume() async {
    await _controller.revalidateOnResume();

    if (mounted) {
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      unawaited(_revalidateAfterResume());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    _controller.lock(reason: LearnerOnlineLockReason.manual);
    LearnerOnlineAccessRuntime.unbind(_controller);

    if (_ownsController) {
      _controller.dispose();
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _controller.snapshot;

    if (snapshot.isAuthorizedFor(widget.userId)) {
      return widget.authorizedChild ??
          BottomNavigationScreen(
            key: ValueKey('authorized-student-shell-${widget.userId}'),
          );
    }

    final isChecking =
        snapshot.status == LearnerOnlineSessionStatus.validating ||
        snapshot.lockReason == LearnerOnlineLockReason.startup ||
        snapshot.lockReason == LearnerOnlineLockReason.appResumed;

    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: isChecking
              ? const Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text(
                      'Verifying secure online access...',
                      textAlign: TextAlign.center,
                    ),
                  ],
                )
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.lock_outline, size: 42),
                    const SizedBox(height: 12),
                    const Text(
                      'Protected learning content is locked until online '
                      'authorization succeeds.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      key: const ValueKey('fr8-retry-online-authorization'),
                      onPressed: () {
                        unawaited(_authorize(forceRefreshToken: true));
                      },
                      child: const Text('Retry secure access'),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

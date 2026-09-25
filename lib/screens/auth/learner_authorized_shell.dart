import 'dart:async';

import 'package:flutter/material.dart';

import '../../services/online_access/learner_connectivity_signal_source.dart';
import '../../services/online_access/learner_online_access_runtime.dart';
import '../../services/online_access/learner_online_access_session_controller.dart';
import '../../services/online_access/learner_online_connectivity_coordinator.dart';
import '../navigation/bottom_navigation.dart';

class LearnerAuthorizedShell extends StatefulWidget {
  const LearnerAuthorizedShell({
    super.key,
    required this.userId,
    this.controller,
    this.connectivitySignalSource,
    this.authorizedChild,
  });

  final String userId;
  final LearnerOnlineAccessSessionController? controller;
  final LearnerConnectivitySignalSource? connectivitySignalSource;
  final Widget? authorizedChild;

  @override
  State<LearnerAuthorizedShell> createState() => _LearnerAuthorizedShellState();
}

class _LearnerAuthorizedShellState extends State<LearnerAuthorizedShell>
    with WidgetsBindingObserver {
  late final LearnerOnlineAccessSessionController _controller;
  late final LearnerOnlineConnectivityCoordinator _connectivityCoordinator;
  late final bool _ownsController;
  static const Duration _startupAuthorizationRetryDelay = Duration(
    milliseconds: 750,
  );

  StreamSubscription<LearnerOnlineAccessSessionSnapshot>? _subscription;
  bool _hasLeftForeground = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    _ownsController = widget.controller == null;
    _controller =
        widget.controller ??
        LearnerOnlineAccessRuntime.createDefaultController();

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

    _connectivityCoordinator = LearnerOnlineConnectivityCoordinator(
      controller: _controller,
      signalSource:
          widget.connectivitySignalSource ??
          ConnectivityPlusLearnerConnectivitySignalSource(),
    );

    unawaited(_startOnlineSession());
  }

  Future<void> _startOnlineSession() async {
    // Connectivity is a transport hint only. The remote Firebase-token probe is
    // the authority for protected learner access, so always attempt it even if
    // the platform connectivity signal is briefly stale during Android startup.
    await _connectivityCoordinator.start();
    await _authorize();

    if (!mounted || _controller.isAuthorizedFor(widget.userId)) {
      return;
    }

    final lockReason = _controller.snapshot.lockReason;
    final retryableStartupFailure =
        lockReason == LearnerOnlineLockReason.backendUnavailable ||
        lockReason == LearnerOnlineLockReason.noAuthenticatedUser ||
        lockReason == LearnerOnlineLockReason.connectivityLost;

    if (!retryableStartupFailure) {
      return;
    }

    await Future<void>.delayed(_startupAuthorizationRetryDelay);
    if (!mounted || _controller.isAuthorizedFor(widget.userId)) {
      return;
    }

    await _authorize(forceRefreshToken: true);
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
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      _hasLeftForeground = true;
      return;
    }

    if (state == AppLifecycleState.resumed && _hasLeftForeground) {
      _hasLeftForeground = false;
      unawaited(_revalidateAfterResume());
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _subscription?.cancel();
    unawaited(_connectivityCoordinator.dispose());
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

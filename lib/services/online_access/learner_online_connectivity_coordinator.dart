import 'dart:async';

import 'learner_connectivity_signal_source.dart';
import 'learner_online_access_session_controller.dart';

/// Bridges platform connectivity signals into the frozen FR8 authorization
/// state machine.
///
/// Connectivity is only a hint. A recovered transport must pass the remote
/// Firebase-token authorization gate before protected content can unlock.
class LearnerOnlineConnectivityCoordinator {
  LearnerOnlineConnectivityCoordinator({
    required LearnerOnlineAccessSessionController controller,
    required LearnerConnectivitySignalSource signalSource,
  }) : _controller = controller,
       _signalSource = signalSource;

  final LearnerOnlineAccessSessionController _controller;
  final LearnerConnectivitySignalSource _signalSource;

  StreamSubscription<bool>? _subscription;
  bool? _lastHasConnectivity;
  bool _disposed = false;

  bool? get lastHasConnectivity => _lastHasConnectivity;

  Future<bool> start() async {
    if (_disposed) {
      return false;
    }

    final existingSubscription = _subscription;
    if (existingSubscription != null) {
      return _lastHasConnectivity ?? false;
    }

    bool initialHasConnectivity;
    try {
      initialHasConnectivity = await _signalSource.hasConnectivity();
    } catch (_) {
      _controller.handleConfirmedNetworkLoss();
      return false;
    }

    if (_disposed) {
      return false;
    }

    _lastHasConnectivity = initialHasConnectivity;
    _subscription = _signalSource.changes.listen(
      _handleSignal,
      onError: (_, _) => _handleMonitorFailure(),
    );

    if (!initialHasConnectivity) {
      _controller.handleConfirmedNetworkLoss();
    }

    return initialHasConnectivity;
  }

  void _handleSignal(bool hasConnectivity) {
    if (_disposed || _lastHasConnectivity == hasConnectivity) {
      return;
    }

    _lastHasConnectivity = hasConnectivity;

    if (hasConnectivity) {
      unawaited(_controller.handleConnectivityRestored());
      return;
    }

    unawaited(_controller.handleTransientConnectivityLoss());
  }

  void _handleMonitorFailure() {
    if (_disposed) {
      return;
    }

    _lastHasConnectivity = false;
    _controller.handleConfirmedNetworkLoss();
  }

  Future<void> dispose() async {
    if (_disposed) {
      return;
    }

    _disposed = true;
    await _subscription?.cancel();
    _subscription = null;
  }
}

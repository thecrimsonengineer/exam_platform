import 'package:flutter/foundation.dart';

import 'learning_twin_motion_descriptor.dart';
import 'learning_twin_motion_state.dart';

final class LearningTwinMotionController extends ChangeNotifier {
  LearningTwinMotionController();

  LearningTwinMotionDescriptor? _currentDescriptor;
  String? _currentEventKey;
  bool _isPlaying = false;
  bool _isLooping = false;
  _PendingMotion? _pending;
  LearningTwinMotionState? _lastCompletedState;
  String? _lastCompletedEventKey;
  bool _disposed = false;

  LearningTwinMotionState get currentState =>
      _currentDescriptor?.state ?? LearningTwinMotionState.idle;
  LearningTwinMotionDescriptor? get currentDescriptor => _currentDescriptor;
  String? get currentEventKey => _currentEventKey;
  bool get isPlaying => _isPlaying;
  bool get isLooping => _isLooping;
  LearningTwinMotionState? get pendingState => _pending?.descriptor.state;
  String? get pendingEventKey => _pending?.eventKey;
  LearningTwinMotionState? get lastCompletedState => _lastCompletedState;
  String? get lastCompletedEventKey => _lastCompletedEventKey;

  bool request(
    LearningTwinMotionDescriptor descriptor, {
    String? eventKey,
    bool forceReplay = false,
  }) {
    if (_disposed) {
      return false;
    }

    if (!forceReplay &&
        eventKey != null &&
        _lastCompletedState == descriptor.state &&
        _lastCompletedEventKey == eventKey) {
      return false;
    }

    if (_currentDescriptor?.state == descriptor.state &&
        _currentEventKey == eventKey) {
      if (!_isPlaying) {
        _isPlaying = true;
        _isLooping = descriptor.loop;
        notifyListeners();
        return true;
      }
      return false;
    }

    final current = _currentDescriptor;
    if (current == null || !_isPlaying || current.state == LearningTwinMotionState.idle) {
      _start(descriptor, eventKey);
      return true;
    }

    if (current.state == LearningTwinMotionState.thinking &&
        descriptor.priority > current.priority) {
      _start(descriptor, eventKey);
      return true;
    }

    if (descriptor.priority > current.priority) {
      _start(descriptor, eventKey);
      return true;
    }

    if (descriptor.state != LearningTwinMotionState.idle) {
      final pending = _pending;
      if (pending == null || descriptor.priority >= pending.descriptor.priority) {
        _pending = _PendingMotion(descriptor, eventKey);
        notifyListeners();
      }
    }
    return false;
  }

  void completeCurrent({LearningTwinMotionDescriptor? idleDescriptor}) {
    if (_disposed) {
      return;
    }

    final completed = _currentDescriptor;
    if (completed != null && !completed.loop && _currentEventKey != null) {
      _lastCompletedState = completed.state;
      _lastCompletedEventKey = _currentEventKey;
    }

    final pending = _pending;
    _pending = null;
    if (pending != null) {
      _start(pending.descriptor, pending.eventKey);
      return;
    }

    if (idleDescriptor != null) {
      _start(idleDescriptor, null);
      return;
    }

    _currentDescriptor = null;
    _currentEventKey = null;
    _isPlaying = false;
    _isLooping = false;
    notifyListeners();
  }

  void stopToIdle({LearningTwinMotionDescriptor? idleDescriptor}) {
    if (_disposed) {
      return;
    }
    _pending = null;
    if (idleDescriptor != null) {
      _start(idleDescriptor, null);
      return;
    }
    _currentDescriptor = null;
    _currentEventKey = null;
    _isPlaying = false;
    _isLooping = false;
    notifyListeners();
  }

  void pause() {
    if (_disposed || !_isPlaying) {
      return;
    }
    _isPlaying = false;
    notifyListeners();
  }

  void resume() {
    if (_disposed || _currentDescriptor == null || _isPlaying) {
      return;
    }
    _isPlaying = true;
    _isLooping = _currentDescriptor!.loop;
    notifyListeners();
  }

  void setAppActive(bool active) {
    if (active) {
      resume();
    } else {
      pause();
    }
  }

  void replayCurrent() {
    if (_disposed || _currentDescriptor == null) {
      return;
    }
    _lastCompletedState = null;
    _lastCompletedEventKey = null;
    _isPlaying = true;
    notifyListeners();
  }

  void _start(LearningTwinMotionDescriptor descriptor, String? eventKey) {
    _currentDescriptor = descriptor;
    _currentEventKey = eventKey;
    _isPlaying = true;
    _isLooping = descriptor.loop;
    notifyListeners();
  }

  @visibleForTesting
  bool get isDisposed => _disposed;

  @override
  void dispose() {
    _disposed = true;
    _pending = null;
    super.dispose();
  }
}

final class _PendingMotion {
  const _PendingMotion(this.descriptor, this.eventKey);

  final LearningTwinMotionDescriptor descriptor;
  final String? eventKey;
}

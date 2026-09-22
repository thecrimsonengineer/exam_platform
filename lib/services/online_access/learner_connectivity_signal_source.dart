import 'package:connectivity_plus/connectivity_plus.dart';

abstract interface class LearnerConnectivitySignalSource {
  Future<bool> hasConnectivity();

  Stream<bool> get changes;
}

/// Cross-platform transport signal used by FR8D.
///
/// A positive connectivity result is not proof that CSP11 is authorized or
/// that the Internet is reachable. It may only trigger the remote FR8
/// authorization gate.
class ConnectivityPlusLearnerConnectivitySignalSource
    implements LearnerConnectivitySignalSource {
  ConnectivityPlusLearnerConnectivitySignalSource({Connectivity? connectivity})
    : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  @override
  Future<bool> hasConnectivity() async {
    return _hasTransport(await _connectivity.checkConnectivity());
  }

  @override
  Stream<bool> get changes {
    return _connectivity.onConnectivityChanged.map(_hasTransport).distinct();
  }

  bool _hasTransport(List<ConnectivityResult> results) {
    return results.any((result) => result != ConnectivityResult.none);
  }
}

import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

/// Abstraction for checking network connectivity.
///
/// Using an abstract class makes it easy to mock in tests.
abstract class NetworkInfo {
  /// Returns `true` when the device has an active network connection.
  Future<bool> get isConnected;

  /// Emits `true`/`false` whenever connectivity changes.
  Stream<bool> get onConnectivityChanged;
}

/// Production implementation backed by [connectivity_plus].
class NetworkInfoImpl implements NetworkInfo {
  final Connectivity _connectivity;

  NetworkInfoImpl(this._connectivity);

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _hasConnection(results);
  }

  @override
  Stream<bool> get onConnectivityChanged {
    return _connectivity.onConnectivityChanged.map(_hasConnection);
  }

  /// Returns `true` if at least one result is NOT [ConnectivityResult.none].
  bool _hasConnection(List<ConnectivityResult> results) {
    return results.any((r) => r != ConnectivityResult.none);
  }
}

import 'package:connectivity_plus/connectivity_plus.dart';

/// Thin wrapper over [Connectivity] that adds:
/// - [lastKnownStatus] — cached bool so BLoCs read O(1) without a platform call
/// - [isOffline] — convenience inverse of [isConnected]
/// - [onStatusChanged] — typed bool stream (true = connected) instead of raw
///   ConnectivityResult for callers that only care about connected/offline.
class ConnectivityChecker {
  ConnectivityChecker({Connectivity? connectivity})
      : _connectivity = connectivity ?? Connectivity();

  final Connectivity _connectivity;

  /// Last connectivity status received from the platform, or null before the
  /// first check. Updated automatically by [onStatusChanged] subscribers and by
  /// every call to [isConnected].
  bool? _lastKnownStatus;

  /// Cached connectivity status. Null until [isConnected] or
  /// [onStatusChanged] resolves for the first time.
  bool? get lastKnownStatus => _lastKnownStatus;

  /// Returns true if the device has any network access.
  /// Also updates [lastKnownStatus].
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    final connected = results.any((r) => r != ConnectivityResult.none);
    _lastKnownStatus = connected;
    return connected;
  }

  /// Convenience inverse of [isConnected].
  Future<bool> get isOffline async => !(await isConnected);

  /// Typed stream of connectivity changes (true = connected, false = offline).
  /// Each emitted value also updates [lastKnownStatus].
  Stream<bool> get onStatusChanged =>
      _connectivity.onConnectivityChanged.map((results) {
        final connected = results.any((r) => r != ConnectivityResult.none);
        _lastKnownStatus = connected;
        return connected;
      });

  /// Deprecated name kept for backward compatibility.
  /// Prefer [onStatusChanged] in new code.
  @Deprecated('Use onStatusChanged instead.')
  Stream<bool> get onConnectivityChanged => onStatusChanged;
}

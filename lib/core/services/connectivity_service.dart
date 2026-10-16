import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';

/// A robust connectivity service that monitors both network interface status
/// and verifies actual internet reachability.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _onlineStatusController =
      StreamController<bool>.broadcast();

  bool _isOnline = true;
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  Timer? _heartbeatTimer;

  bool get isOnline => _isOnline;
  Stream<bool> get isOnlineStream => _onlineStatusController.stream;

  /// Initializes connectivity listeners and performs an immediate check.
  void initialize() {
    _subscription?.cancel();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _evaluateConnectivity(results);
    });

    // Periodic heartbeat every 30 seconds for background verification
    _heartbeatTimer?.cancel();
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (_) {
      checkConnectivity();
    });

    // Run initial check
    checkConnectivity();
  }

  /// Manually checks and returns whether the device is currently online.
  Future<bool> checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      return await _evaluateConnectivity(results);
    } catch (_) {
      // In testing or environments without platform channels, test internet directly
      final reachable = await _verifyInternetReachability();
      _updateStatus(reachable);
      return reachable;
    }
  }

  Future<bool> _evaluateConnectivity(List<ConnectivityResult> results) async {
    // If no network interface is active, device is definitely offline
    final hasActiveInterface = results.any(
      (r) =>
          r == ConnectivityResult.wifi ||
          r == ConnectivityResult.mobile ||
          r == ConnectivityResult.ethernet ||
          r == ConnectivityResult.vpn,
    );

    if (!hasActiveInterface) {
      _updateStatus(false);
      return false;
    }

    // Verify actual reachability to avoid "connected without internet" scenarios
    final reachable = await _verifyInternetReachability();
    _updateStatus(reachable);
    return reachable;
  }

  Future<bool> _verifyInternetReachability() async {
    try {
      final result = await InternetAddress.lookup(
        'google.com',
      ).timeout(const Duration(seconds: 3));
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on TimeoutException catch (_) {
      return false;
    } catch (_) {
      return false;
    }
  }

  void _updateStatus(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      if (!_onlineStatusController.isClosed) {
        _onlineStatusController.add(isOnline);
      }
    }
  }

  void dispose() {
    _subscription?.cancel();
    _heartbeatTimer?.cancel();
    _onlineStatusController.close();
  }
}

import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:pay_app/services/connectivity/connectivity.dart';

enum ConnectivityStatus {
  online,
  connecting,
  offline,
}

class ConnectivityState with ChangeNotifier {
  final ConnectivityService _connectivityService = ConnectivityService();
  StreamSubscription<bool>? _connectivitySubscription;
  Timer? _connectingTimer;

  ConnectivityStatus _status = ConnectivityStatus.online;
  ConnectivityStatus get status => _status;

  bool get isOnline => _status == ConnectivityStatus.online;
  bool get isOffline => _status == ConnectivityStatus.offline;
  bool get isConnecting => _status == ConnectivityStatus.connecting;
  bool get shouldShowBanner => _status != ConnectivityStatus.online;

  ConnectivityState() {
    _init();
  }

  Future<void> _init() async {
    // Initialize the connectivity service
    await _connectivityService.init();

    // Set initial state
    _status = _connectivityService.isConnected
        ? ConnectivityStatus.online
        : ConnectivityStatus.offline;

    // Listen to connectivity changes
    _connectivitySubscription =
        _connectivityService.onConnectivityChanged.listen(
      _handleConnectivityChange,
    );

    notifyListeners();
  }

  void _handleConnectivityChange(bool isConnected) {
    final wasOnline = _status == ConnectivityStatus.online;

    if (isConnected && !wasOnline) {
      // Transitioning from offline/connecting to online
      _status = ConnectivityStatus.online;
      _connectingTimer?.cancel();
      _connectingTimer = null;
      debugPrint('Network connection restored');
    } else if (!isConnected && wasOnline) {
      // Lost connection - enter connecting state first
      _status = ConnectivityStatus.connecting;
      debugPrint('Network connection lost - attempting to reconnect');

      // After 5 seconds of connecting, change to offline
      _connectingTimer?.cancel();
      _connectingTimer = Timer(const Duration(seconds: 5), () {
        if (_status == ConnectivityStatus.connecting) {
          _status = ConnectivityStatus.offline;
          debugPrint('Connection attempt timed out - now offline');
          notifyListeners();
        }
      });
    }

    notifyListeners();
  }

  /// Manually check connectivity status
  Future<void> checkConnectivity() async {
    // When user manually retries, set to connecting
    if (_status != ConnectivityStatus.online) {
      _status = ConnectivityStatus.connecting;
      notifyListeners();
    }

    final isConnected = await _connectivityService.checkConnectivity();
    _handleConnectivityChange(isConnected);
  }

  @override
  void dispose() {
    _connectivitySubscription?.cancel();
    _connectingTimer?.cancel();
    _connectivityService.dispose();
    super.dispose();
  }
}

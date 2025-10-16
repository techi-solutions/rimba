import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  // Stream controller for connectivity changes
  final _connectivityController = StreamController<bool>.broadcast();
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;
  
  bool _isConnected = true;
  bool get isConnected => _isConnected;
  
  // Timer for periodic connectivity checks
  Timer? _periodicCheckTimer;
  
  /// Initialize the connectivity service and start listening to changes
  Future<void> init() async {
    // Check initial connectivity
    await _updateConnectivityStatus();
    
    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        _handleConnectivityChange(results);
      },
    );
    
    // Start periodic checks (every 5 seconds) to detect network recovery
    _startPeriodicConnectivityCheck();
  }
  
  /// Handle connectivity changes
  void _handleConnectivityChange(List<ConnectivityResult> results) {
    final wasConnected = _isConnected;
    _isConnected = _hasActiveConnection(results);
    
    // Notify listeners if connectivity status changed
    if (wasConnected != _isConnected) {
      debugPrint('Connectivity changed: ${_isConnected ? "Online" : "Offline"}');
      _connectivityController.add(_isConnected);
    }
  }
  
  /// Check if there's an active connection from the results
  bool _hasActiveConnection(List<ConnectivityResult> results) {
    if (results.isEmpty) return false;
    
    // If any result is not 'none', we have connectivity
    return results.any((result) => result != ConnectivityResult.none);
  }
  
  /// Update connectivity status by checking current state
  Future<void> _updateConnectivityStatus() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _handleConnectivityChange(results);
    } catch (e) {
      debugPrint('Error checking connectivity: $e');
      // Assume offline on error
      _isConnected = false;
      _connectivityController.add(false);
    }
  }
  
  /// Start periodic connectivity checks
  void _startPeriodicConnectivityCheck() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = Timer.periodic(
      const Duration(seconds: 5),
      (_) => _updateConnectivityStatus(),
    );
  }
  
  /// Stop periodic connectivity checks
  void _stopPeriodicConnectivityCheck() {
    _periodicCheckTimer?.cancel();
    _periodicCheckTimer = null;
  }
  
  /// Manual check for connectivity (useful after failed requests)
  Future<bool> checkConnectivity() async {
    await _updateConnectivityStatus();
    return _isConnected;
  }
  
  /// Dispose resources
  void dispose() {
    _subscription?.cancel();
    _stopPeriodicConnectivityCheck();
    _connectivityController.close();
  }
}


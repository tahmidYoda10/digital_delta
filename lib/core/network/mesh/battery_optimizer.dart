import '../../utils/app_logger.dart';
import 'dart:async';

class BatteryOptimizer {
  double _currentBatteryLevel = 100.0;
  bool _isStationary = false;
  int _nearbyNodesCount = 0;

  // Default broadcast intervals (ms)
  static const int normalInterval = 5000;
  static const int lowBatteryInterval = 12000; // 60% reduction
  static const int stationaryInterval = 40000;  // 80% reduction
  static const int nearNodesInterval = 10000;   // 50% reduction

  Timer? _batterySimulator;

  /// Initialize battery monitoring
  void initialize() {
    AppLogger.info('🔋 Battery optimizer initialized');

    // Simulate battery drain
    _batterySimulator = Timer.periodic(const Duration(seconds: 10), (timer) {
      _simulateBatteryDrain();
    });
  }

  /// Calculate optimal broadcast interval (M8.4)
  int getOptimalBroadcastInterval() {
    // Priority 1: Low battery (< 30%)
    if (_currentBatteryLevel < 30.0) {
      AppLogger.debug('🔋 Low battery mode: ${lowBatteryInterval}ms interval');
      return lowBatteryInterval;
    }

    // Priority 2: Stationary device
    if (_isStationary) {
      AppLogger.debug('📍 Stationary mode: ${stationaryInterval}ms interval');
      return stationaryInterval;
    }

    // Priority 3: Nearby nodes (reduce redundant broadcasts)
    if (_nearbyNodesCount > 3) {
      AppLogger.debug('📡 Dense network mode: ${nearNodesInterval}ms interval');
      return nearNodesInterval;
    }

    // Default: Normal interval
    return normalInterval;
  }

  /// Update battery level
  void updateBatteryLevel(double level) {
    final oldLevel = _currentBatteryLevel;
    _currentBatteryLevel = level.clamp(0.0, 100.0);

    if (_currentBatteryLevel < 30.0 && oldLevel >= 30.0) {
      AppLogger.warning('⚠️ Battery below 30%, enabling power saving mode');
    }
  }

  /// Update stationary status (from accelerometer)
  void updateStationaryStatus(bool isStationary) {
    _isStationary = isStationary;

    if (isStationary) {
      AppLogger.debug('📍 Device stationary, reducing mesh activity');
    }
  }

  /// Update nearby nodes count
  void updateNearbyNodesCount(int count) {
    _nearbyNodesCount = count;
  }

  /// Simulate battery drain
  void _simulateBatteryDrain() {
    // Drain faster when mesh is active
    final drainRate = _isStationary ? 0.1 : 0.3;
    _currentBatteryLevel = (_currentBatteryLevel - drainRate).clamp(0.0, 100.0);

    if (_currentBatteryLevel < 20.0) {
      AppLogger.warning('🔋 Battery critical: ${_currentBatteryLevel.toStringAsFixed(1)}%');
    }
  }

  /// Get battery savings (for demonstration)
  Map<String, dynamic> getBatterySavings() {
    final currentInterval = getOptimalBroadcastInterval();
    final savingsPercent = ((normalInterval - currentInterval) / normalInterval * 100).abs();

    return {
      'battery_level': _currentBatteryLevel,
      'current_interval_ms': currentInterval,
      'normal_interval_ms': normalInterval,
      'savings_percent': savingsPercent,
      'is_stationary': _isStationary,
      'nearby_nodes': _nearbyNodesCount,
    };
  }

  void dispose() {
    _batterySimulator?.cancel();
  }
}
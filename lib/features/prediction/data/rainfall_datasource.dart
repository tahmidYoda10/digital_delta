import 'dart:async';
import 'dart:math';
import '../../../core/utils/app_logger.dart';
import 'models/rainfall_data.dart';

class RainfallDataSource {
  final Map<String, RainfallData> _currentData = {};
  final Map<String, double> _cumulativeRainfall = {};
  final Map<String, double> _previousRate = {};

  Timer? _simulationTimer;
  final Random _random = Random();

  /// Start rainfall simulation for edges
  void startSimulation(List<String> edgeIds) {
    AppLogger.info('🌧️ Starting rainfall simulation for ${edgeIds.length} edges');

    // Initialize data for each edge
    for (var edgeId in edgeIds) {
      _cumulativeRainfall[edgeId] = 0.0;
      _previousRate[edgeId] = 0.0;

      _currentData[edgeId] = RainfallData(
        edgeId: edgeId,
        rainfallRate: 0.0,
        cumulativeRainfall: 0.0,
        rateOfChange: 0.0,
        elevation: _random.nextDouble() * 500, // Random elevation 0-500m
        soilSaturation: 0.3, // Initial saturation 30%
        timestamp: DateTime.now(),
      );
    }

    // Update every 5 seconds
    _simulationTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _updateRainfall();
    });
  }

  /// Update rainfall data (simulation)
  void _updateRainfall() {
    for (var edgeId in _currentData.keys) {
      final previousRate = _previousRate[edgeId] ?? 0.0;

      // Simulate rainfall rate (0-80 mm/hour with some randomness)
      final newRate = _simulateRainfallRate(previousRate);

      // Update cumulative rainfall
      final intervalHours = 5.0 / 3600.0; // 5 seconds to hours
      _cumulativeRainfall[edgeId] =
          (_cumulativeRainfall[edgeId] ?? 0.0) + (newRate * intervalHours);

      // Calculate rate of change
      final rateOfChange = (newRate - previousRate) / intervalHours;

      // Update soil saturation (increases with cumulative rainfall)
      final saturation = min(1.0, 0.3 + (_cumulativeRainfall[edgeId]! / 200.0));

      // Create new data point
      _currentData[edgeId] = RainfallData(
        edgeId: edgeId,
        rainfallRate: newRate,
        cumulativeRainfall: _cumulativeRainfall[edgeId]!,
        rateOfChange: rateOfChange,
        elevation: _currentData[edgeId]!.elevation,
        soilSaturation: saturation,
        timestamp: DateTime.now(),
      );

      _previousRate[edgeId] = newRate;

      AppLogger.debug('📊 $edgeId: ${newRate.toStringAsFixed(1)} mm/hr, cumulative: ${_cumulativeRainfall[edgeId]!.toStringAsFixed(1)} mm');
    }
  }

  /// Simulate realistic rainfall rate
  double _simulateRainfallRate(double previousRate) {
    // Random walk with tendency to increase during storm
    final change = (_random.nextDouble() - 0.3) * 10.0; // Bias towards increase
    final newRate = (previousRate + change).clamp(0.0, 80.0);

    // Occasionally spike (heavy rainfall burst)
    if (_random.nextDouble() < 0.1) {
      return min(80.0, newRate + _random.nextDouble() * 20.0);
    }

    return newRate;
  }

  /// Get current rainfall data for all edges
  List<RainfallData> getCurrentData() {
    return _currentData.values.toList();
  }

  /// Get data for specific edge
  RainfallData? getDataForEdge(String edgeId) {
    return _currentData[edgeId];
  }

  /// Stop simulation
  void stopSimulation() {
    _simulationTimer?.cancel();
    _simulationTimer = null;
    AppLogger.info('🛑 Rainfall simulation stopped');
  }

  /// Dispose resources
  void dispose() {
    stopSimulation();
    _currentData.clear();
    _cumulativeRainfall.clear();
    _previousRate.clear();
  }
}
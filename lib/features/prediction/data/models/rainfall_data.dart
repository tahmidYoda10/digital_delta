class RainfallData {
  final String edgeId;
  final double rainfallRate; // mm/hour
  final double cumulativeRainfall; // mm
  final double rateOfChange; // mm/hour²
  final double elevation; // meters
  final double soilSaturation; // 0.0 to 1.0
  final DateTime timestamp;

  RainfallData({
    required this.edgeId,
    required this.rainfallRate,
    required this.cumulativeRainfall,
    required this.rateOfChange,
    required this.elevation,
    required this.soilSaturation,
    required this.timestamp,
  });

  /// Convert to feature vector for ML model
  List<double> toFeatures() {
    return [
      rainfallRate / 100.0,        // Normalize to 0-1 (max 100 mm/hr)
      cumulativeRainfall / 500.0,  // Normalize to 0-1 (max 500 mm)
      rateOfChange / 50.0,         // Normalize to 0-1 (max 50 mm/hr²)
      elevation / 1000.0,          // Normalize to 0-1 (max 1000m)
      soilSaturation,              // Already 0-1
    ];
  }

  Map<String, dynamic> toMap() {
    return {
      'edge_id': edgeId,
      'rainfall_rate': rainfallRate,
      'cumulative_rainfall': cumulativeRainfall,
      'rate_of_change': rateOfChange,
      'elevation': elevation,
      'soil_saturation': soilSaturation,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory RainfallData.fromMap(Map<String, dynamic> map) {
    return RainfallData(
      edgeId: map['edge_id'],
      rainfallRate: map['rainfall_rate'].toDouble(),
      cumulativeRainfall: map['cumulative_rainfall'].toDouble(),
      rateOfChange: map['rate_of_change'].toDouble(),
      elevation: map['elevation'].toDouble(),
      soilSaturation: map['soil_saturation'].toDouble(),
      timestamp: DateTime.parse(map['timestamp']),
    );
  }

  @override
  String toString() {
    return 'RainfallData(edge: $edgeId, rate: ${rainfallRate.toStringAsFixed(1)} mm/hr, cumulative: ${cumulativeRainfall.toStringAsFixed(1)} mm)';
  }
}
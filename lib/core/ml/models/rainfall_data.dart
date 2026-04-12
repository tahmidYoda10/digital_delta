class RainfallData {
  final String edgeId;
  final DateTime timestamp;
  final double rainfallRateMmPerHour;
  final double cumulativeRainfallMm;
  final double elevationMeters;
  final double soilSaturationPercent;
  final double temperatureCelsius;

  RainfallData({
    required this.edgeId,
    required this.timestamp,
    required this.rainfallRateMmPerHour,
    required this.cumulativeRainfallMm,
    required this.elevationMeters,
    required this.soilSaturationPercent,
    required this.temperatureCelsius,
  });

  /// Convert to feature vector for ML (M7.1)
  List<double> toFeatureVector() {
    return [
      rainfallRateMmPerHour,
      cumulativeRainfallMm,
      _calculateRateOfChange(),
      elevationMeters,
      soilSaturationPercent,
    ];
  }

  /// Calculate rate of change (simplified - would use time series in production)
  double _calculateRateOfChange() {
    // In production, compare with previous reading
    // For now, use rainfall rate as proxy
    return rainfallRateMmPerHour / 10.0;
  }

  Map<String, dynamic> toMap() {
    return {
      'edge_id': edgeId,
      'timestamp': timestamp.toIso8601String(),
      'rainfall_rate': rainfallRateMmPerHour,
      'cumulative_rainfall': cumulativeRainfallMm,
      'elevation': elevationMeters,
      'soil_saturation': soilSaturationPercent,
      'temperature': temperatureCelsius,
    };
  }

  factory RainfallData.fromMap(Map<String, dynamic> map) {
    return RainfallData(
      edgeId: map['edge_id'],
      timestamp: DateTime.parse(map['timestamp']),
      rainfallRateMmPerHour: map['rainfall_rate'].toDouble(),
      cumulativeRainfallMm: map['cumulative_rainfall'].toDouble(),
      elevationMeters: map['elevation'].toDouble(),
      soilSaturationPercent: map['soil_saturation'].toDouble(),
      temperatureCelsius: map['temperature']?.toDouble() ?? 25.0,
    );
  }

  @override
  String toString() {
    return 'RainfallData(edge: $edgeId, rate: ${rainfallRateMmPerHour}mm/h, cumulative: ${cumulativeRainfallMm}mm)';
  }
}
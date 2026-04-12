class FeatureExtractor {
  /// Get feature names for model
  List<String> getFeatureNames() {
    return [
      'rainfall_rate',
      'cumulative_rainfall',
      'rate_of_change',
      'elevation',
      'soil_saturation',
    ];
  }

  /// Extract features from raw data
  List<double> extract(Map<String, dynamic> rawData) {
    return [
      (rawData['rainfall_rate'] ?? 0.0) / 100.0,
      (rawData['cumulative_rainfall'] ?? 0.0) / 500.0,
      (rawData['rate_of_change'] ?? 0.0) / 50.0,
      (rawData['elevation'] ?? 0.0) / 1000.0,
      (rawData['soil_saturation'] ?? 0.0),
    ];
  }
}
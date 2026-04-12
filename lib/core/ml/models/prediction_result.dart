class PredictionResult {
  final String edgeId;
  final double probability; // 0.0 to 1.0
  final DateTime predictedAt;
  final DateTime? impassableBy;
  final List<double> features;
  final Map<String, double> featureImportance;

  PredictionResult({
    required this.edgeId,
    required this.probability,
    required this.predictedAt,
    this.impassableBy,
    required this.features,
    this.featureImportance = const {},
  });

  /// Check if edge is high risk (> 70%)
  bool isHighRisk() => probability > 0.7;

  /// Get risk level
  String getRiskLevel() {
    if (probability < 0.3) return 'LOW';
    if (probability < 0.7) return 'MEDIUM';
    return 'HIGH';
  }

  /// Get color for UI
  String getRiskColor() {
    if (probability < 0.3) return 'green';
    if (probability < 0.7) return 'orange';
    return 'red';
  }

  Map<String, dynamic> toMap() {
    return {
      'edge_id': edgeId,
      'probability': probability,
      'predicted_at': predictedAt.toIso8601String(),
      'impassable_by': impassableBy?.toIso8601String(),
      'features': features,
      'feature_importance': featureImportance,
    };
  }

  @override
  String toString() {
    return 'PredictionResult(edge: $edgeId, risk: ${(probability * 100).toStringAsFixed(1)}%, level: ${getRiskLevel()})';
  }
}
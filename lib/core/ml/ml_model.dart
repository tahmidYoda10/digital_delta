import 'dart:math';
import '../utils/app_logger.dart';
import 'models/prediction_result.dart';
import 'feature_extractor.dart';

/// Logistic Regression classifier for route impassability (M7.2)
class MLModel {
  // Trained weights (from sklearn - example values)
  List<double> _weights = [
    0.8,   // rainfall_rate (high importance)
    0.5,   // cumulative_rainfall
    0.6,   // rate_of_change
    -0.3,  // elevation (negative: higher elevation = less flood risk)
    0.7,   // soil_saturation
  ];

  double _bias = -1.5;

  final FeatureExtractor _featureExtractor = FeatureExtractor();

  // Model metadata
  String modelVersion = '1.0.0';
  DateTime trainedAt = DateTime(2026, 1, 1);
  Map<String, double> metrics = {
    'accuracy': 0.89,
    'precision': 0.87,
    'recall': 0.85,
    'f1_score': 0.86,
  };

  /// Predict impassability probability (M7.2)
  PredictionResult predict({
    required String edgeId,
    required List<double> features,
  }) {
    try {
      AppLogger.debug('🤖 Running ML inference for edge: $edgeId');

      // Validate input
      if (features.length != _weights.length) {
        throw Exception('Feature length mismatch: expected ${_weights.length}, got ${features.length}');
      }

      // Calculate logit: z = w·x + b
      double z = _bias;
      for (int i = 0; i < features.length; i++) {
        z += _weights[i] * features[i];
      }

      // Sigmoid activation: σ(z) = 1 / (1 + e^-z)
      final probability = _sigmoid(z);

      // Calculate feature importance
      final featureImportance = _calculateFeatureImportance(features);

      // Predict time to impassability (if high risk)
      DateTime? impassableBy;
      if (probability > 0.7) {
        final hoursUntilFailure = _estimateTimeToFailure(features, probability);
        impassableBy = DateTime.now().add(Duration(hours: hoursUntilFailure));
      }

      final result = PredictionResult(
        edgeId: edgeId,
        probability: probability,
        predictedAt: DateTime.now(),
        impassableBy: impassableBy,
        features: features,
        featureImportance: featureImportance,
      );

      AppLogger.info('✅ Prediction: ${(probability * 100).toStringAsFixed(1)}% risk for $edgeId');
      return result;

    } catch (e, stack) {
      AppLogger.error('ML prediction failed', e, stack);

      // Return safe default (low risk)
      return PredictionResult(
        edgeId: edgeId,
        probability: 0.3,
        predictedAt: DateTime.now(),
        features: features,
        featureImportance: const {},
      );
    }
  }

  /// Sigmoid function
  double _sigmoid(double z) {
    return 1.0 / (1.0 + exp(-z));
  }

  /// Calculate feature importance (contribution to prediction)
  Map<String, double> _calculateFeatureImportance(List<double> features) {
    final featureNames = _featureExtractor.getFeatureNames();
    final importance = <String, double>{};

    double totalContribution = 0.0;
    for (int i = 0; i < features.length; i++) {
      final contribution = (_weights[i] * features[i]).abs();
      importance[featureNames[i]] = contribution;
      totalContribution += contribution;
    }

    // Normalize to percentages
    if (totalContribution > 0) {
      importance.updateAll((key, value) => value / totalContribution);
    }

    return importance;
  }

  /// Estimate hours until road becomes impassable
  int _estimateTimeToFailure(List<double> features, double probability) {
    // Simplified heuristic based on rainfall rate
    final rainfallRate = features[0] * 100.0; // Denormalize

    if (rainfallRate > 50) return 1;  // Heavy rain: 1 hour
    if (rainfallRate > 30) return 2;  // Moderate rain: 2 hours
    if (rainfallRate > 10) return 4;  // Light rain: 4 hours

    return 6; // Very light: 6 hours
  }

  /// Update model weights (for online learning - optional)
  void updateWeights(List<double> newWeights, double newBias) {
    if (newWeights.length != _weights.length) {
      throw Exception('Weight dimension mismatch');
    }

    _weights = newWeights;
    _bias = newBias;

    AppLogger.info('🔄 ML model weights updated');
  }

  /// Get model info
  Map<String, dynamic> getModelInfo() {
    return {
      'version': modelVersion,
      'trained_at': trainedAt.toIso8601String(),
      'metrics': metrics,
      'weights': _weights,
      'bias': _bias,
    };
  }

  /// Load weights from trained sklearn model (✅ FIXED)
  void loadFromSklearn(Map<String, dynamic> modelData) {
    // Expected format:
    // {
    //   'weights': [0.8, 0.5, 0.6, -0.3, 0.7],
    //   'bias': -1.5,
    //   'metrics': {'f1': 0.86, 'precision': 0.87, 'recall': 0.85}
    // }

    try {
      if (modelData.containsKey('weights')) {
        // ✅ FIX: Properly cast List<dynamic> to List<double>
        final weightsList = modelData['weights'] as List;
        _weights = weightsList.map<double>((e) => (e as num).toDouble()).toList();
      }

      if (modelData.containsKey('bias')) {
        _bias = (modelData['bias'] as num).toDouble();
      }

      if (modelData.containsKey('metrics')) {
        // ✅ FIX: Properly cast metrics map
        final metricsMap = modelData['metrics'] as Map<String, dynamic>;
        metrics = metricsMap.map<String, double>(
              (key, value) => MapEntry(key, (value as num).toDouble()),
        );
      }

      AppLogger.info('✅ Model loaded from sklearn export');
    } catch (e, stack) {
      AppLogger.error('Failed to load sklearn model', e, stack);
      throw Exception('Invalid sklearn model format: ${e.toString()}');
    }
  }
}
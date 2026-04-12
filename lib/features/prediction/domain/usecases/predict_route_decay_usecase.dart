import '../../../../core/ml/ml_model.dart';
import '../../../../core/ml/feature_extractor.dart';
import '../../../../core/ml/models/prediction_result.dart';
import '../../../../core/routing/graph_manager.dart';
import '../../../../core/utils/app_logger.dart';
import '../../data/models/rainfall_data.dart';

class PredictRouteDecayUseCase {
  final MLModel _mlModel;
  final FeatureExtractor _featureExtractor;
  final GraphManager _graphManager;

  PredictRouteDecayUseCase({
    required MLModel mlModel,
    required FeatureExtractor featureExtractor,
    required GraphManager graphManager,
  })  : _mlModel = mlModel,
        _featureExtractor = featureExtractor,
        _graphManager = graphManager;

  /// Predict route decay for all edges with rainfall data
  Future<List<PredictionResult>> predictAll(List<RainfallData> rainfallData) async {
    final predictions = <PredictionResult>[];

    for (var data in rainfallData) {
      try {
        // Extract features
        final features = data.toFeatures();

        // Run ML prediction
        final prediction = _mlModel.predict(
          edgeId: data.edgeId,
          features: features,
        );

        predictions.add(prediction);

        // Update graph if high risk
        if (prediction.isHighRisk()) {
          await _graphManager.updateEdge(
            data.edgeId,
            riskScore: prediction.probability,
          );
        }

      } catch (e, stack) {
        AppLogger.error('Prediction failed for edge ${data.edgeId}', e, stack);
      }
    }

    return predictions;
  }

  /// Predict for single edge
  Future<PredictionResult?> predictForEdge(RainfallData data) async {
    try {
      final features = data.toFeatures();
      return _mlModel.predict(edgeId: data.edgeId, features: features);
    } catch (e) {
      AppLogger.error('Prediction failed for ${data.edgeId}', e);
      return null;
    }
  }
}
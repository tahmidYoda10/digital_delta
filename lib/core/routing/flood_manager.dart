import 'dart:async';
import '../utils/app_logger.dart';
import 'graph_manager.dart';
import 'models/graph_edge.dart';

/// Manages flood events and triggers route recalculation
class FloodManager {
  final GraphManager _graphManager;
  final StreamController<FloodEvent> _floodEventController = StreamController.broadcast();

  FloodManager({required GraphManager graphManager}) : _graphManager = graphManager;

  /// Stream of flood events for UI updates
  Stream<FloodEvent> get floodEvents => _floodEventController.stream;

  /// Handle edge flooding (triggered by Chaos Server or ML prediction)
  Future<void> handleFloodEvent({
    required String edgeId,
    required FloodSource source,
    double? predictedRisk,
  }) async {
    final edge = _graphManager.edges.firstWhere(
          (e) => e.id == edgeId,
      orElse: () => throw Exception('Edge $edgeId not found'),
    );

    AppLogger.warning(
        '🌊 FLOOD EVENT: ${edge.id} (${edge.sourceId}→${edge.targetId}) '
            'Source: ${source.name}, Risk: ${predictedRisk ?? "N/A"}'
    );

    // Update edge weight based on source
    double newWeight;
    double newRisk;
    bool flooded;

    if (source == FloodSource.chaosServer) {
      // Actual flood from Chaos Server
      flooded = true;
      newWeight = 9999.0; // Impassable
      newRisk = 1.0;
    } else if (source == FloodSource.mlPrediction) {
      // Predicted risk from ML
      flooded = false;
      newRisk = predictedRisk ?? 0.5;
      // Increase weight based on risk (e.g., 2x multiplier at 100% risk)
      newWeight = edge.baseWeight * (1.0 + newRisk);
    } else {
      // Manual override
      flooded = true;
      newWeight = 9999.0;
      newRisk = 1.0;
    }

    // Update in graph
    await _graphManager.updateEdge(
      edgeId,
      isFlooded: flooded,
      currentWeight: newWeight,
      riskScore: newRisk,
    );

    // Emit event for listeners (UI, BLoC, etc.)
    _floodEventController.add(FloodEvent(
      edgeId: edgeId,
      source: source,
      timestamp: DateTime.now(),
      isFlooded: flooded,
      riskScore: newRisk,
      affectedRoutes: _findAffectedRoutes(edgeId),
    ));

    AppLogger.info('✅ Flood event processed: $edgeId');
  }

  /// Find routes that use this edge (for reroute notifications)
  List<String> _findAffectedRoutes(String edgeId) {
    // TODO: Integrate with active delivery tracking
    // For now, return empty list
    return [];
  }

  /// Get all currently flooded edges
  List<GraphEdge> getFloodedEdges() {
    return _graphManager.getFloodedEdges();
  }

  /// Get edges at risk (ML predicted)
  List<GraphEdge> getRiskyEdges({double threshold = 0.5}) {
    return _graphManager.edges
        .where((e) => !e.isFlooded && e.riskScore >= threshold)
        .toList();
  }

  void dispose() {
    _floodEventController.close();
  }
}

/// Flood event data
class FloodEvent {
  final String edgeId;
  final FloodSource source;
  final DateTime timestamp;
  final bool isFlooded;
  final double riskScore;
  final List<String> affectedRoutes;

  FloodEvent({
    required this.edgeId,
    required this.source,
    required this.timestamp,
    required this.isFlooded,
    required this.riskScore,
    required this.affectedRoutes,
  });
}

/// Source of flood information
enum FloodSource {
  chaosServer,    // Random simulation
  mlPrediction,   // ML rainfall model
  manualOverride, // Admin action
}

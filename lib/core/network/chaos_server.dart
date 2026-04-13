import 'dart:async';
import 'dart:math';
import '../utils/app_logger.dart';
import '../routing/graph_manager.dart';
import '../routing/models/graph_edge.dart';

/// M4 - Chaos Server: Simulates random flooding every 30 seconds
class ChaosServer {
  final GraphManager _graphManager;
  final Random _random = Random();
  Timer? _chaosTimer;

  // Track flooded edges to unfold them later
  final Set<String> _currentlyFloodedEdges = {};

  // Chaos configuration
  final Duration floodInterval;
  final Duration floodDuration;
  final double floodProbability;

  ChaosServer({
    required GraphManager graphManager,
    this.floodInterval = const Duration(seconds: 30),
    this.floodDuration = const Duration(minutes: 5),
    this.floodProbability = 0.3, // 30% chance per interval
  }) : _graphManager = graphManager;

  /// Start chaos simulation
  void start() {
    if (_chaosTimer != null) {
      AppLogger.warning('⚡ Chaos Server already running');
      return;
    }

    AppLogger.info('⚡ CHAOS SERVER STARTED - Flooding every ${floodInterval.inSeconds}s');

    _chaosTimer = Timer.periodic(floodInterval, (_) => _triggerChaosEvent());
  }

  /// Stop chaos simulation
  void stop() {
    _chaosTimer?.cancel();
    _chaosTimer = null;
    AppLogger.info('⚡ Chaos Server stopped');
  }

  /// Trigger random flooding event
  Future<void> _triggerChaosEvent() async {
    if (_random.nextDouble() > floodProbability) {
      AppLogger.info('⚡ Chaos check: No flooding this time');
      return;
    }

    final availableEdges = _graphManager.edges
        .where((e) => !e.isFlooded && !_currentlyFloodedEdges.contains(e.id))
        .toList();

    if (availableEdges.isEmpty) {
      AppLogger.warning('⚡ No available edges to flood');
      return;
    }

    // Pick random edge
    final targetEdge = availableEdges[_random.nextInt(availableEdges.length)];

    await _floodEdge(targetEdge);
  }

  /// Flood a specific edge
  Future<void> _floodEdge(GraphEdge edge) async {
    AppLogger.warning('🌊 CHAOS EVENT: Flooding ${edge.id} (${edge.sourceId} → ${edge.targetId})');

    // Update edge to flooded state
    await _graphManager.updateEdge(
      edge.id,
      isFlooded: true,
      currentWeight: 9999.0, // Make impassable
      riskScore: 1.0,
    );

    _currentlyFloodedEdges.add(edge.id);

    // Schedule unflooding
    Future.delayed(floodDuration, () => _unfloodEdge(edge.id));
  }

  /// Restore edge after flood duration
  Future<void> _unfloodEdge(String edgeId) async {
    AppLogger.info('🌤️ CHAOS RECOVERY: Unflooding $edgeId');

    final edge = _graphManager.edges.firstWhere((e) => e.id == edgeId);

    await _graphManager.updateEdge(
      edgeId,
      isFlooded: false,
      currentWeight: edge.baseWeight,
      riskScore: 0.0,
    );

    _currentlyFloodedEdges.remove(edgeId);
  }

  /// Manually flood specific edge (for testing)
  Future<void> manualFlood(String edgeId, {Duration? duration}) async {
    final edge = _graphManager.edges.firstWhere(
          (e) => e.id == edgeId,
      orElse: () => throw Exception('Edge $edgeId not found'),
    );

    await _floodEdge(edge);

    if (duration != null) {
      Future.delayed(duration, () => _unfloodEdge(edgeId));
    }
  }

  /// Get current flood status
  Map<String, dynamic> getFloodStatus() {
    return {
      'total_edges': _graphManager.edges.length,
      'flooded_edges': _currentlyFloodedEdges.length,
      'flooded_edge_ids': _currentlyFloodedEdges.toList(),
      'chaos_active': _chaosTimer?.isActive ?? false,
    };
  }

  void dispose() {
    stop();
  }
}
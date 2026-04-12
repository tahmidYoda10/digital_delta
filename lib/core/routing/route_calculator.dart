import 'dart:collection';
import 'dart:math';
import 'package:uuid/uuid.dart';
import '../utils/app_logger.dart';
import 'models/graph_node.dart';
import 'models/graph_edge.dart';
import 'models/route.dart';
import 'vehicle_constraints.dart';

class RouteCalculator {
  final Map<String, GraphNode> _nodes;
  final Map<String, List<GraphEdge>> _adjacencyList;
  final Uuid _uuid = const Uuid();

  RouteCalculator({
    required Map<String, GraphNode> nodes,
    required List<GraphEdge> edges,
  })  : _nodes = nodes,
        _adjacencyList = {} {
    _buildAdjacencyList(edges);
  }

  /// Build adjacency list for fast lookup (✅ BIDIRECTIONAL EDGES)
  void _buildAdjacencyList(List<GraphEdge> edges) {
    for (var edge in edges) {
      // Forward direction
      _adjacencyList.putIfAbsent(edge.sourceId, () => []).add(edge);

      // ✅ ADD REVERSE DIRECTION (critical for graph connectivity)
      final reverseEdge = GraphEdge(
        id: '${edge.id}_reverse',
        sourceId: edge.targetId,
        targetId: edge.sourceId,
        edgeType: edge.edgeType,
        baseWeight: edge.baseWeight,
        currentWeight: edge.currentWeight,
        isFlooded: edge.isFlooded,
        riskScore: edge.riskScore,
      );
      _adjacencyList.putIfAbsent(edge.targetId, () => []).add(reverseEdge);
    }
  }

  /// Calculate shortest path using Dijkstra's algorithm (M4.2)
  Route? calculateRoute({
    required String startNodeId,
    required String endNodeId,
    required VehicleConstraints vehicleConstraints,
    bool includeRiskScores = true,
  }) {
    final stopwatch = Stopwatch()..start();

    try {
      AppLogger.info('🗺️ Calculating route: $startNodeId → $endNodeId');

      // Validate nodes
      if (!_nodes.containsKey(startNodeId) || !_nodes.containsKey(endNodeId)) {
        AppLogger.warning('Invalid start or end node');
        return null;
      }

      // ✅ CHECK IF NODES ARE THE SAME
      if (startNodeId == endNodeId) {
        AppLogger.warning('Start and end nodes are the same');
        return Route(
          id: _uuid.v4(),
          nodes: [_nodes[startNodeId]!],
          edges: [],
          vehicleConstraints: vehicleConstraints,
          totalDistance: 0.0,
          estimatedTime: 0.0,
          calculatedAt: DateTime.now(),
          isValid: true,
        );
      }

      // Initialize distances and previous nodes
      final distances = <String, double>{};
      final previous = <String, String?>{};
      final visited = <String>{};
      final priorityQueue = PriorityQueue<_NodeDistance>();

      for (var nodeId in _nodes.keys) {
        distances[nodeId] = double.infinity;
        previous[nodeId] = null;
      }
      distances[startNodeId] = 0.0;
      priorityQueue.add(_NodeDistance(startNodeId, 0.0));

      // Dijkstra's algorithm
      while (priorityQueue.isNotEmpty) {
        final current = priorityQueue.removeFirst();
        final currentNodeId = current.nodeId;

        if (visited.contains(currentNodeId)) continue;
        visited.add(currentNodeId);

        if (currentNodeId == endNodeId) break; // Found shortest path

        // Explore neighbors
        final neighbors = _adjacencyList[currentNodeId] ?? [];

        for (var edge in neighbors) {
          // Check vehicle constraints (M4.3)
          if (!vehicleConstraints.canUseEdge(edge)) {
            continue;
          }

          final neighborId = edge.targetId;
          if (visited.contains(neighborId)) continue;

          final weight = edge.getEffectiveWeight(includeRisk: includeRiskScores);
          final newDistance = distances[currentNodeId]! + weight;

          if (newDistance < distances[neighborId]!) {
            distances[neighborId] = newDistance;
            previous[neighborId] = currentNodeId;
            priorityQueue.add(_NodeDistance(neighborId, newDistance));
          }
        }
      }

      stopwatch.stop();

      // Reconstruct path
      if (distances[endNodeId] == double.infinity) {
        AppLogger.warning('❌ No path found (took ${stopwatch.elapsedMilliseconds}ms)');
        return Route(
          id: _uuid.v4(),
          nodes: [],
          edges: [],
          vehicleConstraints: vehicleConstraints,
          totalDistance: 0.0,
          estimatedTime: 0.0,
          calculatedAt: DateTime.now(),
          isValid: false,
          invalidReason: 'No valid path found for ${vehicleConstraints.vehicleType}',
        );
      }

      final path = _reconstructPath(previous, endNodeId);
      final routeEdges = _getEdgesForPath(path);
      final routeNodes = path.map((id) => _nodes[id]!).toList();

      final totalTime = distances[endNodeId]!;
      final totalDistance = _calculateTotalDistance(routeNodes);

      AppLogger.info('✅ Route calculated in ${stopwatch.elapsedMilliseconds}ms: ${path.length} nodes, ${totalTime.toStringAsFixed(1)} min');

      return Route(
        id: _uuid.v4(),
        nodes: routeNodes,
        edges: routeEdges,
        vehicleConstraints: vehicleConstraints,
        totalDistance: totalDistance,
        estimatedTime: totalTime,
        calculatedAt: DateTime.now(),
        isValid: true,
      );

    } catch (e, stack) {
      AppLogger.error('Route calculation failed', e, stack);
      return null;
    }
  }

  /// Reconstruct path from previous map
  List<String> _reconstructPath(Map<String, String?> previous, String endNodeId) {
    final path = <String>[];
    String? current = endNodeId;

    while (current != null) {
      path.insert(0, current);
      current = previous[current];
    }

    return path;
  }

  /// Get edges for a given path
  List<GraphEdge> _getEdgesForPath(List<String> path) {
    final edges = <GraphEdge>[];

    for (var i = 0; i < path.length - 1; i++) {
      final sourceId = path[i];
      final targetId = path[i + 1];

      final edge = (_adjacencyList[sourceId] ?? [])
          .firstWhere((e) => e.targetId == targetId);
      edges.add(edge);
    }

    return edges;
  }

  /// Calculate total distance using Haversine formula
  double _calculateTotalDistance(List<GraphNode> nodes) {
    double totalKm = 0.0;

    for (var i = 0; i < nodes.length - 1; i++) {
      final from = nodes[i].position;
      final to = nodes[i + 1].position;
      totalKm += _haversineDistance(from.latitude, from.longitude, to.latitude, to.longitude);
    }

    return totalKm;
  }

  /// Haversine distance formula
  double _haversineDistance(double lat1, double lon1, double lat2, double lon2) {
    const R = 6371.0; // Earth radius in km
    final dLat = _toRadians(lat2 - lat1);
    final dLon = _toRadians(lon2 - lon1);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) * cos(_toRadians(lat2)) *
            sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180.0;
}

/// Helper class for priority queue
class _NodeDistance implements Comparable<_NodeDistance> {
  final String nodeId;
  final double distance;

  _NodeDistance(this.nodeId, this.distance);

  @override
  int compareTo(_NodeDistance other) => distance.compareTo(other.distance);
}

/// Simple priority queue implementation
class PriorityQueue<T extends Comparable> {
  final List<T> _heap = [];

  void add(T value) {
    _heap.add(value);
    _heap.sort();
  }

  T removeFirst() => _heap.removeAt(0);

  bool get isNotEmpty => _heap.isNotEmpty;
  bool get isEmpty => _heap.isEmpty;
}
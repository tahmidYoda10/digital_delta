import 'graph_node.dart';
import 'graph_edge.dart';
import '../vehicle_constraints.dart';

class Route {
  final String id;
  final List<GraphNode> nodes;
  final List<GraphEdge> edges;
  final VehicleConstraints vehicleConstraints;
  final double totalDistance;
  final double estimatedTime; // minutes
  final DateTime calculatedAt;
  final bool isValid;
  final String? invalidReason;

  Route({
    required this.id,
    required this.nodes,
    required this.edges,
    required this.vehicleConstraints,
    required this.totalDistance,
    required this.estimatedTime,
    required this.calculatedAt,
    this.isValid = true,
    this.invalidReason,
  });

  /// Get ETA
  DateTime getETA() {
    return calculatedAt.add(Duration(minutes: estimatedTime.round()));
  }

  /// Check if route is stale (needs recalculation)
  bool isStale({Duration threshold = const Duration(minutes: 5)}) {
    return DateTime.now().difference(calculatedAt) > threshold;
  }

  /// Get path as list of node IDs
  List<String> getNodeIds() {
    return nodes.map((n) => n.id).toList();
  }

  /// Get path as list of edge IDs
  List<String> getEdgeIds() {
    return edges.map((e) => e.id).toList();
  }

  @override
  String toString() {
    return 'Route(nodes: ${nodes.length}, distance: ${totalDistance.toStringAsFixed(1)} km, time: ${estimatedTime.toStringAsFixed(0)} min, valid: $isValid)';
  }

  Route copyWith({
    String? id,
    List<GraphNode>? nodes,
    List<GraphEdge>? edges,
    VehicleConstraints? vehicleConstraints,
    double? totalDistance,
    double? estimatedTime,
    DateTime? calculatedAt,
    bool? isValid,
    String? invalidReason,
  }) {
    return Route(
      id: id ?? this.id,
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      vehicleConstraints: vehicleConstraints ?? this.vehicleConstraints,
      totalDistance: totalDistance ?? this.totalDistance,
      estimatedTime: estimatedTime ?? this.estimatedTime,
      calculatedAt: calculatedAt ?? this.calculatedAt,
      isValid: isValid ?? this.isValid,
      invalidReason: invalidReason ?? this.invalidReason,
    );
  }
}
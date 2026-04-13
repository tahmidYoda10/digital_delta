import 'package:equatable/equatable.dart';
import '../../../../core/routing/models/route.dart';
import '../../../../core/routing/models/graph_node.dart';
import '../../../../core/routing/models/graph_edge.dart';

abstract class RoutingState extends Equatable {
  const RoutingState();

  @override
  List<Object?> get props => [];
}

class RoutingInitial extends RoutingState {}

class RoutingLoading extends RoutingState {}

class RoutingReady extends RoutingState {
  final Map<String, GraphNode> nodes;
  final List<GraphEdge> edges;
  final bool chaosActive;

  const RoutingReady({
    required this.nodes,
    required this.edges,
    this.chaosActive = false,
  });

  @override
  List<Object?> get props => [nodes, edges, chaosActive];

  RoutingReady copyWith({
    Map<String, GraphNode>? nodes,
    List<GraphEdge>? edges,
    bool? chaosActive,
  }) {
    return RoutingReady(
      nodes: nodes ?? this.nodes,
      edges: edges ?? this.edges,
      chaosActive: chaosActive ?? this.chaosActive,
    );
  }
}

class RoutingCalculated extends RoutingState {
  final Route route;
  final Duration calculationTime;
  final bool chaosActive;
  final List<GraphEdge> allEdges; // ✅ ADD THIS

  const RoutingCalculated({
    required this.route,
    required this.calculationTime,
    this.chaosActive = false,
    required this.allEdges, // ✅ ADD THIS
  });

  @override
  List<Object?> get props => [route, calculationTime, chaosActive, allEdges];

  RoutingCalculated copyWith({
    Route? route,
    Duration? calculationTime,
    bool? chaosActive,
    List<GraphEdge>? allEdges,
  }) {
    return RoutingCalculated(
      route: route ?? this.route,
      calculationTime: calculationTime ?? this.calculationTime,
      chaosActive: chaosActive ?? this.chaosActive,
      allEdges: allEdges ?? this.allEdges, // ✅ ADD THIS
    );
  }
}

class RoutingError extends RoutingState {
  final String message;

  const RoutingError(this.message);

  @override
  List<Object?> get props => [message];
}

class RoutingEdgeUpdated extends RoutingState {
  final String edgeId;
  final String message;

  const RoutingEdgeUpdated({
    required this.edgeId,
    required this.message,
  });

  @override
  List<Object?> get props => [edgeId, message];
}
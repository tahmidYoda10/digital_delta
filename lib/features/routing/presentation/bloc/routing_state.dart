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

  const RoutingReady({
    required this.nodes,
    required this.edges,
  });

  @override
  List<Object?> get props => [nodes, edges];
}

class RoutingCalculated extends RoutingState {
  final Route route;
  final Duration calculationTime;

  const RoutingCalculated({
    required this.route,
    required this.calculationTime,
  });

  @override
  List<Object?> get props => [route, calculationTime];
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

class RoutingError extends RoutingState {
  final String message;

  const RoutingError(this.message);

  @override
  List<Object?> get props => [message];
}
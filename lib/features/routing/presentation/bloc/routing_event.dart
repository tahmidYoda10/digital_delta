import 'package:equatable/equatable.dart';
import '../../../../core/routing/vehicle_constraints.dart';

abstract class RoutingEvent extends Equatable {
  const RoutingEvent();

  @override
  List<Object?> get props => [];
}

class RoutingInitializeRequested extends RoutingEvent {}

class RoutingCalculateRouteRequested extends RoutingEvent {
  final String startNodeId;
  final String endNodeId;
  final VehicleConstraints vehicleConstraints;

  const RoutingCalculateRouteRequested({
    required this.startNodeId,
    required this.endNodeId,
    required this.vehicleConstraints,
  });

  @override
  List<Object?> get props => [startNodeId, endNodeId, vehicleConstraints];
}

class RoutingUpdateEdgeRequested extends RoutingEvent {
  final String edgeId;
  final bool? isFlooded;
  final double? riskScore;

  const RoutingUpdateEdgeRequested({
    required this.edgeId,
    this.isFlooded,
    this.riskScore,
  });

  @override
  List<Object?> get props => [edgeId, isFlooded, riskScore];
}

class RoutingLoadGraphRequested extends RoutingEvent {
  final Map<String, dynamic> graphJson;

  const RoutingLoadGraphRequested(this.graphJson);

  @override
  List<Object?> get props => [graphJson];
}

// ✅ NEW: Chaos control events
class RoutingStartChaosRequested extends RoutingEvent {
  @override
  List<Object?> get props => [];
}

class RoutingStopChaosRequested extends RoutingEvent {
  @override
  List<Object?> get props => [];
}

// ✅ NEW: Auto-reroute event (triggered by flood)
class RoutingAutoRerouteRequested extends RoutingEvent {
  final String floodedEdgeId;
  final String startNodeId;
  final String endNodeId;
  final VehicleConstraints vehicleConstraints;

  const RoutingAutoRerouteRequested({
    required this.floodedEdgeId,
    required this.startNodeId,
    required this.endNodeId,
    required this.vehicleConstraints,
  });

  @override
  List<Object?> get props => [floodedEdgeId, startNodeId, endNodeId, vehicleConstraints];
}
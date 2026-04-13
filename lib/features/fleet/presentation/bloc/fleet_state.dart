import '../../../../core/fleet/models/drone_model.dart';
import '../../../../core/fleet/models/rendezvous_point.dart';
import '../../../../core/fleet/models/handoff_event.dart';

abstract class FleetState {}

class FleetInitial extends FleetState {}

class FleetLoading extends FleetState {}

class FleetReady extends FleetState {
  final List<DroneModel> drones;

  FleetReady({this.drones = const []});
}

class FleetLoaded extends FleetState {
  final List<DroneModel> drones;

  FleetLoaded({required this.drones});
}

class FleetRendezvousCalculated extends FleetState {
  final RendezvousPoint rendezvousPoint;

  FleetRendezvousCalculated({required this.rendezvousPoint});
}

class FleetHandoffInProgress extends FleetState {
  final String deliveryId;
  final HandoffEvent handoff;

  FleetHandoffInProgress({
    required this.deliveryId,
    required this.handoff,
  });
}

class FleetHandoffCompleted extends FleetState {
  final String deliveryId;

  FleetHandoffCompleted({required this.deliveryId});
}

class FleetError extends FleetState {
  final String message;

  FleetError({required this.message});
}
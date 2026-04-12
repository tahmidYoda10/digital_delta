import 'package:equatable/equatable.dart';
import '../../../../core/fleet/models/rendezvous_point.dart';
import '../../../../core/fleet/models/drone_model.dart';
import '../../../../core/fleet/models/handoff_event.dart';

abstract class FleetState extends Equatable {
  const FleetState();

  @override
  List<Object?> get props => [];
}

class FleetInitial extends FleetState {}

class FleetLoading extends FleetState {}

class FleetReady extends FleetState {
  final List<DroneModel> drones;

  const FleetReady(this.drones);

  @override
  List<Object?> get props => [drones];
}

class FleetRendezvousCalculated extends FleetState {
  final RendezvousPoint rendezvousPoint;

  const FleetRendezvousCalculated(this.rendezvousPoint);

  @override
  List<Object?> get props => [rendezvousPoint];
}

class FleetHandoffInProgress extends FleetState {
  final HandoffEvent handoff;

  const FleetHandoffInProgress(this.handoff);

  @override
  List<Object?> get props => [handoff];
}

class FleetHandoffCompleted extends FleetState {
  final HandoffEvent handoff;

  const FleetHandoffCompleted(this.handoff);

  @override
  List<Object?> get props => [handoff];
}

class FleetError extends FleetState {
  final String message;

  const FleetError(this.message);

  @override
  List<Object?> get props => [message];
}
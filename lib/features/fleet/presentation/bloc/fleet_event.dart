import 'package:equatable/equatable.dart';
import 'package:latlong2/latlong.dart';

abstract class FleetEvent extends Equatable {
  const FleetEvent();

  @override
  List<Object?> get props => [];
}

class FleetInitializeRequested extends FleetEvent {}

class FleetCalculateRendezvousRequested extends FleetEvent {
  final LatLng boatPosition;
  final LatLng droneBasePosition;
  final LatLng destinationPosition;
  final String droneId;

  const FleetCalculateRendezvousRequested({
    required this.boatPosition,
    required this.droneBasePosition,
    required this.destinationPosition,
    required this.droneId,
  });

  @override
  List<Object?> get props => [boatPosition, droneBasePosition, destinationPosition, droneId];
}

class FleetExecuteHandoffRequested extends FleetEvent {
  final String deliveryId;

  const FleetExecuteHandoffRequested(this.deliveryId);

  @override
  List<Object?> get props => [deliveryId];
}

class FleetDroneStatusUpdated extends FleetEvent {
  final String droneId;
  final double batteryLevel;

  const FleetDroneStatusUpdated({
    required this.droneId,
    required this.batteryLevel,
  });

  @override
  List<Object?> get props => [droneId, batteryLevel];
}
import 'package:latlong2/latlong.dart';

abstract class FleetEvent {}

class FleetLoadRequested extends FleetEvent {}

class FleetInitializeRequested extends FleetEvent {}

class FleetCalculateRendezvousRequested extends FleetEvent {
  final LatLng boatPosition;
  final LatLng droneBasePosition;
  final LatLng destinationPosition;
  final String droneId;

  FleetCalculateRendezvousRequested({
    required this.boatPosition,
    required this.droneBasePosition,
    required this.destinationPosition,
    required this.droneId,
  });
}

class FleetExecuteHandoffRequested extends FleetEvent {
  final String deliveryId;
  final String droneId;
  final String boatId;

  FleetExecuteHandoffRequested({
    required this.deliveryId,
    required this.droneId,
    required this.boatId,
  });
}
import 'package:latlong2/latlong.dart';

class RendezvousPoint {
  final LatLng position;
  final double distanceFromBoatKm;
  final double distanceFromDroneBaseKm;
  final double distanceToDestinationKm;
  final double totalTravelTimeMinutes;
  final DateTime estimatedBoatArrival;
  final DateTime estimatedDroneArrival;
  final bool isOptimal;

  RendezvousPoint({
    required this.position,
    required this.distanceFromBoatKm,
    required this.distanceFromDroneBaseKm,
    required this.distanceToDestinationKm,
    required this.totalTravelTimeMinutes,
    required this.estimatedBoatArrival,
    required this.estimatedDroneArrival,
    this.isOptimal = false,
  });

  /// Get maximum wait time between arrivals
  Duration getMaxWaitTime() {
    return estimatedBoatArrival.difference(estimatedDroneArrival).abs();
  }

  /// Check if synchronization is good (< 5 min difference)
  bool isSynchronized() {
    return getMaxWaitTime().inMinutes < 5;
  }

  Map<String, dynamic> toMap() {
    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
      'distance_from_boat_km': distanceFromBoatKm,
      'distance_from_drone_base_km': distanceFromDroneBaseKm,
      'distance_to_destination_km': distanceToDestinationKm,
      'total_travel_time_minutes': totalTravelTimeMinutes,
      'estimated_boat_arrival': estimatedBoatArrival.toIso8601String(),
      'estimated_drone_arrival': estimatedDroneArrival.toIso8601String(),
      'is_optimal': isOptimal,
    };
  }

  @override
  String toString() {
    return 'RendezvousPoint(pos: ${position.latitude.toStringAsFixed(4)},${position.longitude.toStringAsFixed(4)}, totalTime: ${totalTravelTimeMinutes.toStringAsFixed(1)}min, synchronized: ${isSynchronized()})';
  }
}
import 'package:latlong2/latlong.dart';

class RendezvousPoint {
  final LatLng position;
  final double distanceFromBoatKm;
  final double distanceFromDroneBaseKm;
  final double distanceToDestinationKm; // ✅ ADDED
  final double boatTravelTimeMinutes;
  final double droneTravelTimeMinutes;
  final double totalTravelTimeMinutes;
  final DateTime estimatedBoatArrival; // ✅ ADDED
  final DateTime estimatedDroneArrival; // ✅ ADDED
  final bool isOptimal; // ✅ ADDED

  RendezvousPoint({
    required this.position,
    required this.distanceFromBoatKm,
    required this.distanceFromDroneBaseKm,
    required this.distanceToDestinationKm, // ✅ ADDED
    required this.boatTravelTimeMinutes,
    required this.droneTravelTimeMinutes,
    required this.totalTravelTimeMinutes,
    required this.estimatedBoatArrival, // ✅ ADDED
    required this.estimatedDroneArrival, // ✅ ADDED
    this.isOptimal = false, // ✅ ADDED
  });

  /// Calculate optimal rendezvous point
  static RendezvousPoint calculate({
    required LatLng boatPosition,
    required LatLng droneBasePosition,
    required LatLng destinationPosition,
    required double boatSpeedKmh,
    required double droneSpeedKmh,
  }) {
    final Distance distance = const Distance();

    // Simple midpoint calculation (can be improved with optimization algorithms)
    final midLat = (boatPosition.latitude + destinationPosition.latitude) / 2;
    final midLon = (boatPosition.longitude + destinationPosition.longitude) / 2;
    final rendezvousPos = LatLng(midLat, midLon);

    // Calculate distances
    final distFromBoat = distance.as(
      LengthUnit.Kilometer,
      boatPosition,
      rendezvousPos,
    );

    final distFromDroneBase = distance.as(
      LengthUnit.Kilometer,
      droneBasePosition,
      rendezvousPos,
    );

    final distToDestination = distance.as(
      LengthUnit.Kilometer,
      rendezvousPos,
      destinationPosition,
    );

    // Calculate travel times
    final boatTime = (distFromBoat / boatSpeedKmh) * 60; // minutes
    final droneTime = (distFromDroneBase / droneSpeedKmh) * 60; // minutes

    final now = DateTime.now();

    return RendezvousPoint(
      position: rendezvousPos,
      distanceFromBoatKm: distFromBoat,
      distanceFromDroneBaseKm: distFromDroneBase,
      distanceToDestinationKm: distToDestination,
      boatTravelTimeMinutes: boatTime,
      droneTravelTimeMinutes: droneTime,
      totalTravelTimeMinutes: boatTime > droneTime ? boatTime : droneTime,
      estimatedBoatArrival: now.add(Duration(minutes: boatTime.round())),
      estimatedDroneArrival: now.add(Duration(minutes: droneTime.round())),
      isOptimal: true,
    );
  }

  /// Check if boat and drone arrive within 5 minutes of each other
  bool isSynchronized() {
    final timeDiff = (boatTravelTimeMinutes - droneTravelTimeMinutes).abs();
    return timeDiff <= 5.0;
  }

  /// Get maximum wait time
  Duration getMaxWaitTime() {
    final waitMinutes = (boatTravelTimeMinutes - droneTravelTimeMinutes).abs();
    return Duration(minutes: waitMinutes.round());
  }

  Map<String, dynamic> toMap() {
    return {
      'position_lat': position.latitude,
      'position_lon': position.longitude,
      'distance_from_boat_km': distanceFromBoatKm,
      'distance_from_drone_base_km': distanceFromDroneBaseKm,
      'distance_to_destination_km': distanceToDestinationKm,
      'boat_travel_time_minutes': boatTravelTimeMinutes,
      'drone_travel_time_minutes': droneTravelTimeMinutes,
      'total_travel_time_minutes': totalTravelTimeMinutes,
      'estimated_boat_arrival': estimatedBoatArrival.toIso8601String(),
      'estimated_drone_arrival': estimatedDroneArrival.toIso8601String(),
      'is_optimal': isOptimal,
    };
  }
}
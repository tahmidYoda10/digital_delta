import 'dart:math';
import 'package:latlong2/latlong.dart';
import '../../../../core/fleet/models/drone_model.dart';
import '../../../../core/fleet/models/rendezvous_point.dart';
import '../../../../core/utils/app_logger.dart';

class CalculateRendezvousUseCase {
  /// Calculate optimal rendezvous point (M8.2)
  RendezvousPoint? calculate({
    required LatLng boatPosition,
    required double boatSpeedKmh,
    required LatLng droneBasePosition,
    required DroneModel drone,
    required LatLng destinationPosition,
  }) {
    try {
      AppLogger.info('📍 Calculating rendezvous point...');

      // Generate candidate points along the path from boat to destination
      final candidates = _generateCandidatePoints(
        boatPosition,
        destinationPosition,
        numPoints: 20,
      );

      RendezvousPoint? bestPoint;
      double minTotalTime = double.infinity;

      for (var candidatePos in candidates) {
        // Calculate distances
        final distanceFromBoat = _haversineDistance(boatPosition, candidatePos);
        final distanceFromDroneBase = _haversineDistance(droneBasePosition, candidatePos);
        final distanceToDestination = _haversineDistance(candidatePos, destinationPosition);

        // Check if drone can reach (with payload + return)
        final droneRoundTrip = distanceFromDroneBase + distanceToDestination;
        if (droneRoundTrip > drone.maxRangeKm * 0.8) {
          continue; // Skip if out of range
        }

        // Calculate travel times
        final boatTime = (distanceFromBoat / boatSpeedKmh) * 60.0; // minutes
        final droneTime = (distanceFromDroneBase / drone.maxSpeedKmh) * 60.0;
        final droneDeliveryTime = (distanceToDestination / drone.maxSpeedKmh) * 60.0;

        // Total time = max(boat arrival, drone arrival) + drone delivery
        final totalTime = max(boatTime, droneTime) + droneDeliveryTime;

        // Find minimum total time
        if (totalTime < minTotalTime) {
          minTotalTime = totalTime;

          final now = DateTime.now();
          bestPoint = RendezvousPoint(
            position: candidatePos,
            distanceFromBoatKm: distanceFromBoat,
            distanceFromDroneBaseKm: distanceFromDroneBase,
            distanceToDestinationKm: distanceToDestination,
            totalTravelTimeMinutes: totalTime,
            estimatedBoatArrival: now.add(Duration(minutes: boatTime.round())),
            estimatedDroneArrival: now.add(Duration(minutes: droneTime.round())),
            isOptimal: true,
          );
        }
      }

      if (bestPoint != null) {
        AppLogger.info('✅ Optimal rendezvous found: ${bestPoint.totalTravelTimeMinutes.toStringAsFixed(1)} min');
      } else {
        AppLogger.warning('⚠️ No valid rendezvous point found');
      }

      return bestPoint;

    } catch (e, stack) {
      AppLogger.error('Rendezvous calculation failed', e, stack);
      return null;
    }
  }

  /// Generate candidate points along path
  List<LatLng> _generateCandidatePoints(
      LatLng start,
      LatLng end,
      {int numPoints = 20}
      ) {
    final points = <LatLng>[];

    for (int i = 0; i <= numPoints; i++) {
      final t = i / numPoints;
      final lat = start.latitude + (end.latitude - start.latitude) * t;
      final lng = start.longitude + (end.longitude - start.longitude) * t;
      points.add(LatLng(lat, lng));
    }

    return points;
  }

  /// Haversine distance formula
  double _haversineDistance(LatLng from, LatLng to) {
    const R = 6371.0; // Earth radius in km
    final dLat = _toRadians(to.latitude - from.latitude);
    final dLon = _toRadians(to.longitude - from.longitude);

    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(from.latitude)) * cos(_toRadians(to.latitude)) *
            sin(dLon / 2) * sin(dLon / 2);

    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return R * c;
  }

  double _toRadians(double degrees) => degrees * pi / 180.0;
}
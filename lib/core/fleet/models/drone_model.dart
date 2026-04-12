import 'package:latlong2/latlong.dart';

enum DroneStatus {
  IDLE,
  IN_TRANSIT,
  HOVERING,
  LANDING,
  CHARGING,
  MAINTENANCE,
}

class DroneModel {
  final String id;
  final String baseStationId;
  LatLng currentPosition;
  DroneStatus status;
  final double maxPayloadKg;
  final double maxRangeKm;
  final double maxSpeedKmh;
  double batteryPercent;
  double currentPayloadKg;

  DroneModel({
    required this.id,
    required this.baseStationId,
    required this.currentPosition,
    this.status = DroneStatus.IDLE,
    this.maxPayloadKg = 50.0,
    this.maxRangeKm = 25.0,
    this.maxSpeedKmh = 60.0,
    this.batteryPercent = 100.0,
    this.currentPayloadKg = 0.0,
  });

  /// Check if drone can perform mission
  bool canPerformMission({
    required double distanceKm,
    required double payloadKg,
  }) {
    // Check payload capacity
    if (payloadKg > maxPayloadKg) return false;

    // Check range (with 20% safety margin)
    final requiredRange = distanceKm * 1.2;
    if (requiredRange > maxRangeKm) return false;

    // Check battery (need at least 30% for safety)
    final requiredBattery = (requiredRange / maxRangeKm) * 100;
    if (batteryPercent < requiredBattery + 30) return false;

    // Check status
    if (status != DroneStatus.IDLE && status != DroneStatus.HOVERING) {
      return false;
    }

    return true;
  }

  /// Estimate flight time in minutes
  double estimateFlightTime(double distanceKm) {
    return (distanceKm / maxSpeedKmh) * 60.0;
  }

  /// Estimate battery consumption for distance
  double estimateBatteryUsage(double distanceKm) {
    // Simple linear model: 1% per km of max range
    final percentPerKm = 100.0 / maxRangeKm;
    return distanceKm * percentPerKm * 1.2; // 20% overhead
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'base_station_id': baseStationId,
      'latitude': currentPosition.latitude,
      'longitude': currentPosition.longitude,
      'status': status.toString(),
      'max_payload_kg': maxPayloadKg,
      'max_range_km': maxRangeKm,
      'battery_percent': batteryPercent,
      'current_payload_kg': currentPayloadKg,
    };
  }

  factory DroneModel.fromMap(Map<String, dynamic> map) {
    return DroneModel(
      id: map['id'],
      baseStationId: map['base_station_id'],
      currentPosition: LatLng(map['latitude'], map['longitude']),
      status: DroneStatus.values.firstWhere(
            (e) => e.toString() == map['status'],
        orElse: () => DroneStatus.IDLE,
      ),
      maxPayloadKg: map['max_payload_kg'].toDouble(),
      maxRangeKm: map['max_range_km'].toDouble(),
      batteryPercent: map['battery_percent'].toDouble(),
      currentPayloadKg: map['current_payload_kg'].toDouble(),
    );
  }

  DroneModel copyWith({
    LatLng? currentPosition,
    DroneStatus? status,
    double? batteryPercent,
    double? currentPayloadKg,
  }) {
    return DroneModel(
      id: id,
      baseStationId: baseStationId,
      currentPosition: currentPosition ?? this.currentPosition,
      status: status ?? this.status,
      maxPayloadKg: maxPayloadKg,
      maxRangeKm: maxRangeKm,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      currentPayloadKg: currentPayloadKg ?? this.currentPayloadKg,
    );
  }

  @override
  String toString() {
    return 'DroneModel(id: $id, status: $status, battery: ${batteryPercent.toStringAsFixed(0)}%, payload: ${currentPayloadKg}kg)';
  }
}
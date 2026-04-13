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
  final double maxRangeKm;
  final double maxPayloadKg;
  final double maxSpeedKmh; // ✅ ADDED
  final double currentLat;
  final double currentLon;
  final double batteryPercent;
  final DroneStatus status;

  DroneModel({
    required this.id,
    required this.baseStationId,
    required this.maxRangeKm,
    required this.maxPayloadKg,
    required this.maxSpeedKmh, // ✅ ADDED
    required this.currentLat,
    required this.currentLon,
    required this.batteryPercent,
    required this.status,
  });

  // Add currentPosition getter for compatibility
  Map<String, double> get currentPosition => {
    'lat': currentLat,
    'lon': currentLon,
  };

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'base_station_id': baseStationId,
      'max_range_km': maxRangeKm,
      'max_payload_kg': maxPayloadKg,
      'max_speed_kmh': maxSpeedKmh, // ✅ ADDED
      'current_lat': currentLat,
      'current_lon': currentLon,
      'battery_percent': batteryPercent,
      'status': status.toString(),
    };
  }

  factory DroneModel.fromMap(Map<String, dynamic> map) {
    return DroneModel(
      id: map['id'],
      baseStationId: map['base_station_id'],
      maxRangeKm: map['max_range_km'],
      maxPayloadKg: map['max_payload_kg'],
      maxSpeedKmh: map['max_speed_kmh'] ?? 60.0, // ✅ ADDED with default
      currentLat: map['current_lat'],
      currentLon: map['current_lon'],
      batteryPercent: map['battery_percent'],
      status: DroneStatus.values.firstWhere(
            (e) => e.toString() == map['status'],
        orElse: () => DroneStatus.IDLE,
      ),
    );
  }
}
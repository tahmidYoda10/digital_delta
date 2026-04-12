import 'models/graph_edge.dart';

enum VehicleType {
  TRUCK,
  SPEEDBOAT,
  DRONE,
  MULTI_MODAL, // ✅ NEW: Can use all edge types
}

class VehicleConstraints {
  final VehicleType vehicleType;
  final double maxPayloadKg;
  final double maxRangeKm;
  final List<EdgeType> allowedEdgeTypes;
  final bool canIgnoreFlooding; // ✅ NEW: For boats

  const VehicleConstraints({
    required this.vehicleType,
    required this.maxPayloadKg,
    required this.maxRangeKm,
    required this.allowedEdgeTypes,
    this.canIgnoreFlooding = false,
  });

  /// Check if vehicle can use this edge (M4.3)
  bool canUseEdge(GraphEdge edge) {
    // ✅ FIX: Allow if edge type is allowed
    if (!allowedEdgeTypes.contains(edge.edgeType)) {
      return false;
    }

    // ✅ FIX: Boats can use flooded waterways
    if (edge.isFlooded && !canIgnoreFlooding) {
      return false;
    }

    return true;
  }

  /// Check if payload is within capacity
  bool canCarryPayload(double payloadKg) {
    return payloadKg <= maxPayloadKg;
  }

  /// Predefined vehicle types

  // ✅ UPDATED: Truck can use ROAD and WATERWAY (for ferry crossings)
  static const VehicleConstraints truck = VehicleConstraints(
    vehicleType: VehicleType.TRUCK,
    maxPayloadKg: 5000.0,
    maxRangeKm: 300.0,
    allowedEdgeTypes: [EdgeType.ROAD, EdgeType.WATERWAY], // ✅ FIXED
    canIgnoreFlooding: false,
  );

  // ✅ UPDATED: Speedboat can ignore flooding on waterways
  static const VehicleConstraints speedboat = VehicleConstraints(
    vehicleType: VehicleType.SPEEDBOAT,
    maxPayloadKg: 1000.0,
    maxRangeKm: 150.0,
    allowedEdgeTypes: [EdgeType.WATERWAY, EdgeType.ROAD], // ✅ Can use roads at low water
    canIgnoreFlooding: true, // ✅ Boats love water!
  );

  // ✅ UPDATED: Drone can use airways and roads (for landing)
  static const VehicleConstraints drone = VehicleConstraints(
    vehicleType: VehicleType.DRONE,
    maxPayloadKg: 50.0,
    maxRangeKm: 25.0,
    allowedEdgeTypes: [EdgeType.AIRWAY, EdgeType.ROAD], // ✅ FIXED
    canIgnoreFlooding: true, // ✅ Flies over floods
  );

  // ✅ NEW: Multi-modal (can use everything)
  static const VehicleConstraints multiModal = VehicleConstraints(
    vehicleType: VehicleType.MULTI_MODAL,
    maxPayloadKg: 2000.0,
    maxRangeKm: 200.0,
    allowedEdgeTypes: [EdgeType.ROAD, EdgeType.WATERWAY, EdgeType.AIRWAY],
    canIgnoreFlooding: false,
  );

  @override
  String toString() => 'VehicleConstraints($vehicleType, payload: $maxPayloadKg kg, range: $maxRangeKm km)';
}
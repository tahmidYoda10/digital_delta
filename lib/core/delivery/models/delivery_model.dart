import 'package:uuid/uuid.dart';
import '../../database/crdt/vector_clock.dart';
import 'cargo_item.dart';

enum DeliveryStatus {
  PENDING,
  IN_TRANSIT,
  AWAITING_POD,
  COMPLETED,
  FAILED,
  PREEMPTED, // Dropped for rerouting (M6)
}

class DeliveryModel {
  final String id;
  final String supplyId;
  final String driverId;
  final String? recipientId;
  final String? routeId;
  final List<CargoItem> cargo;
  final DeliveryStatus status;
  final String? qrSignature;
  final VectorClock vectorClock;
  final DateTime createdAt;
  final DateTime? completedAt;
  final DateTime? estimatedArrival;
  final String deviceId;

  DeliveryModel({
    required this.id,
    required this.supplyId,
    required this.driverId,
    this.recipientId,
    this.routeId,
    required this.cargo,
    required this.status,
    this.qrSignature,
    required this.vectorClock,
    required this.createdAt,
    this.completedAt,
    this.estimatedArrival,
    required this.deviceId,
  });

  factory DeliveryModel.create({
    required String supplyId,
    required String driverId,
    required List<CargoItem> cargo,
    required String deviceId,
    DateTime? estimatedArrival,
  }) {
    final vectorClock = VectorClock();
    vectorClock.increment(deviceId);

    return DeliveryModel(
      id: const Uuid().v4(),
      supplyId: supplyId,
      driverId: driverId,
      cargo: cargo,
      status: DeliveryStatus.PENDING,
      vectorClock: vectorClock,
      createdAt: DateTime.now(),
      estimatedArrival: estimatedArrival,
      deviceId: deviceId,
    );
  }

  /// Get highest priority cargo
  CargoPriority getHighestPriority() {
    if (cargo.isEmpty) return CargoPriority.P3_LOW;

    return cargo
        .map((c) => c.priority)
        .reduce((a, b) => a.index < b.index ? a : b);
  }

  /// Check if any cargo has SLA breach
  bool hasSLABreach() {
    return cargo.any((c) => c.isSLABreached());
  }

  /// Get total cargo weight
  double getTotalWeight() {
    return cargo.fold(0.0, (sum, item) => sum + item.weightKg);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'supply_id': supplyId,
      'driver_id': driverId,
      'recipient_id': recipientId,
      'route_id': routeId,
      'status': status.toString(),
      'qr_signature': qrSignature,
      'vector_clock': vectorClock.toJson(),
      'created_at': createdAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'device_id': deviceId,
    };
  }

  factory DeliveryModel.fromMap(Map<String, dynamic> map) {
    return DeliveryModel(
      id: map['id'],
      supplyId: map['supply_id'],
      driverId: map['driver_id'],
      recipientId: map['recipient_id'],
      routeId: map['route_id'],
      cargo: [], // Load separately
      status: DeliveryStatus.values.firstWhere(
            (e) => e.toString() == map['status'],
        orElse: () => DeliveryStatus.PENDING,
      ),
      qrSignature: map['qr_signature'],
      vectorClock: VectorClock.fromJson(map['vector_clock']),
      createdAt: DateTime.parse(map['created_at']),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'])
          : null,
      deviceId: map['device_id'],
    );
  }

  DeliveryModel copyWith({
    DeliveryStatus? status,
    String? qrSignature,
    DateTime? completedAt,
    String? recipientId,
  }) {
    return DeliveryModel(
      id: id,
      supplyId: supplyId,
      driverId: driverId,
      recipientId: recipientId ?? this.recipientId,
      routeId: routeId,
      cargo: cargo,
      status: status ?? this.status,
      qrSignature: qrSignature ?? this.qrSignature,
      vectorClock: vectorClock,
      createdAt: createdAt,
      completedAt: completedAt ?? this.completedAt,
      estimatedArrival: estimatedArrival,
      deviceId: deviceId,
    );
  }

  @override
  String toString() {
    return 'DeliveryModel(id: $id, status: $status, priority: ${getHighestPriority()}, cargo: ${cargo.length} items)';
  }
}
import '../../../../core/delivery/models/pod_receipt.dart';

enum HandoffStatus {
  INITIATED,
  BOAT_ARRIVED,
  DRONE_ARRIVED,
  TRANSFER_IN_PROGRESS,
  COMPLETED,
  FAILED,
}

class HandoffEvent {
  final String id;
  final String deliveryId;
  final String boatId;
  final String droneId;
  final HandoffStatus status;
  final DateTime initiatedAt;
  final DateTime? completedAt;
  final PoDReceipt? boatReceipt;
  final PoDReceipt? droneReceipt;

  HandoffEvent({
    required this.id,
    required this.deliveryId,
    required this.boatId,
    required this.droneId,
    required this.status,
    required this.initiatedAt,
    this.completedAt,
    this.boatReceipt,
    this.droneReceipt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'delivery_id': deliveryId,
      'boat_id': boatId,
      'drone_id': droneId,
      'status': status.toString(),
      'initiated_at': initiatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
    };
  }

  HandoffEvent copyWith({
    HandoffStatus? status,
    DateTime? completedAt,
    PoDReceipt? boatReceipt,
    PoDReceipt? droneReceipt,
  }) {
    return HandoffEvent(
      id: id,
      deliveryId: deliveryId,
      boatId: boatId,
      droneId: droneId,
      status: status ?? this.status,
      initiatedAt: initiatedAt,
      completedAt: completedAt ?? this.completedAt,
      boatReceipt: boatReceipt ?? this.boatReceipt,
      droneReceipt: droneReceipt ?? this.droneReceipt,
    );
  }

  @override
  String toString() {
    return 'HandoffEvent(id: $id, status: $status, boat: $boatId, drone: $droneId)';
  }
}
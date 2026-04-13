import 'package:uuid/uuid.dart';
import '../../database/crdt/vector_clock.dart';

enum RequestPriority {
  URGENT,    // Life-threatening (medical)
  HIGH,      // Essential (food, water)
  MEDIUM,    // Important (blankets, clothes)
  LOW,       // Non-essential
}

enum RequestStatus {
  PENDING,
  APPROVED,
  IN_PROGRESS,
  FULFILLED,
  REJECTED,
}

class SupplyRequest {
  final String id;
  final String requesterId;
  final String campId;
  final String itemName;
  final int quantity;
  final RequestPriority priority;
  final RequestStatus status;
  final String? medicalReason;
  final DateTime createdAt;
  final DateTime? approvedAt;
  final String? approvedBy;
  final String? rejectedReason;
  final VectorClock vectorClock;
  final String deviceId;

  SupplyRequest({
    required this.id,
    required this.requesterId,
    required this.campId,
    required this.itemName,
    required this.quantity,
    required this.priority,
    required this.status,
    this.medicalReason,
    required this.createdAt,
    this.approvedAt,
    this.approvedBy,
    this.rejectedReason,
    required this.vectorClock,
    required this.deviceId,
  });

  factory SupplyRequest.create({
    required String requesterId,
    required String campId,
    required String itemName,
    required int quantity,
    required RequestPriority priority,
    required String deviceId,
    String? medicalReason,
  }) {
    final vectorClock = VectorClock();
    vectorClock.increment(deviceId);

    return SupplyRequest(
      id: const Uuid().v4(),
      requesterId: requesterId,
      campId: campId,
      itemName: itemName,
      quantity: quantity,
      priority: priority,
      status: RequestStatus.PENDING,
      medicalReason: medicalReason,
      createdAt: DateTime.now(),
      vectorClock: vectorClock,
      deviceId: deviceId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'requester_id': requesterId,
      'camp_id': campId,
      'item_name': itemName,
      'quantity': quantity,
      'priority': priority.toString(),
      'status': status.toString(),
      'medical_reason': medicalReason,
      'created_at': createdAt.toIso8601String(),
      'approved_at': approvedAt?.toIso8601String(),
      'approved_by': approvedBy,
      'rejected_reason': rejectedReason,
      'vector_clock': vectorClock.toJson(),
      'device_id': deviceId,
    };
  }

  factory SupplyRequest.fromMap(Map<String, dynamic> map) {
    return SupplyRequest(
      id: map['id'],
      requesterId: map['requester_id'],
      campId: map['camp_id'],
      itemName: map['item_name'],
      quantity: map['quantity'],
      priority: RequestPriority.values.firstWhere(
            (e) => e.toString() == map['priority'],
        orElse: () => RequestPriority.MEDIUM,
      ),
      status: RequestStatus.values.firstWhere(
            (e) => e.toString() == map['status'],
        orElse: () => RequestStatus.PENDING,
      ),
      medicalReason: map['medical_reason'],
      createdAt: DateTime.parse(map['created_at']),
      approvedAt: map['approved_at'] != null ? DateTime.parse(map['approved_at']) : null,
      approvedBy: map['approved_by'],
      rejectedReason: map['rejected_reason'],
      vectorClock: VectorClock.fromJson(map['vector_clock']),
      deviceId: map['device_id'],
    );
  }

  SupplyRequest copyWith({
    RequestStatus? status,
    DateTime? approvedAt,
    String? approvedBy,
    String? rejectedReason,
  }) {
    return SupplyRequest(
      id: id,
      requesterId: requesterId,
      campId: campId,
      itemName: itemName,
      quantity: quantity,
      priority: priority,
      status: status ?? this.status,
      medicalReason: medicalReason,
      createdAt: createdAt,
      approvedAt: approvedAt ?? this.approvedAt,
      approvedBy: approvedBy ?? this.approvedBy,
      rejectedReason: rejectedReason ?? this.rejectedReason,
      vectorClock: vectorClock,
      deviceId: deviceId,
    );
  }

  @override
  String toString() {
    return 'SupplyRequest($itemName x$quantity, priority: $priority, status: $status)';
  }
}
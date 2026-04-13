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
  final double rendezvousLat;
  final double rendezvousLon;
  final DateTime initiatedAt;
  final DateTime? completedAt;
  final HandoffStatus status;

  HandoffEvent({
    required this.id,
    required this.deliveryId,
    required this.boatId,
    required this.droneId,
    required this.rendezvousLat,
    required this.rendezvousLon,
    required this.initiatedAt,
    this.completedAt,
    required this.status,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'delivery_id': deliveryId,
      'boat_id': boatId,
      'drone_id': droneId,
      'rendezvous_lat': rendezvousLat,
      'rendezvous_lon': rendezvousLon,
      'initiated_at': initiatedAt.toIso8601String(),
      'completed_at': completedAt?.toIso8601String(),
      'status': status.toString(),
    };
  }

  factory HandoffEvent.fromMap(Map<String, dynamic> map) {
    return HandoffEvent(
      id: map['id'],
      deliveryId: map['delivery_id'],
      boatId: map['boat_id'],
      droneId: map['drone_id'],
      rendezvousLat: map['rendezvous_lat'],
      rendezvousLon: map['rendezvous_lon'],
      initiatedAt: DateTime.parse(map['initiated_at']),
      completedAt: map['completed_at'] != null
          ? DateTime.parse(map['completed_at'])
          : null,
      status: HandoffStatus.values.firstWhere(
            (e) => e.toString() == map['status'],
        orElse: () => HandoffStatus.INITIATED,
      ),
    );
  }
}
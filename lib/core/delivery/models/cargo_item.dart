enum CargoPriority {
  P0_CRITICAL,  // 2 hours SLA
  P1_HIGH,      // 6 hours SLA
  P2_STANDARD,  // 24 hours SLA
  P3_LOW,       // 72 hours SLA
}

class CargoItem {
  final String id;
  final String name;
  final double weightKg;
  final CargoPriority priority;
  final DateTime createdAt;
  final DateTime slaDeadline;
  final String? medicalCategory; // e.g., "antivenom", "insulin"

  CargoItem({
    required this.id,
    required this.name,
    required this.weightKg,
    required this.priority,
    required this.createdAt,
    required this.slaDeadline,
    this.medicalCategory,
  });

  /// Get SLA window in minutes
  int getSLAMinutes() {
    switch (priority) {
      case CargoPriority.P0_CRITICAL:
        return 2 * 60;
      case CargoPriority.P1_HIGH:
        return 6 * 60;
      case CargoPriority.P2_STANDARD:
        return 24 * 60;
      case CargoPriority.P3_LOW:
        return 72 * 60;
    }
  }

  /// Check if SLA is breached
  bool isSLABreached() {
    return DateTime.now().isAfter(slaDeadline);
  }

  /// Get remaining time until SLA breach
  Duration getRemainingTime() {
    return slaDeadline.difference(DateTime.now());
  }

  /// Check if SLA is at risk (< 30% time remaining)
  bool isSLAAtRisk() {
    final remaining = getRemainingTime();
    final total = Duration(minutes: getSLAMinutes());
    return remaining.inMinutes < (total.inMinutes * 0.3);
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'weight_kg': weightKg,
      'priority': priority.toString(),
      'created_at': createdAt.toIso8601String(),
      'sla_deadline': slaDeadline.toIso8601String(),
      'medical_category': medicalCategory,
    };
  }

  factory CargoItem.fromMap(Map<String, dynamic> map) {
    return CargoItem(
      id: map['id'],
      name: map['name'],
      weightKg: map['weight_kg'].toDouble(),
      priority: CargoPriority.values.firstWhere(
            (e) => e.toString() == map['priority'],
        orElse: () => CargoPriority.P2_STANDARD,
      ),
      createdAt: DateTime.parse(map['created_at']),
      slaDeadline: DateTime.parse(map['sla_deadline']),
      medicalCategory: map['medical_category'],
    );
  }

  @override
  String toString() {
    return 'CargoItem(id: $id, name: $name, priority: $priority, SLA: ${getRemainingTime().inMinutes} min)';
  }
}
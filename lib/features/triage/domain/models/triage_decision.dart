enum TriageAction {
  CONTINUE,         // No action needed
  REROUTE,          // Change route due to conditions
  PREEMPT,          // Drop low-priority cargo
  HANDOFF_DRONE,    // Transfer to drone for last mile
  ABORT,            // Cancel delivery
}

class TriageDecision {
  final String deliveryId;
  final TriageAction action;
  final String reason;
  final DateTime decidedAt;
  final Map<String, dynamic> metadata;

  TriageDecision({
    required this.deliveryId,
    required this.action,
    required this.reason,
    required this.decidedAt,
    this.metadata = const {},
  });

  Map<String, dynamic> toMap() {
    return {
      'id': '$deliveryId-${decidedAt.millisecondsSinceEpoch}',
      'delivery_id': deliveryId,
      'decision_type': action.toString(),
      'reason': reason,
      'timestamp': decidedAt.toIso8601String(),
    };
  }

  @override
  String toString() {
    return 'TriageDecision(delivery: $deliveryId, action: $action, reason: $reason)';
  }
}
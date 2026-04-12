enum EdgeType {
  ROAD,      // Trucks only
  WATERWAY,  // Speedboats only
  AIRWAY,    // Drones only
}

class GraphEdge {
  final String id;
  final String sourceId;
  final String targetId;
  final EdgeType edgeType;
  final double baseWeight; // Base travel time in minutes
  double currentWeight;    // Current weight (affected by conditions)
  final bool isFlooded;
  final double riskScore;  // 0.0 to 1.0 from ML model
  final Map<String, dynamic>? metadata;

  GraphEdge({
    required this.id,
    required this.sourceId,
    required this.targetId,
    required this.edgeType,
    required this.baseWeight,
    double? currentWeight,
    this.isFlooded = false,
    this.riskScore = 0.0,
    this.metadata,
  }) : currentWeight = currentWeight ?? baseWeight;

  /// Calculate effective weight based on conditions (M4.2)
  double getEffectiveWeight({
    bool includeRisk = true,
    double riskMultiplier = 2.0,
  }) {
    if (isFlooded) {
      return 9999.0; // Impassable
    }

    double weight = currentWeight;

    // Apply risk penalty
    if (includeRisk && riskScore > 0.0) {
      weight *= (1.0 + (riskScore * riskMultiplier));
    }

    return weight;
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'source_id': sourceId,
      'target_id': targetId,
      'edge_type': edgeType.toString(),
      'base_weight': baseWeight,
      'current_weight': currentWeight,
      'is_flooded': isFlooded ? 1 : 0,
      'risk_score': riskScore,
    };
  }

  factory GraphEdge.fromMap(Map<String, dynamic> map) {
    return GraphEdge(
      id: map['id'],
      sourceId: map['source_id'],
      targetId: map['target_id'],
      edgeType: EdgeType.values.firstWhere(
            (e) => e.toString() == map['edge_type'],
        orElse: () => EdgeType.ROAD,
      ),
      baseWeight: map['base_weight'].toDouble(),
      currentWeight: map['current_weight'].toDouble(),
      isFlooded: map['is_flooded'] == 1,
      riskScore: map['risk_score']?.toDouble() ?? 0.0,
    );
  }

  GraphEdge copyWith({
    String? id,
    String? sourceId,
    String? targetId,
    EdgeType? edgeType,
    double? baseWeight,
    double? currentWeight,
    bool? isFlooded,
    double? riskScore,
    Map<String, dynamic>? metadata,
  }) {
    return GraphEdge(
      id: id ?? this.id,
      sourceId: sourceId ?? this.sourceId,
      targetId: targetId ?? this.targetId,
      edgeType: edgeType ?? this.edgeType,
      baseWeight: baseWeight ?? this.baseWeight,
      currentWeight: currentWeight ?? this.currentWeight,
      isFlooded: isFlooded ?? this.isFlooded,
      riskScore: riskScore ?? this.riskScore,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() {
    return 'GraphEdge(id: $id, $sourceId→$targetId, type: $edgeType, weight: $currentWeight, flooded: $isFlooded)';
  }
}
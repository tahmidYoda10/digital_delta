import 'package:latlong2/latlong.dart';

enum NodeType {
  CENTRAL_COMMAND,
  SUPPLY_DROP,
  RELIEF_CAMP,
  HOSPITAL,
  WAYPOINT,
  DRONE_BASE,
}

class GraphNode {
  final String id;
  final String name;
  final NodeType type;
  final LatLng position;
  final bool isActive;
  final Map<String, dynamic>? metadata;

  GraphNode({
    required this.id,
    required this.name,
    required this.type,
    required this.position,
    this.isActive = true,
    this.metadata,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type.toString(),
      'latitude': position.latitude,
      'longitude': position.longitude,
      'is_active': isActive ? 1 : 0,
    };
  }

  factory GraphNode.fromMap(Map<String, dynamic> map) {
    return GraphNode(
      id: map['id'],
      name: map['name'],
      type: NodeType.values.firstWhere(
            (e) => e.toString() == map['type'],
        orElse: () => NodeType.WAYPOINT,
      ),
      position: LatLng(map['latitude'], map['longitude']),
      isActive: map['is_active'] == 1,
    );
  }

  GraphNode copyWith({
    String? id,
    String? name,
    NodeType? type,
    LatLng? position,
    bool? isActive,
    Map<String, dynamic>? metadata,
  }) {
    return GraphNode(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      position: position ?? this.position,
      isActive: isActive ?? this.isActive,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  String toString() => 'GraphNode(id: $id, name: $name, type: $type)';
}
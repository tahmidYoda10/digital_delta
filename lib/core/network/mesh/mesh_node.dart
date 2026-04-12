import 'package:flutter_blue_plus/flutter_blue_plus.dart';

enum NodeRole {
  CLIENT,   // Only sends/receives
  RELAY,    // Forwards messages
  HYBRID,   // Both client and relay
}

enum NodeStatus {
  OFFLINE,
  SCANNING,
  CONNECTED,
  RELAYING,
}

class MeshNode {
  final String deviceId;
  final String deviceName;
  final BluetoothDevice? bluetoothDevice;
  NodeRole role;
  NodeStatus status;
  final DateTime discoveredAt;
  DateTime lastSeenAt;
  int batteryLevel;
  int signalStrength; // RSSI
  bool isStationary;
  int relayedMessageCount;

  MeshNode({
    required this.deviceId,
    required this.deviceName,
    this.bluetoothDevice,
    this.role = NodeRole.HYBRID,
    this.status = NodeStatus.OFFLINE,
    required this.discoveredAt,
    required this.lastSeenAt,
    this.batteryLevel = 100,
    this.signalStrength = -100,
    this.isStationary = false,
    this.relayedMessageCount = 0,
  });

  /// Determine optimal role based on device state (M3.2)
  void updateRole() {
    // Rule: Low battery → CLIENT only
    if (batteryLevel < 30) {
      role = NodeRole.CLIENT;
      return;
    }

    // Rule: Stationary + good battery → RELAY
    if (isStationary && batteryLevel > 50) {
      role = NodeRole.RELAY;
      return;
    }

    // Rule: Good signal + good battery → HYBRID
    if (signalStrength > -70 && batteryLevel > 40) {
      role = NodeRole.HYBRID;
      return;
    }

    // Default: CLIENT
    role = NodeRole.CLIENT;
  }

  /// Check if node is active (seen in last 30 seconds)
  bool isActive() {
    return DateTime.now().difference(lastSeenAt).inSeconds < 30;
  }

  /// Update last seen timestamp
  void updateLastSeen() {
    lastSeenAt = DateTime.now();
  }

  Map<String, dynamic> toJson() {
    return {
      'deviceId': deviceId,
      'deviceName': deviceName,
      'role': role.toString(),
      'status': status.toString(),
      'discoveredAt': discoveredAt.toIso8601String(),
      'lastSeenAt': lastSeenAt.toIso8601String(),
      'batteryLevel': batteryLevel,
      'signalStrength': signalStrength,
      'isStationary': isStationary,
      'relayedMessageCount': relayedMessageCount,
    };
  }

  factory MeshNode.fromJson(Map<String, dynamic> json) {
    return MeshNode(
      deviceId: json['deviceId'],
      deviceName: json['deviceName'],
      role: NodeRole.values.firstWhere(
            (e) => e.toString() == json['role'],
        orElse: () => NodeRole.HYBRID,
      ),
      status: NodeStatus.values.firstWhere(
            (e) => e.toString() == json['status'],
        orElse: () => NodeStatus.OFFLINE,
      ),
      discoveredAt: DateTime.parse(json['discoveredAt']),
      lastSeenAt: DateTime.parse(json['lastSeenAt']),
      batteryLevel: json['batteryLevel'],
      signalStrength: json['signalStrength'],
      isStationary: json['isStationary'],
      relayedMessageCount: json['relayedMessageCount'],
    );
  }

  @override
  String toString() {
    return 'MeshNode(id: $deviceId, name: $deviceName, role: $role, status: $status, battery: $batteryLevel%, rssi: $signalStrength)';
  }
}
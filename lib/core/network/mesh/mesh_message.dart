import 'dart:convert';
import 'package:uuid/uuid.dart';
import '../../utils/app_logger.dart';

enum MessageType {
  SYNC_REQUEST,
  SYNC_RESPONSE,
  SUPPLY_UPDATE,
  ROUTE_UPDATE,
  DELIVERY_POD,
  HEARTBEAT,
}

class MeshMessage {
  final String id;
  final MessageType type;
  final String senderId;
  final String? recipientId; // null = broadcast
  final Map<String, dynamic> payload;
  final DateTime timestamp;
  final int ttl; // Time-to-live (hops remaining)
  final List<String> routePath; // Track relay path
  final String signature; // Sender's signature

  MeshMessage({
    required this.id,
    required this.type,
    required this.senderId,
    this.recipientId,
    required this.payload,
    required this.timestamp,
    required this.ttl,
    required this.routePath,
    required this.signature,
  });

  /// Create new message
  factory MeshMessage.create({
    required MessageType type,
    required String senderId,
    String? recipientId,
    required Map<String, dynamic> payload,
    String signature = '',
  }) {
    return MeshMessage(
      id: const Uuid().v4(),
      type: type,
      senderId: senderId,
      recipientId: recipientId,
      payload: payload,
      timestamp: DateTime.now(),
      ttl: 10, // Default 10 hops
      routePath: [senderId],
      signature: signature,
    );
  }

  /// Create relay copy (decrement TTL, add to path)
  MeshMessage relay(String relayNodeId) {
    return MeshMessage(
      id: id,
      type: type,
      senderId: senderId,
      recipientId: recipientId,
      payload: payload,
      timestamp: timestamp,
      ttl: ttl - 1,
      routePath: [...routePath, relayNodeId],
      signature: signature,
    );
  }

  /// Check if message should be relayed
  bool canRelay() => ttl > 0;

  /// Check if this node is in the route path (prevent loops)
  bool hasVisited(String nodeId) => routePath.contains(nodeId);

  /// Convert to JSON for transmission
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.toString(),
      'senderId': senderId,
      'recipientId': recipientId,
      'payload': payload,
      'timestamp': timestamp.toIso8601String(),
      'ttl': ttl,
      'routePath': routePath,
      'signature': signature,
    };
  }

  /// Parse from JSON
  factory MeshMessage.fromJson(Map<String, dynamic> json) {
    return MeshMessage(
      id: json['id'],
      type: MessageType.values.firstWhere(
            (e) => e.toString() == json['type'],
      ),
      senderId: json['senderId'],
      recipientId: json['recipientId'],
      payload: Map<String, dynamic>.from(json['payload']),
      timestamp: DateTime.parse(json['timestamp']),
      ttl: json['ttl'],
      routePath: List<String>.from(json['routePath']),
      signature: json['signature'],
    );
  }

  /// Serialize to bytes for Bluetooth transmission
  List<int> toBytes() {
    final jsonString = jsonEncode(toJson());
    return utf8.encode(jsonString);
  }

  /// Deserialize from bytes
  factory MeshMessage.fromBytes(List<int> bytes) {
    final jsonString = utf8.decode(bytes);
    final json = jsonDecode(jsonString);
    return MeshMessage.fromJson(json);
  }

  @override
  String toString() {
    return 'MeshMessage(id: ${id.substring(0, 8)}, type: $type, sender: $senderId, ttl: $ttl, hops: ${routePath.length})';
  }
}
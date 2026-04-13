import 'vector_clock.dart';

/// Last-Write-Wins Register (CRDT primitive)
class LWWRegister<T> {
  final String id;
  T? value;
  VectorClock vectorClock;
  DateTime timestamp;
  String deviceId;

  LWWRegister(this.id)
      : value = null,
        vectorClock = VectorClock(),
        timestamp = DateTime.now(),
        deviceId = '';

  /// Set value with vector clock
  void set(T newValue, VectorClock clock, String device) {
    value = newValue;
    vectorClock = clock.copy();
    timestamp = DateTime.now();
    deviceId = device;
  }

  /// Merge with another register (M2.1 - CRDT merge)
  void merge(LWWRegister<T> other) {
    // Check causal relationship
    if (other.vectorClock.happenedBefore(vectorClock)) {
      // Current value is newer, keep it
      return;
    } else if (vectorClock.happenedBefore(other.vectorClock)) {
      // Other value is newer, take it
      value = other.value;
      vectorClock = other.vectorClock.copy();
      timestamp = other.timestamp;
      deviceId = other.deviceId;
    } else {
      // Concurrent writes - use timestamp as tiebreaker
      if (other.timestamp.isAfter(timestamp)) {
        value = other.value;
        vectorClock = other.vectorClock.copy();
        timestamp = other.timestamp;
        deviceId = other.deviceId;
      } else if (timestamp == other.timestamp) {
        // Same timestamp - use deviceId lexicographically
        if (other.deviceId.compareTo(deviceId) > 0) {
          value = other.value;
          vectorClock = other.vectorClock.copy();
          timestamp = other.timestamp;
          deviceId = other.deviceId;
        }
      }
    }
  }

  /// Check if concurrent with another register
  bool isConcurrentWith(LWWRegister<T> other) {
    return vectorClock.isConcurrentWith(other.vectorClock);
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'value': value,
      'vectorClock': vectorClock.toJson(),
      'timestamp': timestamp.toIso8601String(),
      'deviceId': deviceId,
    };
  }

  factory LWWRegister.fromJson(Map<String, dynamic> json, T Function(dynamic) parser) {
    final register = LWWRegister<T>(json['id']);
    register.value = json['value'] != null ? parser(json['value']) : null;
    register.vectorClock = VectorClock.fromJson(json['vectorClock']);
    register.timestamp = DateTime.parse(json['timestamp']);
    register.deviceId = json['deviceId'];
    return register;
  }

  @override
  String toString() {
    return 'LWWRegister(id: $id, value: $value, clock: $vectorClock, device: $deviceId)';
  }
}
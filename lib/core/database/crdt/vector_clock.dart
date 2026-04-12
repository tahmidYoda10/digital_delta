import 'dart:convert';

/// Vector Clock for causal ordering (M2.2)
class VectorClock {
  final Map<String, int> _clock;

  VectorClock() : _clock = {};

  VectorClock.fromMap(Map<String, int> clock) : _clock = Map.from(clock);

  /// Increment clock for a device
  void increment(String deviceId) {
    _clock[deviceId] = (_clock[deviceId] ?? 0) + 1;
  }

  /// Merge two vector clocks (taking max of each component)
  void merge(VectorClock other) {
    for (var entry in other._clock.entries) {
      _clock[entry.key] =
      (_clock[entry.key] ?? 0) > entry.value
          ? _clock[entry.key]!
          : entry.value;
    }
  }

  /// Check if this clock happened before other
  bool happenedBefore(VectorClock other) {
    bool lessThanOrEqual = true;
    bool strictlyLess = false;

    for (var key in {..._clock.keys, ...other._clock.keys}) {
      int thisValue = _clock[key] ?? 0;
      int otherValue = other._clock[key] ?? 0;

      if (thisValue > otherValue) {
        lessThanOrEqual = false;
        break;
      }
      if (thisValue < otherValue) {
        strictlyLess = true;
      }
    }

    return lessThanOrEqual && strictlyLess;
  }

  /// Check if clocks are concurrent (conflict)
  bool isConcurrentWith(VectorClock other) {
    return !happenedBefore(other) && !other.happenedBefore(this);
  }

  /// Get timestamp for a specific device
  int getTimestamp(String deviceId) => _clock[deviceId] ?? 0;

  /// Convert to JSON string
  String toJson() => jsonEncode(_clock);

  /// Create from JSON string
  factory VectorClock.fromJson(String json) {
    Map<String, dynamic> decoded = jsonDecode(json);
    return VectorClock.fromMap(decoded.map((k, v) => MapEntry(k, v as int)));
  }

  Map<String, int> toMap() => Map.from(_clock);

  @override
  String toString() => 'VectorClock($_clock)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is VectorClock &&
              runtimeType == other.runtimeType &&
              _mapsEqual(_clock, other._clock);

  bool _mapsEqual(Map a, Map b) {
    if (a.length != b.length) return false;
    for (var key in a.keys) {
      if (a[key] != b[key]) return false;
    }
    return true;
  }

  @override
  int get hashCode => _clock.hashCode;

  VectorClock copy() => VectorClock.fromMap(_clock);
}
import 'vector_clock.dart';

enum CRDTOperation { INSERT, UPDATE, DELETE }

/// CRDT Entry with LWW (Last-Write-Wins) semantics
class CRDTEntry<T> {
  final String id;
  final T? value;
  final VectorClock vectorClock;
  final CRDTOperation operation;
  final String deviceId;
  final DateTime timestamp;
  final bool tombstone; // For deletions

  CRDTEntry({
    required this.id,
    this.value,
    required this.vectorClock,
    required this.operation,
    required this.deviceId,
    required this.timestamp,
    this.tombstone = false,
  });

  /// Resolve conflict using vector clocks
  static CRDTEntry<T> resolveConflict<T>(
      CRDTEntry<T> entry1,
      CRDTEntry<T> entry2,
      ) {
    // Check causal relationship
    if (entry1.vectorClock.happenedBefore(entry2.vectorClock)) {
      return entry2; // entry2 is newer
    } else if (entry2.vectorClock.happenedBefore(entry1.vectorClock)) {
      return entry1; // entry1 is newer
    } else {
      // Concurrent: use timestamp as tiebreaker (LWW)
      if (entry1.timestamp.isAfter(entry2.timestamp)) {
        return entry1;
      } else if (entry2.timestamp.isAfter(entry1.timestamp)) {
        return entry2;
      } else {
        // Same timestamp: use deviceId lexicographically
        return entry1.deviceId.compareTo(entry2.deviceId) > 0
            ? entry1
            : entry2;
      }
    }
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'value': value.toString(), // Serialize based on type
      'vector_clock': vectorClock.toJson(),
      'operation': operation.toString(),
      'device_id': deviceId,
      'timestamp': timestamp.toIso8601String(),
      'tombstone': tombstone ? 1 : 0,
    };
  }

  factory CRDTEntry.fromMap(Map<String, dynamic> map, T Function(String) valueParser) {
    return CRDTEntry<T>(
      id: map['id'],
      value: map['tombstone'] == 1 ? null : valueParser(map['value']),
      vectorClock: VectorClock.fromJson(map['vector_clock']),
      operation: CRDTOperation.values.firstWhere(
            (e) => e.toString() == map['operation'],
      ),
      deviceId: map['device_id'],
      timestamp: DateTime.parse(map['timestamp']),
      tombstone: map['tombstone'] == 1,
    );
  }

  @override
  String toString() => 'CRDTEntry(id: $id, clock: $vectorClock, op: $operation)';
}
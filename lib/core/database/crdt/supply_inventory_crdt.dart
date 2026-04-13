import 'lww_register.dart';
import 'vector_clock.dart';
import '../../utils/app_logger.dart';

/// CRDT-backed supply inventory (M2.1)
class SupplyInventoryCRDT {
  final Map<String, LWWRegister<int>> _items = {};
  final Map<String, ConflictRecord> _conflicts = {};

  // ✅ ADD UNNAMED CONSTRUCTOR
  SupplyInventoryCRDT();

  /// Update item quantity
  void updateItem(String itemId, int quantity, VectorClock clock, String deviceId) {
    if (!_items.containsKey(itemId)) {
      _items[itemId] = LWWRegister<int>(itemId);
    }

    final register = _items[itemId]!;
    final oldValue = register.value;

    register.set(quantity, clock, deviceId);

    AppLogger.info('📦 Updated $itemId: $oldValue → $quantity (device: $deviceId)');
  }

  /// Get item quantity
  int? getQuantity(String itemId) {
    return _items[itemId]?.value;
  }

  /// Merge with remote CRDT (M2.1 - conflict detection)
  void merge(SupplyInventoryCRDT remote, String localDeviceId) {
    AppLogger.info('🔄 Merging CRDT state from remote...');

    for (var entry in remote._items.entries) {
      final itemId = entry.key;
      final remoteRegister = entry.value;

      if (!_items.containsKey(itemId)) {
        // New item from remote
        _items[itemId] = remoteRegister;
        AppLogger.info('✅ Added new item: $itemId = ${remoteRegister.value}');
      } else {
        final localRegister = _items[itemId]!;

        // Check for conflict (M2.3)
        if (localRegister.isConcurrentWith(remoteRegister)) {
          _conflicts[itemId] = ConflictRecord(
            itemId: itemId,
            localValue: localRegister.value!,
            remoteValue: remoteRegister.value!,
            localClock: localRegister.vectorClock,
            remoteClock: remoteRegister.vectorClock,
            localDevice: localDeviceId,
            remoteDevice: remoteRegister.deviceId,
            localTimestamp: localRegister.timestamp,
            remoteTimestamp: remoteRegister.timestamp,
            detectedAt: DateTime.now(),
          );

          AppLogger.warning('⚠️ CONFLICT DETECTED: $itemId (local: ${localRegister.value}, remote: ${remoteRegister.value})');
        }

        // Merge (LWW wins)
        localRegister.merge(remoteRegister);
        AppLogger.info('✅ Merged $itemId = ${localRegister.value}');
      }
    }
  }

  /// Get all conflicts (M2.3)
  List<ConflictRecord> getConflicts() {
    return _conflicts.values.toList();
  }

  /// Resolve conflict manually
  void resolveConflict(String itemId, int chosenValue, String deviceId) {
    if (_conflicts.containsKey(itemId)) {
      final register = _items[itemId]!;
      final newClock = register.vectorClock.copy();
      newClock.increment(deviceId);

      register.set(chosenValue, newClock, deviceId);
      _conflicts.remove(itemId);

      AppLogger.info('✅ Conflict resolved: $itemId = $chosenValue');
    }
  }

  /// Get all items
  Map<String, int?> getAllItems() {
    return _items.map((key, value) => MapEntry(key, value.value));
  }

  /// Get statistics
  Map<String, dynamic> getStats() {
    return {
      'total_items': _items.length,
      'conflicts': _conflicts.length,
      'items': getAllItems(),
    };
  }

  /// Export to JSON
  Map<String, dynamic> toJson() {
    return {
      'items': _items.map((key, value) => MapEntry(key, value.toJson())),
      'conflicts': _conflicts.map((key, value) => MapEntry(key, value.toJson())),
    };
  }

  /// Import from JSON
  factory SupplyInventoryCRDT.fromJson(Map<String, dynamic> json) {
    final crdt = SupplyInventoryCRDT();

    if (json['items'] != null) {
      (json['items'] as Map<String, dynamic>).forEach((key, value) {
        crdt._items[key] = LWWRegister<int>.fromJson(
          value,
              (val) => val is int ? val : int.parse(val.toString()),
        );
      });
    }

    return crdt;
  }
}

/// Conflict record (M2.3)
class ConflictRecord {
  final String itemId;
  final int localValue;
  final int remoteValue;
  final VectorClock localClock;
  final VectorClock remoteClock;
  final String localDevice;
  final String remoteDevice;
  final DateTime localTimestamp;
  final DateTime remoteTimestamp;
  final DateTime detectedAt;

  ConflictRecord({
    required this.itemId,
    required this.localValue,
    required this.remoteValue,
    required this.localClock,
    required this.remoteClock,
    required this.localDevice,
    required this.remoteDevice,
    required this.localTimestamp,
    required this.remoteTimestamp,
    required this.detectedAt,
  });

  /// Determine winner (for UI display)
  String getWinner() {
    if (localTimestamp.isAfter(remoteTimestamp)) {
      return 'Local';
    } else if (remoteTimestamp.isAfter(localTimestamp)) {
      return 'Remote';
    } else {
      return localDevice.compareTo(remoteDevice) > 0 ? 'Local' : 'Remote';
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'itemId': itemId,
      'localValue': localValue,
      'remoteValue': remoteValue,
      'localClock': localClock.toJson(),
      'remoteClock': remoteClock.toJson(),
      'localDevice': localDevice,
      'remoteDevice': remoteDevice,
      'localTimestamp': localTimestamp.toIso8601String(),
      'remoteTimestamp': remoteTimestamp.toIso8601String(),
      'detectedAt': detectedAt.toIso8601String(),
    };
  }
}
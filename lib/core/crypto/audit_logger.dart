import 'package:crypto/crypto.dart';
import 'dart:convert';
import '../database/database_helper.dart';
import '../utils/app_logger.dart';
import 'package:uuid/uuid.dart';

enum AuthEventType {
  LOGIN_SUCCESS,
  LOGIN_FAILED,
  OTP_GENERATED,
  OTP_VERIFIED,
  OTP_FAILED,
  KEY_ROTATION,
  LOGOUT,
}

class AuditLogger {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final Uuid _uuid = const Uuid();

  /// Log authentication event with hash chain (M1.4)
  Future<void> logAuthEvent({
    required String userId,
    required AuthEventType eventType,
    required String deviceId,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final database = await _db.database;

      // Get previous hash
      final lastLog = await database.query(
        'auth_logs',
        orderBy: 'timestamp DESC',
        limit: 1,
      );

      String? prevHash = lastLog.isNotEmpty ? lastLog.first['current_hash'] as String? : null;

      // Create current log entry
      final logId = _uuid.v4();
      final timestamp = DateTime.now().toIso8601String();

      // Calculate hash: SHA256(prevHash + logId + userId + eventType + timestamp)
      final hashInput = '${prevHash ?? "genesis"}|$logId|$userId|${eventType.toString()}|$timestamp';
      final currentHash = sha256.convert(utf8.encode(hashInput)).toString();

      // Insert log
      await database.insert('auth_logs', {
        'id': logId,
        'user_id': userId,
        'event_type': eventType.toString(),
        'timestamp': timestamp,
        'device_id': deviceId,
        'prev_hash': prevHash,
        'current_hash': currentHash,
      });

      AppLogger.info('📝 Auth event logged: $eventType for user $userId');

    } catch (e, stack) {
      AppLogger.error('Failed to log auth event', e, stack);
    }
  }

  /// Verify audit trail integrity
  Future<bool> verifyIntegrity() async {
    try {
      final database = await _db.database;
      final logs = await database.query(
        'auth_logs',
        orderBy: 'timestamp ASC',
      );

      if (logs.isEmpty) return true;

      String? expectedPrevHash;

      for (var log in logs) {
        // Check if prev_hash matches expected
        if (log['prev_hash'] != expectedPrevHash) {
          AppLogger.error('❌ Audit trail corruption detected at log ${log['id']}');
          return false;
        }

        // Recalculate current hash
        final hashInput = '${expectedPrevHash ?? "genesis"}|${log['id']}|${log['user_id']}|${log['event_type']}|${log['timestamp']}';
        final calculatedHash = sha256.convert(utf8.encode(hashInput)).toString();

        if (calculatedHash != log['current_hash']) {
          AppLogger.error('❌ Hash mismatch at log ${log['id']}');
          return false;
        }

        expectedPrevHash = log['current_hash'] as String?;
      }

      AppLogger.info('✅ Audit trail integrity verified');
      return true;

    } catch (e, stack) {
      AppLogger.error('Failed to verify audit trail', e, stack);
      return false;
    }
  }

  /// Get audit logs for a user
  Future<List<Map<String, dynamic>>> getUserLogs(String userId) async {
    final database = await _db.database;
    return await database.query(
      'auth_logs',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'timestamp DESC',
    );
  }
}
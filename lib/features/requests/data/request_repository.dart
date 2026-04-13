import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/delivery/models/supply_request.dart';
import '../../../core/utils/app_logger.dart';

class RequestRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;

  /// ✅ DATABASE GETTER
  Future<Database> get database => _db.database;

  /// Create a new request (Citizen)
  Future<SupplyRequest> createRequest(SupplyRequest request) async {
    try {
      await _db.insertWithCRDT(
        table: 'supply_requests',
        values: request.toMap(),
        deviceId: request.deviceId,
        recordId: request.id,
      );

      AppLogger.info('✅ Request created: ${request.itemName} x${request.quantity}');
      return request;
    } catch (e, stack) {
      AppLogger.error('Failed to create request', e, stack);
      rethrow;
    }
  }

  /// Get all requests by user
  Future<List<SupplyRequest>> getMyRequests(String userId) async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'supply_requests',
        where: 'requester_id = ?',
        whereArgs: [userId],
        orderBy: 'created_at DESC',
      );

      return results.map((map) => SupplyRequest.fromMap(map)).toList();
    } catch (e, stack) {
      AppLogger.error('Failed to load user requests', e, stack);
      return [];
    }
  }

  /// Get all pending requests (Manager/Commander)
  Future<List<SupplyRequest>> getPendingRequests() async {
    try {
      final db = await _db.database;
      final results = await db.query(
        'supply_requests',
        where: 'status = ?',
        whereArgs: [RequestStatus.PENDING.toString()],
        orderBy: 'created_at ASC',
      );

      return results.map((map) => SupplyRequest.fromMap(map)).toList();
    } catch (e, stack) {
      AppLogger.error('Failed to load pending requests', e, stack);
      return [];
    }
  }

  /// ✅ GET ALL REQUESTS (for volunteers)
  Future<List<SupplyRequest>> getAllRequests() async {
    try {
      final db = await database;
      final results = await db.query(
        'supply_requests',
        orderBy: 'created_at DESC',
      );

      return results.map((map) => SupplyRequest.fromMap(map)).toList();
    } catch (e, stack) {
      AppLogger.error('Failed to load all requests', e, stack);
      return [];
    }
  }

  /// Approve request (Manager/Commander)
  Future<void> approveRequest(String requestId, String approverId) async {
    try {
      final db = await _db.database;
      await db.update(
        'supply_requests',
        {
          'status': RequestStatus.APPROVED.toString(),
          'approved_at': DateTime.now().toIso8601String(),
          'approved_by': approverId,
        },
        where: 'id = ?',
        whereArgs: [requestId],
      );

      AppLogger.info('✅ Request approved: $requestId by $approverId');
    } catch (e, stack) {
      AppLogger.error('Failed to approve request', e, stack);
      rethrow;
    }
  }

  /// Reject request
  Future<void> rejectRequest(String requestId, String reason) async {
    try {
      final db = await _db.database;
      await db.update(
        'supply_requests',
        {
          'status': RequestStatus.REJECTED.toString(),
          'rejected_reason': reason,
        },
        where: 'id = ?',
        whereArgs: [requestId],
      );

      AppLogger.info('❌ Request rejected: $requestId');
    } catch (e, stack) {
      AppLogger.error('Failed to reject request', e, stack);
      rethrow;
    }
  }

  /// Update request status
  Future<void> updateStatus(String requestId, RequestStatus status) async {
    try {
      final db = await _db.database;
      await db.update(
        'supply_requests',
        {'status': status.toString()},
        where: 'id = ?',
        whereArgs: [requestId],
      );
    } catch (e, stack) {
      AppLogger.error('Failed to update request status', e, stack);
      rethrow;
    }
  }
}
import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/user_model.dart';
import '../../../core/crypto/totp_manager.dart';
import '../../../core/crypto/key_manager.dart';
import '../../../core/crypto/audit_logger.dart';
import '../../../core/auth/user_role.dart';
import '../../../core/auth/rbac_manager.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/repositories/auth_repository.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final TOTPManager _totpManager;
  final KeyManager _keyManager;
  final AuditLogger _auditLogger = AuditLogger();
  final RBACManager _rbacManager = RBACManager();

  AuthRepositoryImpl({
    required TOTPManager totpManager,
    required KeyManager keyManager,
  })  : _totpManager = totpManager,
        _keyManager = keyManager;

  @override
  Future<UserModel?> login(String username, String otp) async {
    try {
      // Verify OTP (M1.1)
      if (!_totpManager.verifyOTP(otp)) {
        await _auditLogger.logAuthEvent(
          userId: username,
          eventType: AuthEventType.LOGIN_FAILED,
          deviceId: _keyManager.deviceId,
        );
        return null;
      }

      // Get user from DB
      final database = await _db.database;
      final result = await database.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      if (result.isEmpty) {
        AppLogger.warning('User not found: $username');
        return null;
      }

      final user = UserModel.fromMap(result.first);

      // Set current user in RBAC
      _rbacManager.setCurrentUser(user);

      // Log successful login (M1.4)
      await _auditLogger.logAuthEvent(
        userId: user.id,
        eventType: AuthEventType.LOGIN_SUCCESS,
        deviceId: _keyManager.deviceId,
      );

      return user;
    } catch (e, stack) {
      AppLogger.error('Login failed', e, stack);
      return null;
    }
  }

  @override
  Future<UserModel> register(String username, UserRole role) async {
    final user = UserModel.create(
      username: username,
      publicKey: _keyManager.publicKeyPem,
      role: role,
      deviceId: _keyManager.deviceId,
    );

    await _db.insertWithCRDT(
      table: 'users',
      values: user.toMap(),
      deviceId: _keyManager.deviceId,
      recordId: user.id,
    );

    // Set current user
    _rbacManager.setCurrentUser(user);

    AppLogger.info('✅ User registered: ${user.username} as ${RolePermissions.getRoleName(role)}');
    return user;
  }

  @override
  Future<void> logout() async {
    final user = _rbacManager.currentUser;

    if (user != null) {
      await _auditLogger.logAuthEvent(
        userId: user.id,
        eventType: AuthEventType.LOGOUT,
        deviceId: _keyManager.deviceId,
      );
    }

    _rbacManager.clearCurrentUser();
  }

  @override
  Future<String> generateOTP() async {
    final otp = _totpManager.generateOTP();

    if (_rbacManager.currentUser != null) {
      await _auditLogger.logAuthEvent(
        userId: _rbacManager.currentUser!.id,
        eventType: AuthEventType.OTP_GENERATED,
        deviceId: _keyManager.deviceId,
      );
    }

    return otp;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    return _rbacManager.currentUser;
  }

  @override
  Future<List<Map<String, dynamic>>> getAuditLogs(String userId) async {
    return await _auditLogger.getUserLogs(userId);
  }

  // Expose RBAC manager
  RBACManager get rbacManager => _rbacManager;
}
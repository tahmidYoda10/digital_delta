import 'package:uuid/uuid.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/user_model.dart';
import '../../../core/database/crdt/vector_clock.dart';
import '../../../core/crypto/totp_manager.dart';
import '../../../core/crypto/key_manager.dart';
import '../../../core/crypto/audit_logger.dart';
import '../../../core/utils/app_logger.dart';
import '../domain/repositories/auth_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthRepositoryImpl implements AuthRepository {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final TOTPManager _totpManager;
  final KeyManager _keyManager;
  final AuditLogger _auditLogger = AuditLogger();
  final Uuid _uuid = const Uuid();

  static const String _currentUserIdKey = 'current_user_id';

  AuthRepositoryImpl({
    required TOTPManager totpManager,
    required KeyManager keyManager,
  })  : _totpManager = totpManager,
        _keyManager = keyManager;

  @override
  Future<UserModel?> login(String username, String otp) async {
    try {
      AppLogger.info('🔐 Attempting login for: $username');

      // Verify OTP (M1.1)
      if (!_totpManager.verifyOTP(otp)) {
        AppLogger.warning('❌ Invalid OTP for $username');

        // Log failed attempt
        await _auditLogger.logAuthEvent(
          userId: username,
          eventType: AuthEventType.OTP_FAILED,
          deviceId: _keyManager.deviceId,
        );

        return null;
      }

      // Check if user exists
      final database = await _db.database;
      final result = await database.query(
        'users',
        where: 'username = ?',
        whereArgs: [username],
      );

      UserModel user;

      if (result.isEmpty) {
        AppLogger.warning('⚠️ User not found, creating new user');
        user = await register(username, UserRole.FIELD_VOLUNTEER);
      } else {
        user = UserModel.fromMap(result.first);
      }

      // Save current user
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currentUserIdKey, user.id);

      // Log successful login (M1.4)
      await _auditLogger.logAuthEvent(
        userId: user.id,
        eventType: AuthEventType.LOGIN_SUCCESS,
        deviceId: _keyManager.deviceId,
      );

      AppLogger.info('✅ Login successful for ${user.username}');
      return user;

    } catch (e, stack) {
      AppLogger.error('Login failed', e, stack);
      return null;
    }
  }

  @override
  Future<UserModel> register(String username, UserRole role) async {
    try {
      AppLogger.info('📝 Registering new user: $username');

      final userId = _uuid.v4();
      final now = DateTime.now();

      // Create vector clock (M2.2)
      final vectorClock = VectorClock();
      vectorClock.increment(_keyManager.deviceId);

      final user = UserModel(
        id: userId,
        username: username,
        publicKey: _keyManager.publicKeyPem,
        role: role,
        createdAt: now,
        vectorClock: vectorClock,
        deviceId: _keyManager.deviceId,
      );

      // Insert into database
      final database = await _db.database;
      await database.insert('users', user.toMap());

      AppLogger.info('✅ User registered: ${user.id}');
      return user;

    } catch (e, stack) {
      AppLogger.error('Registration failed', e, stack);
      rethrow;
    }
  }

  @override
  Future<String> generateOTP() async {
    final otp = _totpManager.generateOTP();

    // Log OTP generation
    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      await _auditLogger.logAuthEvent(
        userId: currentUser.id,
        eventType: AuthEventType.OTP_GENERATED,
        deviceId: _keyManager.deviceId,
      );
    }

    return otp;
  }

  @override
  Future<bool> verifyOTP(String code) async {
    final isValid = _totpManager.verifyOTP(code);

    final currentUser = await getCurrentUser();
    if (currentUser != null) {
      await _auditLogger.logAuthEvent(
        userId: currentUser.id,
        eventType: isValid ? AuthEventType.OTP_VERIFIED : AuthEventType.OTP_FAILED,
        deviceId: _keyManager.deviceId,
      );
    }

    return isValid;
  }

  @override
  Future<UserModel?> getCurrentUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString(_currentUserIdKey);

      if (userId == null) return null;

      final database = await _db.database;
      final result = await database.query(
        'users',
        where: 'id = ?',
        whereArgs: [userId],
      );

      if (result.isEmpty) return null;

      return UserModel.fromMap(result.first);

    } catch (e) {
      AppLogger.error('Failed to get current user', e);
      return null;
    }
  }

  @override
  Future<void> logout() async {
    final currentUser = await getCurrentUser();

    if (currentUser != null) {
      await _auditLogger.logAuthEvent(
        userId: currentUser.id,
        eventType: AuthEventType.LOGOUT,
        deviceId: _keyManager.deviceId,
      );
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_currentUserIdKey);

    AppLogger.info('👋 User logged out');
  }

  @override
  Future<List<Map<String, dynamic>>> getAuditLogs(String userId) async {
    return await _auditLogger.getUserLogs(userId);
  }
}
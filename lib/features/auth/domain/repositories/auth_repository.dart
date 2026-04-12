import '../../../../core/database/models/user_model.dart';

abstract class AuthRepository {
  Future<UserModel?> login(String username, String otp);
  Future<UserModel> register(String username, UserRole role);
  Future<String> generateOTP();
  Future<bool> verifyOTP(String code);
  Future<UserModel?> getCurrentUser();
  Future<void> logout();
  Future<List<Map<String, dynamic>>> getAuditLogs(String userId);
}
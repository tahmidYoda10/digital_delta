import '../../../../core/database/models/user_model.dart';
import '../../../../core/auth/user_role.dart';

abstract class AuthRepository {
  Future<UserModel?> login(String username, String otp);
  Future<UserModel> register(String username, UserRole role);
  Future<void> logout();
  Future<String> generateOTP();
  Future<UserModel?> getCurrentUser();
  Future<List<Map<String, dynamic>>> getAuditLogs(String userId);
}
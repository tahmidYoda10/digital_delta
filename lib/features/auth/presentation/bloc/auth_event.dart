import '../../../../core/auth/user_role.dart';

abstract class AuthEvent {}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String otp;

  AuthLoginRequested({required this.username, required this.otp});
}

class AuthRegisterRequested extends AuthEvent {
  final String username;
  final UserRole role;

  AuthRegisterRequested({required this.username, required this.role});
}

class AuthOTPGenerateRequested extends AuthEvent {}

class AuthLogoutRequested extends AuthEvent {}

class AuthAuditLogsRequested extends AuthEvent {
  final String userId;

  AuthAuditLogsRequested({required this.userId});
}
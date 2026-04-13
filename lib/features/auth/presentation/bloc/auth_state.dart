import '../../../../core/database/models/user_model.dart';

abstract class AuthState {
  const AuthState();
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);
}

class AuthUnauthenticated extends AuthState {}

class AuthOTPGenerated extends AuthState {
  final String otp;
  final int remainingSeconds;

  const AuthOTPGenerated({
    required this.otp,
    required this.remainingSeconds,
  });
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);
}

class AuthAuditLogsLoaded extends AuthState {
  final List<Map<String, dynamic>> logs;

  const AuthAuditLogsLoaded(this.logs);
}
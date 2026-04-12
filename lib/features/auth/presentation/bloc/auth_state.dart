import 'package:equatable/equatable.dart';
import '../../../../core/database/models/user_model.dart';

abstract class AuthState extends Equatable {
  const AuthState();

  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final UserModel user;

  const AuthAuthenticated(this.user);

  @override
  List<Object?> get props => [user];
}

class AuthUnauthenticated extends AuthState {}

class AuthOTPGenerated extends AuthState {
  final String otp;
  final int remainingSeconds;

  const AuthOTPGenerated({
    required this.otp,
    required this.remainingSeconds,
  });

  @override
  List<Object?> get props => [otp, remainingSeconds];
}

class AuthError extends AuthState {
  final String message;

  const AuthError(this.message);

  @override
  List<Object?> get props => [message];
}

class AuthAuditLogsLoaded extends AuthState {
  final List<Map<String, dynamic>> logs;

  const AuthAuditLogsLoaded(this.logs);

  @override
  List<Object?> get props => [logs];
}
import 'package:equatable/equatable.dart';
import '../../../../core/database/models/user_model.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthCheckRequested extends AuthEvent {}

class AuthLoginRequested extends AuthEvent {
  final String username;
  final String otp;

  const AuthLoginRequested({
    required this.username,
    required this.otp,
  });

  @override
  List<Object?> get props => [username, otp];
}

class AuthRegisterRequested extends AuthEvent {
  final String username;
  final UserRole role;

  const AuthRegisterRequested({
    required this.username,
    required this.role,
  });

  @override
  List<Object?> get props => [username, role];
}

class AuthOTPGenerateRequested extends AuthEvent {}

class AuthLogoutRequested extends AuthEvent {}

class AuthAuditLogsRequested extends AuthEvent {
  final String userId;

  const AuthAuditLogsRequested(this.userId);

  @override
  List<Object?> get props => [userId];
}
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/crypto/totp_manager.dart'; // ✅ FIXED PATH
import '../../domain/repositories/auth_repository.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final AuthRepository _authRepository;
  final TOTPManager _totpManager;

  AuthBloc({
    required AuthRepository authRepository,
    required TOTPManager totpManager,
  })  : _authRepository = authRepository,
        _totpManager = totpManager,
        super(AuthInitial()) {
    on<AuthCheckRequested>(_onAuthCheckRequested);
    on<AuthLoginRequested>(_onAuthLoginRequested);
    on<AuthRegisterRequested>(_onAuthRegisterRequested);
    on<AuthOTPGenerateRequested>(_onAuthOTPGenerateRequested);
    on<AuthLogoutRequested>(_onAuthLogoutRequested);
    on<AuthAuditLogsRequested>(_onAuthAuditLogsRequested);
  }

  Future<void> _onAuthCheckRequested(
      AuthCheckRequested event,
      Emitter<AuthState> emit,
      ) async {
    try {
      final user = await _authRepository.getCurrentUser();

      if (user != null) {
        emit(AuthAuthenticated(user));
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
    }
  }

  Future<void> _onAuthLoginRequested(
      AuthLoginRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      final user = await _authRepository.login(event.username, event.otp);

      if (user != null) {
        AppLogger.info('✅ Login successful: ${user.username}');
        emit(AuthAuthenticated(user));
      } else {
        emit(const AuthError('Invalid OTP or username'));
      }
    } catch (e) {
      AppLogger.error('Login failed', e);
      emit(AuthError('Login failed: ${e.toString()}'));
    }
  }

  Future<void> _onAuthRegisterRequested(
      AuthRegisterRequested event,
      Emitter<AuthState> emit,
      ) async {
    emit(AuthLoading());

    try {
      final user = await _authRepository.register(event.username, event.role);
      emit(AuthAuthenticated(user));
    } catch (e) {
      emit(AuthError('Registration failed: ${e.toString()}'));
    }
  }

  Future<void> _onAuthOTPGenerateRequested(
      AuthOTPGenerateRequested event,
      Emitter<AuthState> emit,
      ) async {
    try {
      final otp = await _authRepository.generateOTP();
      final remainingSeconds = _totpManager.getRemainingSeconds();

      emit(AuthOTPGenerated(
        otp: otp,
        remainingSeconds: remainingSeconds,
      ));
    } catch (e) {
      emit(AuthError('Failed to generate OTP: ${e.toString()}'));
    }
  }

  Future<void> _onAuthLogoutRequested(
      AuthLogoutRequested event,
      Emitter<AuthState> emit,
      ) async {
    await _authRepository.logout();
    emit(AuthUnauthenticated());
  }

  Future<void> _onAuthAuditLogsRequested(
      AuthAuditLogsRequested event,
      Emitter<AuthState> emit,
      ) async {
    try {
      final logs = await _authRepository.getAuditLogs(event.userId);
      emit(AuthAuditLogsLoaded(logs));
    } catch (e) {
      emit(AuthError('Failed to load audit logs: ${e.toString()}'));
    }
  }
}
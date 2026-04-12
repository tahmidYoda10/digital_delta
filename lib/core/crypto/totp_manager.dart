import 'package:otp/otp.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';
import '../utils/app_logger.dart';

class TOTPManager {
  static const String _secretKey = 'totp_secret';
  String? _secret;

  /// Initialize TOTP with existing or new secret
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    _secret = prefs.getString(_secretKey);

    if (_secret == null) {
      _secret = _generateSecret();
      await prefs.setString(_secretKey, _secret!);
      AppLogger.info('🔐 Generated new TOTP secret');
    } else {
      AppLogger.info('🔐 Loaded existing TOTP secret');
    }
  }

  /// Generate random base32 secret
  String _generateSecret() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final random = Random.secure();
    return List.generate(32, (_) => chars[random.nextInt(chars.length)]).join();
  }

  /// Generate current TOTP code (M1.1)
  String generateOTP() {
    if (_secret == null) {
      throw Exception('TOTP not initialized');
    }

    final code = OTP.generateTOTPCodeString(
      _secret!,
      DateTime.now().millisecondsSinceEpoch,
      length: 6,
      interval: 30, // 30 second window
      algorithm: Algorithm.SHA1, // Changed from SHA256 to SHA1 for compatibility
      isGoogle: true,
    );

    AppLogger.debug('🔢 Generated TOTP: $code');
    return code;
  }

  /// Verify TOTP code with tolerance window
  bool verifyOTP(String code) {
    if (_secret == null) return false;

    final now = DateTime.now().millisecondsSinceEpoch;

    // Check current window
    final currentCode = OTP.generateTOTPCodeString(
      _secret!,
      now,
      length: 6,
      interval: 30,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );

    if (code == currentCode) {
      AppLogger.debug('✅ TOTP verification: true (current window)');
      return true;
    }

    // Check previous window (30 seconds ago)
    final prevCode = OTP.generateTOTPCodeString(
      _secret!,
      now - 30000, // 30 seconds earlier
      length: 6,
      interval: 30,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );

    if (code == prevCode) {
      AppLogger.debug('✅ TOTP verification: true (previous window)');
      return true;
    }

    // Check next window (30 seconds ahead)
    final nextCode = OTP.generateTOTPCodeString(
      _secret!,
      now + 30000, // 30 seconds later
      length: 6,
      interval: 30,
      algorithm: Algorithm.SHA1,
      isGoogle: true,
    );

    if (code == nextCode) {
      AppLogger.debug('✅ TOTP verification: true (next window)');
      return true;
    }

    AppLogger.debug('❌ TOTP verification: false');
    return false;
  }

  /// Get remaining seconds until code expires
  int getRemainingSeconds() {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return 30 - (now % 30);
  }

  String get secret => _secret ?? '';
}
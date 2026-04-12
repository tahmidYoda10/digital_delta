import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../utils/app_logger.dart';
import '../crypto/key_manager.dart';
import 'models/pod_receipt.dart';
import 'pod_generator.dart';

enum VerificationResult {
  VALID,
  INVALID_SIGNATURE,
  REPLAY_ATTACK,
  TAMPERED,
  EXPIRED,
}

class PoDVerifier {
  final KeyManager _keyManager;
  final PoDGenerator _generator;

  PoDVerifier({
    required KeyManager keyManager,
    required PoDGenerator generator,
  })  : _keyManager = keyManager,
        _generator = generator;

  /// Verify PoD receipt (M5.2)
  VerificationResult verify(PoDReceipt receipt) {
    try {
      AppLogger.info('🔍 Verifying PoD: ${receipt.deliveryId}');

      // 1. Check integrity (tamper detection)
      if (!receipt.verifyIntegrity()) {
        AppLogger.warning('❌ PoD tampered: ${receipt.deliveryId}');
        return VerificationResult.TAMPERED;
      }

      // 2. Check for replay attack (M5.2)
      if (_generator.isNonceUsed(receipt.nonce)) {
        AppLogger.warning('❌ Replay attack detected: ${receipt.deliveryId}');
        return VerificationResult.REPLAY_ATTACK;
      }

      // 3. Check timestamp (not older than 24 hours)
      final age = DateTime.now().difference(receipt.timestamp);
      if (age.inHours > 24) {
        AppLogger.warning('❌ PoD expired: ${receipt.deliveryId}');
        return VerificationResult.EXPIRED;
      }

      // 4. Verify driver signature
      if (!_verifySignature(receipt)) {
        AppLogger.warning('❌ Invalid signature: ${receipt.deliveryId}');
        return VerificationResult.INVALID_SIGNATURE;
      }

      AppLogger.info('✅ PoD verified: ${receipt.deliveryId}');
      return VerificationResult.VALID;

    } catch (e, stack) {
      AppLogger.error('PoD verification failed', e, stack);
      return VerificationResult.INVALID_SIGNATURE;
    }
  }

  /// Verify signature
  bool _verifySignature(PoDReceipt receipt) {
    // Reconstruct payload
    final payloadData = '${receipt.deliveryId}|${receipt.driverPublicKey}|${receipt.recipientPublicKey}|${receipt.nonce}|${receipt.timestamp.toIso8601String()}';

    // In production, verify RSA signature with driver's public key
    // For now, check hash equality
    final expectedHash = sha256.convert(utf8.encode(payloadData + _extractDeviceId(receipt.driverPublicKey)));

    return expectedHash.toString() == receipt.driverSignature;
  }

  String _extractDeviceId(String publicKey) {
    // Extract device ID from public key metadata
    // Simplified for demo
    return _keyManager.deviceId;
  }
}
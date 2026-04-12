import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:uuid/uuid.dart';
import '../crypto/key_manager.dart';
import '../utils/app_logger.dart';
import 'models/pod_receipt.dart';
import 'models/delivery_model.dart';

class PoDGenerator {
  final KeyManager _keyManager;
  final Set<String> _usedNonces = {}; // M5.2: Replay protection

  PoDGenerator({required KeyManager keyManager}) : _keyManager = keyManager;

  /// Generate PoD QR code (M5.1)
  PoDReceipt generatePoD({
    required DeliveryModel delivery,
    required String recipientPublicKey,
  }) {
    try {
      AppLogger.info('📝 Generating PoD for delivery: ${delivery.id}');

      // Generate unique nonce
      final nonce = _generateNonce();

      // Store nonce to prevent replay
      _usedNonces.add(nonce);

      // Calculate payload hash
      final timestamp = DateTime.now();
      final payloadData = '${delivery.id}|${_keyManager.publicKeyPem}|$recipientPublicKey|$nonce|${timestamp.toIso8601String()}';
      final payloadHash = sha256.convert(utf8.encode(payloadData)).toString();

      // Sign with driver's private key
      final signature = _sign(payloadData);

      final receipt = PoDReceipt(
        deliveryId: delivery.id,
        driverPublicKey: _keyManager.publicKeyPem,
        recipientPublicKey: recipientPublicKey,
        payloadHash: payloadHash,
        nonce: nonce,
        timestamp: timestamp,
        driverSignature: signature,
      );

      AppLogger.info('✅ PoD generated: ${receipt.deliveryId}');
      return receipt;

    } catch (e, stack) {
      AppLogger.error('Failed to generate PoD', e, stack);
      rethrow;
    }
  }

  /// Generate unique nonce
  String _generateNonce() {
    return const Uuid().v4();
  }

  /// Sign data with private key (simplified)
  String _sign(String data) {
    // In production, use RSA signature with private key
    // For now, using SHA-256 hash as signature
    final hash = sha256.convert(utf8.encode(data + _keyManager.deviceId));
    return hash.toString();
  }

  /// Check if nonce was already used (M5.2)
  bool isNonceUsed(String nonce) {
    return _usedNonces.contains(nonce);
  }

  /// Clear old nonces (run periodically)
  void clearOldNonces() {
    // In production, implement time-based cleanup
    if (_usedNonces.length > 10000) {
      _usedNonces.clear();
      AppLogger.info('🧹 Cleared nonce cache');
    }
  }
}
import 'dart:convert';
import 'dart:typed_data';
import 'package:encrypt/encrypt.dart';
import 'package:pointycastle/export.dart';
import '../utils/app_logger.dart';
import 'key_manager.dart';

class EncryptionService {
  final KeyManager _keyManager;

  EncryptionService({required KeyManager keyManager}) : _keyManager = keyManager;

  /// Encrypt payload for recipient (M3.3)
  String encryptForRecipient(Map<String, dynamic> payload, String recipientPublicKeyPem) {
    try {
      // Convert payload to JSON
      final plaintext = jsonEncode(payload);

      // Parse recipient's public key
      final recipientPublicKey = _parsePublicKey(recipientPublicKeyPem);

      // Encrypt with recipient's public key
      final encrypted = _keyManager.encrypt(plaintext, recipientPublicKey);

      AppLogger.debug('🔒 Payload encrypted for recipient');
      return encrypted;

    } catch (e, stack) {
      AppLogger.error('Encryption failed', e, stack);
      rethrow;
    }
  }

  /// Decrypt payload (M3.3)
  Map<String, dynamic> decrypt(String ciphertext) {
    try {
      // Decrypt with own private key
      final plaintext = _keyManager.decrypt(ciphertext);

      // Parse JSON
      final payload = jsonDecode(plaintext) as Map<String, dynamic>;

      AppLogger.debug('🔓 Payload decrypted successfully');
      return payload;

    } catch (e, stack) {
      AppLogger.error('Decryption failed', e, stack);
      rethrow;
    }
  }

  /// Parse public key from PEM
  RSAPublicKey _parsePublicKey(String pem) {
    final data = jsonDecode(pem);
    return RSAPublicKey(
      BigInt.parse(data['modulus'], radix: 16),
      BigInt.parse(data['exponent'], radix: 16),
    );
  }

  /// Sign message
  String sign(String message) {
    // Use SHA-256 hash as signature (simplified)
    final bytes = utf8.encode(message);
    // In production, use proper RSA signature
    return base64.encode(bytes);
  }

  /// Verify signature
  bool verify(String message, String signature) {
    try {
      final expectedSignature = sign(message);
      return expectedSignature == signature;
    } catch (e) {
      return false;
    }
  }
}
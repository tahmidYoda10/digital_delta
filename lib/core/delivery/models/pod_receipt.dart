import 'dart:convert';
import 'package:crypto/crypto.dart';

class PoDReceipt {
  final String deliveryId;
  final String driverPublicKey;
  final String recipientPublicKey;
  final String payloadHash;
  final String nonce;
  final DateTime timestamp;
  final String driverSignature;
  final String? recipientSignature;

  PoDReceipt({
    required this.deliveryId,
    required this.driverPublicKey,
    required this.recipientPublicKey,
    required this.payloadHash,
    required this.nonce,
    required this.timestamp,
    required this.driverSignature,
    this.recipientSignature,
  });

  /// Generate QR code payload (M5.1)
  String toQRPayload() {
    final data = {
      'delivery_id': deliveryId,
      'driver_pubkey': driverPublicKey,
      'recipient_pubkey': recipientPublicKey,
      'payload_hash': payloadHash,
      'nonce': nonce,
      'timestamp': timestamp.toIso8601String(),
      'driver_signature': driverSignature,
    };

    return jsonEncode(data);
  }

  /// Parse from QR code payload
  factory PoDReceipt.fromQRPayload(String qrPayload) {
    final data = jsonDecode(qrPayload) as Map<String, dynamic>;

    return PoDReceipt(
      deliveryId: data['delivery_id'],
      driverPublicKey: data['driver_pubkey'],
      recipientPublicKey: data['recipient_pubkey'],
      payloadHash: data['payload_hash'],
      nonce: data['nonce'],
      timestamp: DateTime.parse(data['timestamp']),
      driverSignature: data['driver_signature'],
    );
  }

  /// Add recipient counter-signature
  PoDReceipt withRecipientSignature(String signature) {
    return PoDReceipt(
      deliveryId: deliveryId,
      driverPublicKey: driverPublicKey,
      recipientPublicKey: recipientPublicKey,
      payloadHash: payloadHash,
      nonce: nonce,
      timestamp: timestamp,
      driverSignature: driverSignature,
      recipientSignature: signature,
    );
  }

  /// Verify integrity (M5.2)
  bool verifyIntegrity() {
    // Recalculate payload hash
    final reconstructed = '$deliveryId|$driverPublicKey|$recipientPublicKey|$nonce|${timestamp.toIso8601String()}';
    final calculatedHash = sha256.convert(utf8.encode(reconstructed)).toString();

    return calculatedHash == payloadHash;
  }

  Map<String, dynamic> toMap() {
    return {
      'delivery_id': deliveryId,
      'driver_pubkey': driverPublicKey,
      'recipient_pubkey': recipientPublicKey,
      'payload_hash': payloadHash,
      'nonce': nonce,
      'timestamp': timestamp.toIso8601String(),
      'driver_signature': driverSignature,
      'recipient_signature': recipientSignature,
    };
  }

  @override
  String toString() {
    return 'PoDReceipt(delivery: $deliveryId, verified: ${verifyIntegrity()}, recipientSigned: ${recipientSignature != null})';
  }
}
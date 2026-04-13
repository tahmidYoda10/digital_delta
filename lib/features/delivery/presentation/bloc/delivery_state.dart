import '../../../../core/delivery/models/pod_receipt.dart';
import '../../../../core/delivery/pod_verifier.dart';

abstract class DeliveryState {
  const DeliveryState();
}

class DeliveryInitial extends DeliveryState {}

class DeliveryLoading extends DeliveryState {}

class DeliveryPoDGenerated extends DeliveryState {
  final PoDReceipt podReceipt;

  const DeliveryPoDGenerated(this.podReceipt);

  // Add qrPayload getter
  String get qrPayload => podReceipt.toQRPayload();
}

class DeliveryPoDVerified extends DeliveryState {
  final PoDReceipt podReceipt;
  final VerificationResult verificationResult;

  const DeliveryPoDVerified({
    required this.podReceipt,
    required this.verificationResult,
  });

  // Add result getter
  VerificationResult get result => verificationResult;
}

class DeliveryCompleted extends DeliveryState {
  const DeliveryCompleted();
}

class DeliveryError extends DeliveryState {
  final String message;

  const DeliveryError(this.message);
}
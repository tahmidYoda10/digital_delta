import 'package:equatable/equatable.dart';
import '../../../../core/delivery/models/pod_receipt.dart';
import '../../../../core/delivery/models/delivery_model.dart';
import '../../../../core/delivery/pod_verifier.dart';

abstract class DeliveryState extends Equatable {
  const DeliveryState();

  @override
  List<Object?> get props => [];
}

class DeliveryInitial extends DeliveryState {}

class DeliveryLoading extends DeliveryState {}

class DeliveryPoDGenerated extends DeliveryState {
  final PoDReceipt receipt;
  final String qrPayload;

  const DeliveryPoDGenerated({
    required this.receipt,
    required this.qrPayload,
  });

  @override
  List<Object?> get props => [receipt, qrPayload];
}

class DeliveryPoDVerified extends DeliveryState {
  final PoDReceipt receipt;
  final VerificationResult result;

  const DeliveryPoDVerified({
    required this.receipt,
    required this.result,
  });

  @override
  List<Object?> get props => [receipt, result];
}

class DeliveryCompleted extends DeliveryState {
  final String deliveryId;

  const DeliveryCompleted(this.deliveryId);

  @override
  List<Object?> get props => [deliveryId];
}

class DeliveryListLoaded extends DeliveryState {
  final List<DeliveryModel> deliveries;

  const DeliveryListLoaded(this.deliveries);

  @override
  List<Object?> get props => [deliveries];
}

class DeliveryError extends DeliveryState {
  final String message;

  const DeliveryError(this.message);

  @override
  List<Object?> get props => [message];
}
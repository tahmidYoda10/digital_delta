import 'package:equatable/equatable.dart';
import '../../../../core/delivery/models/delivery_model.dart';

abstract class DeliveryEvent extends Equatable {
  const DeliveryEvent();

  @override
  List<Object?> get props => [];
}

class DeliveryGeneratePoDRequested extends DeliveryEvent {
  final DeliveryModel delivery;
  final String recipientPublicKey;

  const DeliveryGeneratePoDRequested({
    required this.delivery,
    required this.recipientPublicKey,
  });

  @override
  List<Object?> get props => [delivery, recipientPublicKey];
}

class DeliveryVerifyPoDRequested extends DeliveryEvent {
  final String qrPayload;

  const DeliveryVerifyPoDRequested(this.qrPayload);

  @override
  List<Object?> get props => [qrPayload];
}

class DeliveryCounterSignRequested extends DeliveryEvent {
  final String deliveryId;

  const DeliveryCounterSignRequested(this.deliveryId);

  @override
  List<Object?> get props => [deliveryId];
}

class DeliveryListRequested extends DeliveryEvent {}
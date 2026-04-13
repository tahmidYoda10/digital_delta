import '../../../../core/delivery/models/delivery_model.dart';
import '../../../../core/delivery/models/pod_receipt.dart';

abstract class DeliveryEvent {}

class DeliveryGeneratePoDRequested extends DeliveryEvent {
  final DeliveryModel delivery;
  final String recipientPublicKey;

  DeliveryGeneratePoDRequested({
    required this.delivery,
    required this.recipientPublicKey,
  });
}

class DeliveryVerifyPoDRequested extends DeliveryEvent {
  final String qrData;

  DeliveryVerifyPoDRequested(this.qrData);
}

class DeliveryCompleteRequested extends DeliveryEvent {
  final String deliveryId;

  DeliveryCompleteRequested({required this.deliveryId});
}

class DeliveryScanQRRequested extends DeliveryEvent {
  final String qrData;

  DeliveryScanQRRequested({required this.qrData});
}
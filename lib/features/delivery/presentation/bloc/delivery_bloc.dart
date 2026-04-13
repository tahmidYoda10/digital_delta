import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/delivery/pod_generator.dart';
import '../../../../core/delivery/pod_verifier.dart';
import '../../../../core/delivery/models/pod_receipt.dart';
import '../../../../core/crypto/key_manager.dart';
import '../../../../core/utils/app_logger.dart';
import 'delivery_event.dart';
import 'delivery_state.dart';

class DeliveryBloc extends Bloc<DeliveryEvent, DeliveryState> {
  final PoDGenerator _podGenerator;
  final PoDVerifier _podVerifier;

  DeliveryBloc({
    required PoDGenerator podGenerator,
    required KeyManager keyManager,
  })  : _podGenerator = podGenerator,
        _podVerifier = PoDVerifier(
          generator: podGenerator,
          keyManager: keyManager,
        ),
        super(DeliveryInitial()) {
    on<DeliveryGeneratePoDRequested>(_onGeneratePoDRequested);
    on<DeliveryVerifyPoDRequested>(_onVerifyPoDRequested);
    on<DeliveryCompleteRequested>(_onCompleteRequested);
  }

  Future<void> _onGeneratePoDRequested(
      DeliveryGeneratePoDRequested event,
      Emitter<DeliveryState> emit,
      ) async {
    emit(DeliveryLoading());

    try {
      final podReceipt = _podGenerator.generatePoD(
        delivery: event.delivery,
        recipientPublicKey: event.recipientPublicKey,
      );

      AppLogger.info('✅ PoD generated for delivery: ${event.delivery.id}');
      emit(DeliveryPoDGenerated(podReceipt));
    } catch (e, stack) {
      AppLogger.error('Failed to generate PoD', e, stack);
      emit(DeliveryError('Failed to generate PoD: ${e.toString()}'));
    }
  }

  Future<void> _onVerifyPoDRequested(
      DeliveryVerifyPoDRequested event,
      Emitter<DeliveryState> emit,
      ) async {
    emit(DeliveryLoading());

    try {
      // Parse QR payload to PoDReceipt
      final podReceipt = PoDReceipt.fromQRPayload(event.qrData);

      // Verify using PoDVerifier
      final result = _podVerifier.verify(podReceipt);

      AppLogger.info('PoD verification result: $result');
      emit(DeliveryPoDVerified(
        podReceipt: podReceipt,
        verificationResult: result,
      ));
    } catch (e, stack) {
      AppLogger.error('Failed to verify PoD', e, stack);
      emit(DeliveryError('Verification error: ${e.toString()}'));
    }
  }

  Future<void> _onCompleteRequested(
      DeliveryCompleteRequested event,
      Emitter<DeliveryState> emit,
      ) async {
    emit(DeliveryLoading());

    try {
      // TODO: Update delivery status in database
      AppLogger.info('✅ Delivery completed: ${event.deliveryId}');
      emit(const DeliveryCompleted());
    } catch (e, stack) {
      AppLogger.error('Failed to complete delivery', e, stack);
      emit(DeliveryError('Failed to complete: ${e.toString()}'));
    }
  }
}
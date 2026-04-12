import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/delivery/pod_generator.dart';
import '../../../../core/delivery/pod_verifier.dart';
import '../../../../core/delivery/models/pod_receipt.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/delivery/models/delivery_model.dart';
import '../../../../core/database/database_helper.dart';
import 'delivery_event.dart';
import 'delivery_state.dart';

class DeliveryBloc extends Bloc<DeliveryEvent, DeliveryState> {
  final PoDGenerator _podGenerator;
  final PoDVerifier _podVerifier;
  final DatabaseHelper _db = DatabaseHelper.instance;

  DeliveryBloc({
    required PoDGenerator podGenerator,
    required PoDVerifier podVerifier,
  })  : _podGenerator = podGenerator,
        _podVerifier = podVerifier,
        super(DeliveryInitial()) {
    on<DeliveryGeneratePoDRequested>(_onGeneratePoDRequested);
    on<DeliveryVerifyPoDRequested>(_onVerifyPoDRequested);
    on<DeliveryCounterSignRequested>(_onCounterSignRequested);
    on<DeliveryListRequested>(_onListRequested);
  }

  Future<void> _onGeneratePoDRequested(
      DeliveryGeneratePoDRequested event,
      Emitter<DeliveryState> emit,
      ) async {
    emit(DeliveryLoading());

    try {
      final receipt = _podGenerator.generatePoD(
        delivery: event.delivery,
        recipientPublicKey: event.recipientPublicKey,
      );

      final qrPayload = receipt.toQRPayload();

      emit(DeliveryPoDGenerated(
        receipt: receipt,
        qrPayload: qrPayload,
      ));

    } catch (e) {
      emit(DeliveryError('Failed to generate PoD: ${e.toString()}'));
    }
  }

  Future<void> _onVerifyPoDRequested(
      DeliveryVerifyPoDRequested event,
      Emitter<DeliveryState> emit,
      ) async {
    emit(DeliveryLoading());

    try {
      final receipt = PoDReceipt.fromQRPayload(event.qrPayload);
      final result = _podVerifier.verify(receipt);

      emit(DeliveryPoDVerified(
        receipt: receipt,
        result: result,
      ));

    } catch (e) {
      emit(DeliveryError('Failed to verify PoD: ${e.toString()}'));
    }
  }

  Future<void> _onCounterSignRequested(
      DeliveryCounterSignRequested event,
      Emitter<DeliveryState> emit,
      ) async {
    try {
      // Update delivery status in database
      final database = await _db.database;
      await database.update(
        'deliveries',
        {'status': DeliveryStatus.COMPLETED.toString()},
        where: 'id = ?',
        whereArgs: [event.deliveryId],
      );

      emit(DeliveryCompleted(event.deliveryId));

    } catch (e) {
      emit(DeliveryError('Failed to complete delivery: ${e.toString()}'));
    }
  }

  Future<void> _onListRequested(
      DeliveryListRequested event,
      Emitter<DeliveryState> emit,
      ) async {
    emit(DeliveryLoading());

    try {
      final database = await _db.database;
      final results = await database.query('deliveries');

      final deliveries = results.map((row) => DeliveryModel.fromMap(row)).toList();

      emit(DeliveryListLoaded(deliveries));

    } catch (e) {
      emit(DeliveryError('Failed to load deliveries: ${e.toString()}'));
    }
  }
}
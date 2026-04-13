import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/triage/triage_engine.dart';
import '../../../../core/utils/app_logger.dart';
import 'triage_event.dart';
import 'triage_state.dart';

class TriageBloc extends Bloc<TriageEvent, TriageState> {
  final TriageEngine _triageEngine = TriageEngine();
  StreamSubscription? _decisionSubscription;

  TriageBloc() : super(TriageInitial()) {
    // Listen to triage decisions
    _decisionSubscription = _triageEngine.decisions.listen((decision) {
      add(TriageDecisionReceived(decision));
    });

    on<TriageRegisterDelivery>(_onRegisterDelivery);
    on<TriageUpdateRoute>(_onUpdateRoute);
    on<TriageCheckStatus>(_onCheckStatus);
    on<TriageDecisionReceived>(_onDecisionReceived);
  }

  Future<void> _onRegisterDelivery(
      TriageRegisterDelivery event,
      Emitter<TriageState> emit,
      ) async {
    try {
      _triageEngine.registerDelivery(event.delivery, event.route);

      final status = _triageEngine.getDeliveryStatus(event.delivery.id);

      emit(TriageMonitoring(
        deliveryId: event.delivery.id,
        status: status,
      ));

      AppLogger.info('✅ Triage monitoring started for ${event.delivery.id}');
    } catch (e) {
      emit(TriageError('Failed to register delivery: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateRoute(
      TriageUpdateRoute event,
      Emitter<TriageState> emit,
      ) async {
    try {
      await _triageEngine.onRouteChanged(
        deliveryId: event.deliveryId,
        newRoute: event.newRoute,
        oldRoute: event.oldRoute,
      );

      final status = _triageEngine.getDeliveryStatus(event.deliveryId);

      emit(TriageMonitoring(
        deliveryId: event.deliveryId,
        status: status,
      ));
    } catch (e) {
      emit(TriageError('Failed to update route: ${e.toString()}'));
    }
  }

  Future<void> _onCheckStatus(
      TriageCheckStatus event,
      Emitter<TriageState> emit,
      ) async {
    final status = _triageEngine.getDeliveryStatus(event.deliveryId);

    emit(TriageMonitoring(
      deliveryId: event.deliveryId,
      status: status,
    ));
  }

  Future<void> _onDecisionReceived(
      TriageDecisionReceived event,
      Emitter<TriageState> emit,
      ) async {
    emit(TriageDecisionMade(
      decision: event.decision,
      timestamp: DateTime.now(),
    ));

    AppLogger.warning('🚨 TRIAGE DECISION: ${event.decision.action} - ${event.decision.reason}');
  }

  @override
  Future<void> close() {
    _decisionSubscription?.cancel();
    _triageEngine.dispose();
    return super.close();
  }
}
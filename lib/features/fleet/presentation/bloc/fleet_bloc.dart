import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/fleet/models/drone_model.dart';
import '../../../../core/fleet/models/rendezvous_point.dart';
import '../../../../core/fleet/models/handoff_event.dart';
import 'fleet_event.dart';
import 'fleet_state.dart';

class FleetBloc extends Bloc<FleetEvent, FleetState> {
  FleetBloc() : super(FleetInitial()) {
    on<FleetLoadRequested>(_onLoadRequested);
    on<FleetInitializeRequested>(_onInitializeRequested);
    on<FleetCalculateRendezvousRequested>(_onCalculateRendezvousRequested);
    on<FleetExecuteHandoffRequested>(_onExecuteHandoffRequested);
  }

  Future<void> _onLoadRequested(
      FleetLoadRequested event,
      Emitter<FleetState> emit,
      ) async {
    emit(FleetLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(FleetLoaded(drones: _getMockDrones()));
    } catch (e, stack) {
      AppLogger.error('Failed to load fleet', e, stack);
      emit(FleetError(message: e.toString()));
    }
  }

  Future<void> _onInitializeRequested(
      FleetInitializeRequested event,
      Emitter<FleetState> emit,
      ) async {
    emit(FleetLoading());
    try {
      await Future.delayed(const Duration(seconds: 1));
      emit(FleetReady(drones: _getMockDrones()));
      AppLogger.info('✅ Fleet initialized');
    } catch (e) {
      emit(FleetError(message: e.toString()));
    }
  }

  Future<void> _onCalculateRendezvousRequested(
      FleetCalculateRendezvousRequested event,
      Emitter<FleetState> emit,
      ) async {
    try {
      emit(FleetLoading());

      final rendezvousPoint = RendezvousPoint.calculate(
        boatPosition: event.boatPosition,
        droneBasePosition: event.droneBasePosition,
        destinationPosition: event.destinationPosition,
        boatSpeedKmh: 30,
        droneSpeedKmh: 60,
      );

      emit(FleetRendezvousCalculated(rendezvousPoint: rendezvousPoint));
      AppLogger.info('✅ Rendezvous calculated: ${rendezvousPoint.position}');
    } catch (e, stack) {
      AppLogger.error('Failed to calculate rendezvous', e, stack);
      emit(FleetError(message: e.toString()));
    }
  }

  Future<void> _onExecuteHandoffRequested(
      FleetExecuteHandoffRequested event,
      Emitter<FleetState> emit,
      ) async {
    try {
      final handoff = HandoffEvent(
        id: 'handoff-${DateTime.now().millisecondsSinceEpoch}',
        deliveryId: event.deliveryId,
        boatId: event.boatId,
        droneId: event.droneId,
        rendezvousLat: 24.95,
        rendezvousLon: 91.85,
        initiatedAt: DateTime.now(),
        status: HandoffStatus.INITIATED,
      );

      emit(FleetHandoffInProgress(
        deliveryId: event.deliveryId,
        handoff: handoff,
      ));

      await Future.delayed(const Duration(seconds: 3));
      emit(FleetHandoffCompleted(deliveryId: event.deliveryId));

      AppLogger.info('✅ Handoff completed: ${event.deliveryId}');
    } catch (e, stack) {
      AppLogger.error('Failed to execute handoff', e, stack);
      emit(FleetError(message: e.toString()));
    }
  }

  List<DroneModel> _getMockDrones() {
    return [
      DroneModel(
        id: 'DRONE-001',
        baseStationId: 'BASE-001',
        maxRangeKm: 15.0,
        maxPayloadKg: 5.0,
        maxSpeedKmh: 60.0, // ✅ ADDED
        currentLat: 24.8949,
        currentLon: 91.8667,
        batteryPercent: 85.0,
        status: DroneStatus.IDLE,
      ),
      DroneModel(
        id: 'DRONE-002',
        baseStationId: 'BASE-001',
        maxRangeKm: 20.0,
        maxPayloadKg: 7.0,
        maxSpeedKmh: 70.0, // ✅ ADDED
        currentLat: 24.9000,
        currentLon: 91.8700,
        batteryPercent: 65.0,
        status: DroneStatus.IDLE,
      ),
      DroneModel(
        id: 'DRONE-003',
        baseStationId: 'BASE-001',
        maxRangeKm: 12.0,
        maxPayloadKg: 4.0,
        maxSpeedKmh: 50.0, // ✅ ADDED
        currentLat: 24.8850,
        currentLon: 91.8600,
        batteryPercent: 45.0,
        status: DroneStatus.CHARGING,
      ),
    ];
  }
}
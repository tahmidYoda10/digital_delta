import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/fleet/models/drone_model.dart';
import '../../../../core/fleet/models/handoff_event.dart';
import '../../../../core/utils/app_logger.dart';
import '../../domain/usecases/calculate_rendezvous_usecase.dart';
import 'fleet_event.dart';
import 'fleet_state.dart';

class FleetBloc extends Bloc<FleetEvent, FleetState> {
  final CalculateRendezvousUseCase _calculateRendezvousUseCase;
  final List<DroneModel> _drones = [];

  FleetBloc({
    required CalculateRendezvousUseCase calculateRendezvousUseCase,
  })  : _calculateRendezvousUseCase = calculateRendezvousUseCase,
        super(FleetInitial()) {
    on<FleetInitializeRequested>(_onInitializeRequested);
    on<FleetCalculateRendezvousRequested>(_onCalculateRendezvousRequested);
    on<FleetExecuteHandoffRequested>(_onExecuteHandoffRequested);
    on<FleetDroneStatusUpdated>(_onDroneStatusUpdated);
  }

  Future<void> _onInitializeRequested(
      FleetInitializeRequested event,
      Emitter<FleetState> emit,
      ) async {
    emit(FleetLoading());

    try {
      // Initialize demo drones
      _drones.clear();
      _drones.addAll([
        DroneModel(
          id: 'DRONE-001',
          baseStationId: 'BASE-001',
          currentPosition: const LatLng(24.8949, 91.8667),
          batteryPercent: 95.0,
        ),
        DroneModel(
          id: 'DRONE-002',
          baseStationId: 'BASE-002',
          currentPosition: const LatLng(25.0658, 91.4073),
          batteryPercent: 80.0,
        ),
      ]);

      emit(FleetReady(_drones));
      AppLogger.info('✅ Fleet initialized with ${_drones.length} drones');

    } catch (e) {
      emit(FleetError('Fleet initialization failed: ${e.toString()}'));
    }
  }

  Future<void> _onCalculateRendezvousRequested(
      FleetCalculateRendezvousRequested event,
      Emitter<FleetState> emit,
      ) async {
    try {
      final drone = _drones.firstWhere((d) => d.id == event.droneId);

      final rendezvousPoint = _calculateRendezvousUseCase.calculate(
        boatPosition: event.boatPosition,
        boatSpeedKmh: 30.0, // Average speedboat speed
        droneBasePosition: event.droneBasePosition,
        drone: drone,
        destinationPosition: event.destinationPosition,
      );

      if (rendezvousPoint != null) {
        emit(FleetRendezvousCalculated(rendezvousPoint));
      } else {
        emit(const FleetError('No valid rendezvous point found'));
      }

    } catch (e) {
      emit(FleetError('Rendezvous calculation failed: ${e.toString()}'));
    }
  }

  Future<void> _onExecuteHandoffRequested(
      FleetExecuteHandoffRequested event,
      Emitter<FleetState> emit,
      ) async {
    try {
      final handoff = HandoffEvent(
        id: const Uuid().v4(),
        deliveryId: event.deliveryId,
        boatId: 'BOAT-001',
        droneId: 'DRONE-001',
        status: HandoffStatus.INITIATED,
        initiatedAt: DateTime.now(),
      );

      emit(FleetHandoffInProgress(handoff));

      // Simulate handoff process
      await Future.delayed(const Duration(seconds: 3));

      final completedHandoff = handoff.copyWith(
        status: HandoffStatus.COMPLETED,
        completedAt: DateTime.now(),
      );

      emit(FleetHandoffCompleted(completedHandoff));
      AppLogger.info('✅ Handoff completed: ${handoff.id}');

    } catch (e) {
      emit(FleetError('Handoff failed: ${e.toString()}'));
    }
  }

  Future<void> _onDroneStatusUpdated(
      FleetDroneStatusUpdated event,
      Emitter<FleetState> emit,
      ) async {
    try {
      final droneIndex = _drones.indexWhere((d) => d.id == event.droneId);
      if (droneIndex != -1) {
        _drones[droneIndex] = _drones[droneIndex].copyWith(
          batteryPercent: event.batteryLevel,
        );
        emit(FleetReady(_drones));
      }
    } catch (e) {
      AppLogger.error('Failed to update drone status', e);
    }
  }
}
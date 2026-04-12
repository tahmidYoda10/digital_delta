import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routing/graph_manager.dart';
import '../../../../core/utils/app_logger.dart';
import 'routing_event.dart';
import 'routing_state.dart';

class RoutingBloc extends Bloc<RoutingEvent, RoutingState> {
  final GraphManager _graphManager;

  RoutingBloc({required GraphManager graphManager})
      : _graphManager = graphManager,
        super(RoutingInitial()) {
    on<RoutingInitializeRequested>(_onInitializeRequested);
    on<RoutingCalculateRouteRequested>(_onCalculateRouteRequested);
    on<RoutingUpdateEdgeRequested>(_onUpdateEdgeRequested);
    on<RoutingLoadGraphRequested>(_onLoadGraphRequested);
  }

  Future<void> _onInitializeRequested(
      RoutingInitializeRequested event,
      Emitter<RoutingState> emit,
      ) async {
    emit(RoutingLoading());

    try {
      await _graphManager.initialize();

      emit(RoutingReady(
        nodes: _graphManager.nodes,
        edges: _graphManager.edges,
      ));

      AppLogger.info('✅ Routing BLoC ready');
    } catch (e) {
      emit(RoutingError('Initialization failed: ${e.toString()}'));
    }
  }

  Future<void> _onCalculateRouteRequested(
      RoutingCalculateRouteRequested event,
      Emitter<RoutingState> emit,
      ) async {
    try {
      final stopwatch = Stopwatch()..start();

      final route = _graphManager.calculator?.calculateRoute(
        startNodeId: event.startNodeId,
        endNodeId: event.endNodeId,
        vehicleConstraints: event.vehicleConstraints,
      );

      stopwatch.stop();

      if (route != null) {
        emit(RoutingCalculated(
          route: route,
          calculationTime: stopwatch.elapsed,
        ));

        // M4.2: Log calculation time
        AppLogger.info('⏱️ Route calculation time: ${stopwatch.elapsedMilliseconds}ms');

        if (stopwatch.elapsedMilliseconds > 2000) {
          AppLogger.warning('⚠️ Route calculation exceeded 2s threshold!');
        }
      } else {
        emit(const RoutingError('Failed to calculate route'));
      }
    } catch (e) {
      emit(RoutingError('Route calculation error: ${e.toString()}'));
    }
  }

  Future<void> _onUpdateEdgeRequested(
      RoutingUpdateEdgeRequested event,
      Emitter<RoutingState> emit,
      ) async {
    try {
      await _graphManager.updateEdge(
        event.edgeId,
        isFlooded: event.isFlooded,
        riskScore: event.riskScore,
      );

      emit(RoutingEdgeUpdated(
        edgeId: event.edgeId,
        message: 'Edge updated successfully',
      ));

      // Emit ready state with updated graph
      emit(RoutingReady(
        nodes: _graphManager.nodes,
        edges: _graphManager.edges,
      ));
    } catch (e) {
      emit(RoutingError('Edge update failed: ${e.toString()}'));
    }
  }

  Future<void> _onLoadGraphRequested(
      RoutingLoadGraphRequested event,
      Emitter<RoutingState> emit,
      ) async {
    emit(RoutingLoading());

    try {
      await _graphManager.importFromJson(event.graphJson);

      emit(RoutingReady(
        nodes: _graphManager.nodes,
        edges: _graphManager.edges,
      ));
    } catch (e) {
      emit(RoutingError('Graph import failed: ${e.toString()}'));
    }
  }
}
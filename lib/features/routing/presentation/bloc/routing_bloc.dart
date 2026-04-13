import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/routing/graph_manager.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../../core/network/chaos_server.dart';
import '../../../../core/routing/flood_manager.dart';
import 'routing_event.dart';
import 'routing_state.dart';

class RoutingBloc extends Bloc<RoutingEvent, RoutingState> {
  final GraphManager _graphManager;
  late ChaosServer _chaosServer;
  late FloodManager _floodManager;
  StreamSubscription? _floodSubscription;

  RoutingBloc({required GraphManager graphManager})
      : _graphManager = graphManager,
        super(RoutingInitial()) {

    _floodManager = FloodManager(graphManager: _graphManager);
    _chaosServer = ChaosServer(graphManager: _graphManager);

    _floodSubscription = _floodManager.floodEvents.listen(_onFloodEvent);

    on<RoutingInitializeRequested>(_onInitializeRequested);
    on<RoutingCalculateRouteRequested>(_onCalculateRouteRequested);
    on<RoutingUpdateEdgeRequested>(_onUpdateEdgeRequested);
    on<RoutingLoadGraphRequested>(_onLoadGraphRequested);
    on<RoutingStartChaosRequested>(_onStartChaos);
    on<RoutingStopChaosRequested>(_onStopChaos);
    on<RoutingAutoRerouteRequested>(_onAutoReroute);
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
        chaosActive: false,
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
          chaosActive: _chaosServer.getFloodStatus()['chaos_active'] as bool,
          allEdges: _graphManager.edges, // ✅ Pass all edges
        ));

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

      emit(RoutingReady(
        nodes: _graphManager.nodes,
        edges: _graphManager.edges,
        chaosActive: _chaosServer.getFloodStatus()['chaos_active'] as bool,
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
        chaosActive: false,
      ));
    } catch (e) {
      emit(RoutingError('Graph import failed: ${e.toString()}'));
    }
  }

  Future<void> _onStartChaos(
      RoutingStartChaosRequested event,
      Emitter<RoutingState> emit,
      ) async {
    _chaosServer.start();
    AppLogger.info('⚡ Chaos mode activated!');

    if (state is RoutingReady) {
      emit((state as RoutingReady).copyWith(chaosActive: true));
    } else if (state is RoutingCalculated) {
      emit((state as RoutingCalculated).copyWith(chaosActive: true));
    }
  }

  Future<void> _onStopChaos(
      RoutingStopChaosRequested event,
      Emitter<RoutingState> emit,
      ) async {
    _chaosServer.stop();
    AppLogger.info('⚡ Chaos mode deactivated');

    if (state is RoutingReady) {
      emit((state as RoutingReady).copyWith(chaosActive: false));
    } else if (state is RoutingCalculated) {
      emit((state as RoutingCalculated).copyWith(chaosActive: false));
    }
  }

  Future<void> _onAutoReroute(
      RoutingAutoRerouteRequested event,
      Emitter<RoutingState> emit,
      ) async {
    AppLogger.warning('🔄 AUTO-REROUTE: Edge ${event.floodedEdgeId} flooded!');

    add(RoutingCalculateRouteRequested(
      startNodeId: event.startNodeId,
      endNodeId: event.endNodeId,
      vehicleConstraints: event.vehicleConstraints,
    ));
  }

  void _onFloodEvent(FloodEvent event) {
    if (state is RoutingCalculated) {
      final currentState = state as RoutingCalculated;
      final currentRoute = currentState.route;

      if (currentRoute.getEdgeIds().contains(event.edgeId) && event.isFlooded) {
        AppLogger.warning('⚠️ Active route affected by flood! Rerouting...');

        add(RoutingAutoRerouteRequested(
          floodedEdgeId: event.edgeId,
          startNodeId: currentRoute.nodes.first.id,
          endNodeId: currentRoute.nodes.last.id,
          vehicleConstraints: currentRoute.vehicleConstraints,
        ));
      }
    }
  }

  @override
  Future<void> close() {
    _floodSubscription?.cancel();
    _chaosServer.dispose();
    _floodManager.dispose();
    return super.close();
  }
}
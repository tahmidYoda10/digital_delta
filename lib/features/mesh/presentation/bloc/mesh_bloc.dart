import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/mesh/mesh_manager.dart';
import '../../../../core/network/mesh/mesh_node.dart';
import '../../../../core/utils/app_logger.dart';
import 'mesh_event.dart';
import 'mesh_state.dart';

class MeshBloc extends Bloc<MeshEvent, MeshState> {
  final MeshManager _meshManager;

  MeshBloc({required MeshManager meshManager})
      : _meshManager = meshManager,
        super(MeshInitial()) {
    on<MeshStartScanRequested>(_onStartScanRequested);
    on<MeshStopScanRequested>(_onStopScanRequested);
    on<MeshConnectToPeerRequested>(_onConnectToPeerRequested);
    on<MeshNodesUpdated>(_onNodesUpdated);

    // Listen to node updates
    _meshManager.nodesStream.listen((nodes) {
      add(MeshNodesUpdated(nodes: nodes));
    });
  }

  Future<void> _onStartScanRequested(
      MeshStartScanRequested event,
      Emitter<MeshState> emit,
      ) async {
    try {
      emit(MeshInitializing());
      await _meshManager.startScanning();
      emit(MeshScanning(discoveredNodes: [], nodeCount: 0));
      AppLogger.info('🔍 Mesh scanning started');
    } catch (e, stack) {
      AppLogger.error('Failed to start mesh scan', e, stack);
      emit(MeshError(message: e.toString()));
    }
  }

  Future<void> _onStopScanRequested(
      MeshStopScanRequested event,
      Emitter<MeshState> emit,
      ) async {
    emit(MeshInitial());
  }

  Future<void> _onConnectToPeerRequested(
      MeshConnectToPeerRequested event,
      Emitter<MeshState> emit,
      ) async {
    try {
      await _meshManager.connectToPeer(event.deviceId);
      AppLogger.info('✅ Connected to peer: ${event.deviceId}');
    } catch (e, stack) {
      AppLogger.error('Failed to connect to peer', e, stack);
      emit(MeshError(message: e.toString()));
    }
  }

  void _onNodesUpdated(
      MeshNodesUpdated event,
      Emitter<MeshState> emit,
      ) {
    if (state is MeshScanning) {
      emit(MeshScanning(
        discoveredNodes: event.nodes.cast<MeshNode>(),
        nodeCount: event.nodes.length,
      ));
    }
  }
}
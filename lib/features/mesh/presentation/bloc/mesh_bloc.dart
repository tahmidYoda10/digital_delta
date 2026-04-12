import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/network/mesh/mesh_manager.dart';
import '../../../../core/utils/app_logger.dart';
import 'mesh_event.dart';
import 'mesh_state.dart';

class MeshBloc extends Bloc<MeshEvent, MeshState> {
  final MeshManager _meshManager;

  MeshBloc({required MeshManager meshManager})
      : _meshManager = meshManager,
        super(MeshInitial()) {
    on<MeshInitializeRequested>(_onInitializeRequested);
    on<MeshStartScanRequested>(_onStartScanRequested);
    on<MeshStopScanRequested>(_onStopScanRequested);
    on<MeshConnectToPeerRequested>(_onConnectToPeerRequested);
    on<MeshSendMessageRequested>(_onSendMessageRequested);
    on<MeshMessageReceived>(_onMessageReceived);
    on<MeshNodesUpdated>(_onNodesUpdated);

    // Listen to mesh events
    _meshManager.messageStream.listen((message) {
      add(MeshMessageReceived(message));
    });

    _meshManager.nodesStream.listen((nodes) {
      add(MeshNodesUpdated(nodes));
    });
  }

  Future<void> _onInitializeRequested(
      MeshInitializeRequested event,
      Emitter<MeshState> emit,
      ) async {
    emit(MeshInitializing());

    try {
      await _meshManager.initialize();
      final stats = _meshManager.getStats();
      final localNodeId = stats['localNode']['deviceId'];

      emit(MeshReady(localNodeId));
      AppLogger.info('✅ Mesh BLoC ready');
    } catch (e) {
      emit(MeshError('Initialization failed: ${e.toString()}'));
    }
  }

  Future<void> _onStartScanRequested(
      MeshStartScanRequested event,
      Emitter<MeshState> emit,
      ) async {
    try {
      await _meshManager.startScanning();
      emit(const MeshScanning([]));
    } catch (e) {
      emit(MeshError('Scan failed: ${e.toString()}'));
    }
  }

  Future<void> _onStopScanRequested(
      MeshStopScanRequested event,
      Emitter<MeshState> emit,
      ) async {
    // Stop scan logic
    emit(const MeshScanning([]));
  }

  Future<void> _onConnectToPeerRequested(
      MeshConnectToPeerRequested event,
      Emitter<MeshState> emit,
      ) async {
    try {
      await _meshManager.connectToPeer(event.deviceId);
      emit(MeshConnected(peerId: event.deviceId, connectedNodes: const []));
    } catch (e) {
      emit(MeshError('Connection failed: ${e.toString()}'));
    }
  }

  Future<void> _onSendMessageRequested(
      MeshSendMessageRequested event,
      Emitter<MeshState> emit,
      ) async {
    try {
      await _meshManager.sendMessage(event.message);
      emit(MeshMessageSent(event.message.id));
    } catch (e) {
      emit(MeshError('Send failed: ${e.toString()}'));
    }
  }

  Future<void> _onMessageReceived(
      MeshMessageReceived event,
      Emitter<MeshState> emit,
      ) async {
    emit(MeshNewMessage(event.message));
  }

  Future<void> _onNodesUpdated(
      MeshNodesUpdated event,
      Emitter<MeshState> emit,
      ) async {
    emit(MeshScanning(event.nodes.cast()));
  }
}
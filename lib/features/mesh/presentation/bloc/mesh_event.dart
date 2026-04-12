import 'package:equatable/equatable.dart';
import '../../../../core/network/mesh/mesh_message.dart';

abstract class MeshEvent extends Equatable {
  const MeshEvent();

  @override
  List<Object?> get props => [];
}

class MeshInitializeRequested extends MeshEvent {}

class MeshStartScanRequested extends MeshEvent {}

class MeshStopScanRequested extends MeshEvent {}

class MeshConnectToPeerRequested extends MeshEvent {
  final String deviceId;

  const MeshConnectToPeerRequested(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}

class MeshSendMessageRequested extends MeshEvent {
  final MeshMessage message;

  const MeshSendMessageRequested(this.message);

  @override
  List<Object?> get props => [message];
}

class MeshMessageReceived extends MeshEvent {
  final MeshMessage message;

  const MeshMessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class MeshNodesUpdated extends MeshEvent {
  final List nodes;

  const MeshNodesUpdated(this.nodes);

  @override
  List<Object?> get props => [nodes];
}
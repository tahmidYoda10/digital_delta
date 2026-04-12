import 'package:equatable/equatable.dart';
import '../../../../core/network/mesh/mesh_node.dart';
import '../../../../core/network/mesh/mesh_message.dart';

abstract class MeshState extends Equatable {
  const MeshState();

  @override
  List<Object?> get props => [];
}

class MeshInitial extends MeshState {}

class MeshInitializing extends MeshState {}

class MeshReady extends MeshState {
  final String localNodeId;

  const MeshReady(this.localNodeId);

  @override
  List<Object?> get props => [localNodeId];
}

class MeshScanning extends MeshState {
  final List<MeshNode> discoveredNodes;

  const MeshScanning(this.discoveredNodes);

  @override
  List<Object?> get props => [discoveredNodes];
}

class MeshConnected extends MeshState {
  final String peerId;
  final List<MeshNode> connectedNodes;

  const MeshConnected({
    required this.peerId,
    required this.connectedNodes,
  });

  @override
  List<Object?> get props => [peerId, connectedNodes];
}

class MeshMessageSent extends MeshState {
  final String messageId;

  const MeshMessageSent(this.messageId);

  @override
  List<Object?> get props => [messageId];
}

class MeshNewMessage extends MeshState {
  final MeshMessage message;

  const MeshNewMessage(this.message);

  @override
  List<Object?> get props => [message];
}

class MeshError extends MeshState {
  final String message;

  const MeshError(this.message);

  @override
  List<Object?> get props => [message];
}
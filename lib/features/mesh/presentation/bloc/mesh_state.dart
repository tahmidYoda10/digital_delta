import '../../../../core/network/mesh/mesh_node.dart';

abstract class MeshState {}

class MeshInitial extends MeshState {}

class MeshInitializing extends MeshState {}

class MeshScanning extends MeshState {
  final List<MeshNode> discoveredNodes;
  final int nodeCount;

  MeshScanning({
    this.discoveredNodes = const [],
    this.nodeCount = 0,
  });
}

class MeshConnected extends MeshState {
  final MeshNode connectedNode;

  MeshConnected({required this.connectedNode});
}

class MeshError extends MeshState {
  final String message;

  MeshError({required this.message});
}
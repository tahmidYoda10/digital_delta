abstract class MeshEvent {}

class MeshStartScanRequested extends MeshEvent {}

class MeshStopScanRequested extends MeshEvent {}

class MeshConnectToPeerRequested extends MeshEvent {
  final String deviceId;

  MeshConnectToPeerRequested({required this.deviceId});
}

class MeshDisconnectRequested extends MeshEvent {}

class MeshNodesUpdated extends MeshEvent {
  final List<dynamic> nodes;

  MeshNodesUpdated({required this.nodes});
}
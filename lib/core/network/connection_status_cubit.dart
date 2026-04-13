import 'package:flutter_bloc/flutter_bloc.dart';

enum ConnectionStatus {
  OFFLINE,   // 🔴 No mesh connection
  SCANNING,  // 🟠 Searching for peers
  SYNCING,   // 🟠 Transferring CRDT data
  ONLINE,    // 🟢 Connected & synced
  CONFLICT,  // 🟣 CRDT conflict detected
}

class ConnectionStatusCubit extends Cubit<ConnectionStatus> {
  ConnectionStatusCubit() : super(ConnectionStatus.OFFLINE);

  int _connectedNodesCount = 0;
  int _conflictsCount = 0;

  void updateStatus(ConnectionStatus status) {
    emit(status);
  }

  void setScanning() => emit(ConnectionStatus.SCANNING);

  void setOnline(int nodeCount) {
    _connectedNodesCount = nodeCount;
    emit(ConnectionStatus.ONLINE);
  }

  void setSyncing() => emit(ConnectionStatus.SYNCING);

  void setOffline() {
    _connectedNodesCount = 0;
    emit(ConnectionStatus.OFFLINE);
  }

  void setConflict(int conflictCount) {
    _conflictsCount = conflictCount;
    emit(ConnectionStatus.CONFLICT);
  }

  String getStatusText() {
    switch (state) {
      case ConnectionStatus.OFFLINE:
        return 'Offline';
      case ConnectionStatus.SCANNING:
        return 'Scanning...';
      case ConnectionStatus.SYNCING:
        return 'Syncing...';
      case ConnectionStatus.ONLINE:
        return _connectedNodesCount > 0
            ? 'Online • $_connectedNodesCount devices'
            : 'Online';
      case ConnectionStatus.CONFLICT:
        return 'Conflict • $_conflictsCount items';
    }
  }

  String getStatusIcon() {
    switch (state) {
      case ConnectionStatus.OFFLINE:
        return '🔴';
      case ConnectionStatus.SCANNING:
        return '🟠';
      case ConnectionStatus.SYNCING:
        return '🟠';
      case ConnectionStatus.ONLINE:
        return '🟢';
      case ConnectionStatus.CONFLICT:
        return '🟣';
    }
  }
}
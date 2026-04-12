import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/mesh_bloc.dart';
import '../bloc/mesh_event.dart';
import '../bloc/mesh_state.dart';
import '../../../../core/network/mesh/mesh_message.dart';

class MeshDebugPage extends StatelessWidget {
  const MeshDebugPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mesh Network Debug'),
        actions: [
          IconButton(
            icon: const Icon(Icons.bluetooth_searching),
            onPressed: () {
              context.read<MeshBloc>().add(MeshStartScanRequested());
            },
          ),
        ],
      ),
      body: BlocBuilder<MeshBloc, MeshState>(
        builder: (context, state) {
          if (state is MeshInitializing) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is MeshError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  SizedBox(height: 16),
                  Text(state.message),
                ],
              ),
            );
          }

          if (state is MeshScanning) {
            return ListView(
              children: [
                ListTile(
                  title: Text('Scanning...'),
                  subtitle: Text('${state.discoveredNodes.length} nodes found'),
                ),
                ...state.discoveredNodes.map((node) {
                  return ListTile(
                    leading: Icon(Icons.devices),
                    title: Text(node.deviceName),
                    subtitle: Text('RSSI: ${node.signalStrength} | Battery: ${node.batteryLevel}%'),
                    trailing: IconButton(
                      icon: Icon(Icons.link),
                      onPressed: () {
                        context.read<MeshBloc>().add(
                          MeshConnectToPeerRequested(node.deviceId),
                        );
                      },
                    ),
                  );
                }),
              ],
            );
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bluetooth, size: 64),
                SizedBox(height: 16),
                Text('Mesh Network Ready'),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<MeshBloc>().add(MeshStartScanRequested());
                  },
                  child: Text('Start Scanning'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
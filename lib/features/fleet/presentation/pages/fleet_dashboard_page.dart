import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:latlong2/latlong.dart';
import '../bloc/fleet_bloc.dart';
import '../bloc/fleet_event.dart';
import '../bloc/fleet_state.dart';
import '../../../../core/fleet/models/drone_model.dart';
import '../../../../core/fleet/models/rendezvous_point.dart';
import '../../../../core/fleet/models/handoff_event.dart';

class FleetDashboardPage extends StatelessWidget {
  const FleetDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚁 Hybrid Fleet Dashboard'),
        backgroundColor: Colors.purple.shade700,
      ),
      body: BlocConsumer<FleetBloc, FleetState>(
        listener: (context, state) {
          if (state is FleetError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is FleetHandoffCompleted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('✅ Handoff completed successfully!'),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is FleetLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is FleetReady || state is FleetLoaded) {
            final drones = state is FleetReady
                ? state.drones
                : (state as FleetLoaded).drones;
            return _buildFleetView(context, drones);
          }

          if (state is FleetRendezvousCalculated) {
            return _buildRendezvousView(context, state.rendezvousPoint);
          }

          if (state is FleetHandoffInProgress) {
            return _buildHandoffView(context, state.handoff);
          }

          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.flight, size: 100, color: Colors.purple),
                const SizedBox(height: 24),
                const Text(
                  'Fleet Management',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    context.read<FleetBloc>().add(FleetInitializeRequested());
                  },
                  child: const Text('Initialize Fleet'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildFleetView(BuildContext context, List<DroneModel> drones) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text(
          'Active Drones',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        ...drones.map((drone) => Card(
          child: ListTile(
            leading: Icon(
              Icons.airplanemode_active,
              color: drone.batteryPercent > 50 ? Colors.green : Colors.orange,
              size: 32,
            ),
            title: Text(drone.id),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Battery: ${drone.batteryPercent.toStringAsFixed(0)}%'),
                Text('Range: ${drone.maxRangeKm} km'),
                Text('Status: ${drone.status.toString().split('.').last}'),
              ],
            ),
            trailing: CircularProgressIndicator(
              value: drone.batteryPercent / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation(
                drone.batteryPercent > 50 ? Colors.green : Colors.orange,
              ),
            ),
          ),
        )),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: () => _showRendezvousDialog(context, drones.first.id),
          icon: const Icon(Icons.calculate),
          label: const Text('Calculate Rendezvous'),
        ),
      ],
    );
  }

  Widget _buildRendezvousView(BuildContext context, RendezvousPoint rendezvousPoint) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Optimal Rendezvous Point',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(),
                _buildInfoRow('Position', '${rendezvousPoint.position.latitude.toStringAsFixed(4)}, ${rendezvousPoint.position.longitude.toStringAsFixed(4)}'),
                _buildInfoRow('Distance from Boat', '${rendezvousPoint.distanceFromBoatKm.toStringAsFixed(2)} km'),
                _buildInfoRow('Distance from Drone Base', '${rendezvousPoint.distanceFromDroneBaseKm.toStringAsFixed(2)} km'),
                _buildInfoRow('Total Travel Time', '${rendezvousPoint.totalTravelTimeMinutes.toStringAsFixed(0)} min'),
                const Divider(),
                Row(
                  children: [
                    Icon(
                      rendezvousPoint.isSynchronized() ? Icons.check_circle : Icons.warning,
                      color: rendezvousPoint.isSynchronized() ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      rendezvousPoint.isSynchronized()
                          ? 'Synchronized'
                          : 'Wait time: ${rendezvousPoint.getMaxWaitTime().inMinutes} min',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            context.read<FleetBloc>().add(
              FleetExecuteHandoffRequested(
                deliveryId: 'DELIVERY-001',
                droneId: 'DRONE-001',
                boatId: 'BOAT-001',
              ),
            );
          },
          icon: const Icon(Icons.send),
          label: const Text('Execute Handoff'),
        ),
      ],
    );
  }

  Widget _buildHandoffView(BuildContext context, HandoffEvent handoff) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text(
            'Handoff in Progress',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 16),
          Text('Boat: ${handoff.boatId}'),
          Text('Drone: ${handoff.droneId}'),
          Text('Status: ${handoff.status.toString().split('.').last}'),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          Text(value),
        ],
      ),
    );
  }

  void _showRendezvousDialog(BuildContext context, String droneId) {
    context.read<FleetBloc>().add(
      FleetCalculateRendezvousRequested(
        boatPosition: const LatLng(24.9, 91.8),
        droneBasePosition: const LatLng(24.8949, 91.8667),
        destinationPosition: const LatLng(25.0, 91.9),
        droneId: droneId,
      ),
    );
  }
}
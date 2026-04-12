import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../bloc/routing_bloc.dart';
import '../bloc/routing_event.dart';
import '../bloc/routing_state.dart';
import '../../../../core/routing/vehicle_constraints.dart';
import '../../../../core/routing/models/graph_node.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  String? _selectedStartNode;
  String? _selectedEndNode;
  VehicleConstraints _selectedVehicle = VehicleConstraints.truck;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Map'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<RoutingBloc>().add(RoutingInitializeRequested());
            },
          ),
        ],
      ),
      body: BlocConsumer<RoutingBloc, RoutingState>(
        listener: (context, state) {
          if (state is RoutingError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          } else if (state is RoutingCalculated) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Route calculated in ${state.calculationTime.inMilliseconds}ms',
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is RoutingLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is RoutingReady || state is RoutingCalculated) {
            return Column(
              children: [
                _buildControlPanel(context, state),
                Expanded(
                  child: _buildMap(context, state),
                ),
              ],
            );
          }

          return const Center(child: Text('Initialize routing'));
        },
      ),
    );
  }

  Widget _buildControlPanel(BuildContext context, RoutingState state) {
    Map<String, GraphNode> nodes = {};

    if (state is RoutingReady) {
      nodes = state.nodes;
    } else if (state is RoutingCalculated) {
      nodes = {for (var node in state.route.nodes) node.id: node};
    }

    // ✅ Handle empty state
    if (nodes.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Icon(Icons.warning, size: 48, color: Colors.orange),
              SizedBox(height: 16),
              Text('No graph data loaded'),
              SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  context.read<RoutingBloc>().add(RoutingInitializeRequested());
                },
                child: Text('Reload Graph'),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Route Planner',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            SizedBox(height: 16),

            // ✅ FIXED: Vehicle selector with SingleChildScrollView
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: SegmentedButton<VehicleConstraints>(
                segments: const [
                  ButtonSegment(
                    value: VehicleConstraints.truck,
                    label: Text('🚚 Truck'),
                  ),
                  ButtonSegment(
                    value: VehicleConstraints.speedboat,
                    label: Text('🚤 Boat'),
                  ),
                  ButtonSegment(
                    value: VehicleConstraints.drone,
                    label: Text('🚁 Drone'),
                  ),
                ],
                selected: {_selectedVehicle},
                onSelectionChanged: (Set<VehicleConstraints> selection) {
                  setState(() {
                    _selectedVehicle = selection.first;
                  });
                },
              ),
            ),
            const SizedBox(height: 16),

            // ✅ FIXED: Start/End selectors in Column instead of Row
            Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'Start Location',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.location_on, color: Colors.green),
                    isDense: true,
                  ),
                  value: _selectedStartNode,
                  items: nodes.values.map((node) {
                    return DropdownMenuItem(
                      value: node.id,
                      child: Text(
                        node.name ?? node.id,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedStartNode = value);
                  },
                ),
                SizedBox(height: 12),
                Icon(Icons.arrow_downward, color: Colors.blue),
                SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: InputDecoration(
                    labelText: 'End Location',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.flag, color: Colors.red),
                    isDense: true,
                  ),
                  value: _selectedEndNode,
                  items: nodes.values.map((node) {
                    return DropdownMenuItem(
                      value: node.id,
                      child: Text(
                        node.name ?? node.id,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedEndNode = value);
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Calculate button
            ElevatedButton.icon(
              onPressed: _selectedStartNode != null && _selectedEndNode != null
                  ? () {
                context.read<RoutingBloc>().add(
                  RoutingCalculateRouteRequested(
                    startNodeId: _selectedStartNode!,
                    endNodeId: _selectedEndNode!,
                    vehicleConstraints: _selectedVehicle,
                  ),
                );
              }
                  : null,
              icon: const Icon(Icons.route),
              label: const Text('Calculate Route'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            // ✅ Show route info
            if (state is RoutingCalculated && state.route.isValid) ...[
              SizedBox(height: 16),
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.green.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '✅ Route Found',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade700,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('Distance: ${state.route.totalDistance.toStringAsFixed(2)} km'),
                    Text('Time: ${state.route.estimatedTime.toStringAsFixed(1)} min'),
                    Text('Nodes: ${state.route.nodes.length}'),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMap(BuildContext context, RoutingState state) {
    final markers = <Marker>[];
    final polylines = <Polyline>[];

    if (state is RoutingReady) {
      // Show all nodes
      for (var node in state.nodes.values) {
        markers.add(
          Marker(
            point: node.position,
            width: 40,
            height: 40,
            child: Icon(
              _getNodeIcon(node.type),
              color: Colors.blue,
              size: 30,
            ),
          ),
        );
      }
    } else if (state is RoutingCalculated && state.route.isValid) {
      // Show route
      final route = state.route;

      // Mark start and end specially
      for (int i = 0; i < route.nodes.length; i++) {
        final node = route.nodes[i];
        Color color = Colors.blue;
        if (i == 0) color = Colors.green; // Start
        if (i == route.nodes.length - 1) color = Colors.red; // End

        markers.add(
          Marker(
            point: node.position,
            width: 40,
            height: 40,
            child: Icon(
              _getNodeIcon(node.type),
              color: color,
              size: 30,
            ),
          ),
        );
      }

      // Draw route line
      polylines.add(
        Polyline(
          points: route.nodes.map((n) => n.position).toList(),
          strokeWidth: 4.0,
          color: Colors.blue,
        ),
      );
    }

    return FlutterMap(
      mapController: _mapController,
      options: MapOptions(
        initialCenter: const LatLng(24.8949, 91.8667), // Sylhet
        initialZoom: 12.0,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.hackfusion.digital_delta',
        ),
        PolylineLayer(polylines: polylines),
        MarkerLayer(markers: markers),
      ],
    );
  }

  IconData _getNodeIcon(NodeType type) {
    switch (type) {
      case NodeType.CENTRAL_COMMAND:
        return Icons.account_balance;
      case NodeType.SUPPLY_DROP:
        return Icons.inventory;
      case NodeType.RELIEF_CAMP:
        return Icons.house;
      case NodeType.HOSPITAL:
        return Icons.local_hospital;
      case NodeType.DRONE_BASE:
        return Icons.airplanemode_active;
      default:
        return Icons.location_on;
    }
  }
}
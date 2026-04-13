import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import '../bloc/routing_bloc.dart';
import '../bloc/routing_event.dart';
import '../bloc/routing_state.dart';
import '../../../../core/routing/vehicle_constraints.dart';
import '../../../../core/routing/models/graph_node.dart';
import '../../../../core/routing/models/graph_edge.dart';
import '../../../../core/auth/rbac_manager.dart';
import '../../../../core/auth/permission_guard.dart';
import '../../../auth/data/auth_repository_impl.dart';
import '../widgets/flood_status_panel.dart';

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
  bool _chaosActive = false;

  late RBACManager _rbacManager;
  late PermissionGuard _permissionGuard;

  @override
  void initState() {
    super.initState();

    // Get RBAC
    final authRepo = RepositoryProvider.of<AuthRepositoryImpl>(context, listen: false);
    _rbacManager = authRepo.rbacManager;
    _permissionGuard = PermissionGuard(_rbacManager);

    // ✅ ROUTE GUARD - Check access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_permissionGuard.canNavigate(context, 'delivery:read')) {
        // Will auto-close and show error
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Route Map'),
        actions: [
          // ✅ CHAOS TOGGLE - Protected
          BlocBuilder<RoutingBloc, RoutingState>(
            builder: (context, state) {
              if (state is RoutingReady) {
                _chaosActive = state.chaosActive;
              } else if (state is RoutingCalculated) {
                _chaosActive = state.chaosActive;
              }

              // Only show if has permission
              if (!_rbacManager.hasPermission('mesh:admin')) {
                return const SizedBox.shrink(); // Hide button
              }

              return IconButton(
                icon: Icon(
                  Icons.thunderstorm,
                  color: _chaosActive ? Colors.orange : Colors.grey,
                ),
                tooltip: _chaosActive ? 'Stop Chaos Mode' : 'Start Chaos Mode',
                onPressed: _toggleChaos,
              );
            },
          ),
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

  // ✅ PROTECTED CHAOS TOGGLE
  void _toggleChaos() {
    if (!_permissionGuard.checkAndShowError(
      context,
      'mesh:admin',
      customMessage: 'Only Administrators can control Chaos Mode',
    )) {
      return; // ❌ Blocked
    }

    // ✅ Proceed
    if (_chaosActive) {
      context.read<RoutingBloc>().add(RoutingStopChaosRequested());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚡ Chaos Mode Deactivated'),
          backgroundColor: Colors.grey,
        ),
      );
    } else {
      context.read<RoutingBloc>().add(RoutingStartChaosRequested());
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⚡ Chaos Mode Activated - Random flooding every 30s'),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Widget _buildControlPanel(BuildContext context, RoutingState state) {
    Map<String, GraphNode> nodes = {};

    if (state is RoutingReady) {
      nodes = state.nodes;
    } else if (state is RoutingCalculated) {
      nodes = {for (var node in state.route.nodes) node.id: node};
    }

    if (nodes.isEmpty) {
      return Card(
        margin: const EdgeInsets.all(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.warning, size: 48, color: Colors.orange),
              const SizedBox(height: 16),
              const Text('No graph data loaded'),
              const SizedBox(height: 8),
              ElevatedButton(
                onPressed: () {
                  context.read<RoutingBloc>().add(RoutingInitializeRequested());
                },
                child: const Text('Reload Graph'),
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
            const SizedBox(height: 16),

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

            Column(
              children: [
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
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
                        node.name,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() => _selectedStartNode = value);
                  },
                ),
                const SizedBox(height: 12),
                const Icon(Icons.arrow_downward, color: Colors.blue),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  decoration: const InputDecoration(
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
                        node.name,
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

            // ✅ PROTECTED CALCULATE BUTTON
            ElevatedButton.icon(
              onPressed: _selectedStartNode != null && _selectedEndNode != null
                  ? _calculateRoute
                  : null,
              icon: const Icon(Icons.route),
              label: const Text('Calculate Route'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
              ),
            ),

            if (state is RoutingCalculated && state.route.isValid) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
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
                    const SizedBox(height: 8),
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

  // ✅ PROTECTED ROUTE CALCULATION
  void _calculateRoute() {
    if (!_permissionGuard.checkAndShowError(
      context,
      'delivery:create',
      customMessage: 'You need Field Volunteer role or higher to plan routes',
    )) {
      return; // ❌ Blocked
    }

    // ✅ Proceed
    context.read<RoutingBloc>().add(
      RoutingCalculateRouteRequested(
        startNodeId: _selectedStartNode!,
        endNodeId: _selectedEndNode!,
        vehicleConstraints: _selectedVehicle,
      ),
    );
  }

  Widget _buildMap(BuildContext context, RoutingState state) {
    final markers = <Marker>[];
    final polylines = <Polyline>[];
    List<GraphEdge> allEdges = [];
    bool chaosActive = false;

    if (state is RoutingReady) {
      allEdges = state.edges;
      chaosActive = state.chaosActive;

      // Draw ALL edges with color coding
      for (var edge in state.edges) {
        final sourceNode = state.nodes[edge.sourceId];
        final targetNode = state.nodes[edge.targetId];

        if (sourceNode != null && targetNode != null) {
          polylines.add(
            Polyline(
              points: [sourceNode.position, targetNode.position],
              strokeWidth: edge.isFlooded ? 4.0 : 2.0,
              color: _getEdgeColor(edge),
              isDotted: edge.isFlooded,
            ),
          );
        }
      }

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
      final route = state.route;
      chaosActive = state.chaosActive;
      allEdges = state.allEdges;

      // Mark start and end specially
      for (int i = 0; i < route.nodes.length; i++) {
        final node = route.nodes[i];
        Color color = Colors.blue;
        if (i == 0) color = Colors.green;
        if (i == route.nodes.length - 1) color = Colors.red;

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

      // Draw route line (thick blue)
      polylines.add(
        Polyline(
          points: route.nodes.map((n) => n.position).toList(),
          strokeWidth: 5.0,
          color: Colors.blue,
        ),
      );
    }

    return Stack(
      children: [
        // Map
        FlutterMap(
          mapController: _mapController,
          options: const MapOptions(
            initialCenter: LatLng(24.8949, 91.8667),
            initialZoom: 10.0,
          ),
          children: [
            TileLayer(
              urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
              userAgentPackageName: 'com.hackfusion.digital_delta',
            ),
            PolylineLayer(polylines: polylines),
            MarkerLayer(markers: markers),
          ],
        ),

        // Flood Status Panel (top-right)
        if (allEdges.isNotEmpty)
          Positioned(
            top: 16,
            right: 16,
            child: FloodStatusPanel(
              edges: allEdges,
              chaosActive: chaosActive,
            ),
          ),

        // Legend (bottom-left)
        Positioned(
          bottom: 16,
          left: 16,
          child: _buildLegend(),
        ),
      ],
    );
  }

  Color _getEdgeColor(GraphEdge edge) {
    if (edge.isFlooded) {
      return Colors.red;
    } else if (edge.riskScore > 0.7) {
      return Colors.orange;
    } else if (edge.riskScore > 0.3) {
      return Colors.yellow;
    } else {
      return Colors.green.withOpacity(0.6);
    }
  }

  Widget _buildLegend() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Legend',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _LegendItem(color: Colors.green, label: 'Safe Route'),
          _LegendItem(color: Colors.yellow, label: 'At Risk'),
          _LegendItem(color: Colors.orange, label: 'High Risk'),
          _LegendItem(color: Colors.red, label: 'Flooded'),
          const SizedBox(height: 4),
          _LegendItem(color: Colors.blue, label: 'Active Route', thick: true),
        ],
      ),
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

class _LegendItem extends StatelessWidget {
  final Color color;
  final String label;
  final bool thick;

  const _LegendItem({
    required this.color,
    required this.label,
    this.thick = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 20,
            height: thick ? 4 : 2,
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 11),
          ),
        ],
      ),
    );
  }
}
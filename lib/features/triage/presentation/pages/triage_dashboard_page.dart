import 'package:flutter/material.dart';
import '../../../../core/delivery/models/delivery_model.dart';
import '../../../../core/delivery/models/cargo_item.dart';
import '../../../../core/routing/models/route.dart' as routing; // ✅ ALIAS TO AVOID CONFLICT
import '../../../../core/routing/vehicle_constraints.dart'; // ✅ ADD THIS
import '../../domain/usecases/evaluate_preemption_usecase.dart';

class TriageDashboardPage extends StatefulWidget {
  const TriageDashboardPage({super.key});

  @override
  State<TriageDashboardPage> createState() => _TriageDashboardPageState();
}

class _TriageDashboardPageState extends State<TriageDashboardPage> {
  final EvaluatePreemptionUseCase _triageEngine = EvaluatePreemptionUseCase();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Triage Dashboard'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSLAOverview(),
          const SizedBox(height: 16),
          _buildActiveDeliveries(),
          const SizedBox(height: 16),
          _buildTriageSimulator(),
        ],
      ),
    );
  }

  Widget _buildSLAOverview() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'SLA Status',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildSLAChip('P0 (2h)', 3, Colors.red),
                _buildSLAChip('P1 (6h)', 7, Colors.orange),
                _buildSLAChip('P2 (24h)', 12, Colors.blue),
                _buildSLAChip('P3 (72h)', 5, Colors.green),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSLAChip(String label, int count, Color color) {
    return Column(
      children: [
        CircleAvatar(
          backgroundColor: color,
          child: Text(
            count.toString(),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildActiveDeliveries() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Active Deliveries',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.local_shipping, color: Colors.blue),
              title: const Text('DELIVERY-001'),
              subtitle: const Text('P0 Critical • ETA: 45 min'),
              trailing: Chip(
                label: const Text('On Time'),
                backgroundColor: Colors.green.shade100,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.local_shipping, color: Colors.orange),
              title: const Text('DELIVERY-002'),
              subtitle: const Text('P1 High • ETA: 2h 30min'),
              trailing: Chip(
                label: const Text('At Risk'),
                backgroundColor: Colors.orange.shade100,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTriageSimulator() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Triage Simulator',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: _simulateRouteDelay,
              icon: const Icon(Icons.warning),
              label: const Text('Simulate 30% Route Delay'),
            ),
          ],
        ),
      ),
    );
  }

  void _simulateRouteDelay() {
    // Demo triage evaluation
    final demoDelivery = DeliveryModel.create(
      supplyId: 'SUPPLY-001',
      driverId: 'DRIVER-001',
      cargo: [
        CargoItem(
          id: 'CARGO-P0',
          name: 'Antivenom',
          weightKg: 5.0,
          priority: CargoPriority.P0_CRITICAL,
          createdAt: DateTime.now(),
          slaDeadline: DateTime.now().add(const Duration(hours: 2)),
        ),
        CargoItem(
          id: 'CARGO-P2',
          name: 'Blankets',
          weightKg: 20.0,
          priority: CargoPriority.P2_STANDARD,
          createdAt: DateTime.now(),
          slaDeadline: DateTime.now().add(const Duration(hours: 24)),
        ),
      ],
      deviceId: 'DEVICE-001',
    );

    // Dummy route (✅ USING ALIAS)
    final dummyRoute = routing.Route(
      id: 'ROUTE-001',
      nodes: [],
      edges: [],
      vehicleConstraints: VehicleConstraints.truck,
      totalDistance: 50.0,
      estimatedTime: 90.0, // 90 minutes
      calculatedAt: DateTime.now(),
    );

    final decision = _triageEngine.evaluate(
      delivery: demoDelivery,
      currentRoute: dummyRoute,
      routeDelayPercent: 0.3,
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Triage Decision: ${decision.action}'),
        content: Text(decision.reason),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }
}
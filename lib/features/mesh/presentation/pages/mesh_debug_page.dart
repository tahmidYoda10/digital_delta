import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/mesh_bloc.dart';
import '../bloc/mesh_event.dart';
import '../bloc/mesh_state.dart';
import '../../../../core/network/mesh/mesh_node.dart';
import '../../../../core/database/crdt/supply_inventory_crdt.dart';
import '../../../../core/database/crdt/vector_clock.dart';
import '../../../../core/network/mesh/battery_optimizer.dart';

class MeshDebugPage extends StatefulWidget {
  const MeshDebugPage({super.key});

  @override
  State<MeshDebugPage> createState() => _MeshDebugPageState();
}

class _MeshDebugPageState extends State<MeshDebugPage> {
  late final SupplyInventoryCRDT _localCRDT;
  late final BatteryOptimizer _batteryOptimizer;

  @override
  void initState() {
    super.initState();
    _localCRDT = SupplyInventoryCRDT(); // ✅ Now works
    _batteryOptimizer = BatteryOptimizer();
    _batteryOptimizer.initialize();
    _simulateCRDTData();
  }

  void _simulateCRDTData() {
    // Simulate local updates
    final localClock = VectorClock();
    localClock.increment('device-A');

    _localCRDT.updateItem('Rice', 100, localClock, 'device-A');
    _localCRDT.updateItem('Water', 200, localClock, 'device-A');
    _localCRDT.updateItem('Medicine', 50, localClock, 'device-A');
  }

  void _simulateConflict() {
    // Simulate concurrent update from remote device
    final remoteCRDT = SupplyInventoryCRDT();
    final remoteClock = VectorClock();
    remoteClock.increment('device-B');

    // Same item, different value, concurrent timestamp
    remoteCRDT.updateItem('Rice', 80, remoteClock, 'device-B');

    // Merge - this will create a conflict
    _localCRDT.merge(remoteCRDT, 'device-A');

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔷 Mesh Network Debug'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<MeshBloc>().add(MeshStartScanRequested());
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Battery Optimizer Section (M8.4)
          _buildBatterySection(),
          const SizedBox(height: 16),

          // CRDT Inventory Section (M2.1)
          _buildCRDTSection(),
          const SizedBox(height: 16),

          // Conflict Detection Section (M2.3)
          _buildConflictSection(),
          const SizedBox(height: 16),

          // Mesh Nodes Section
          _buildMeshNodesSection(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _simulateConflict,
        icon: const Icon(Icons.warning),
        label: const Text('Simulate Conflict'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  Widget _buildBatterySection() {
    final stats = _batteryOptimizer.getBatterySavings();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '🔋 Battery Optimization (M8.4)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            _buildStatRow('Battery Level', '${stats['battery_level'].toStringAsFixed(1)}%'),
            _buildStatRow('Broadcast Interval', '${stats['current_interval_ms']}ms'),
            _buildStatRow('Power Savings', '${stats['savings_percent'].toStringAsFixed(1)}%'),
            _buildStatRow('Is Stationary', stats['is_stationary'] ? 'Yes' : 'No'),
            _buildStatRow('Nearby Nodes', '${stats['nearby_nodes']}'),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: stats['battery_level'] / 100,
              backgroundColor: Colors.grey.shade300,
              valueColor: AlwaysStoppedAnimation<Color>(
                stats['battery_level'] > 30 ? Colors.green : Colors.red,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCRDTSection() {
    final items = _localCRDT.getAllItems();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '📦 CRDT Inventory (M2.1)',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (items.isEmpty)
              const Text('No items in inventory')
            else
              ...items.entries.map((entry) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500)),
                      Chip(
                        label: Text('${entry.value} units'),
                        backgroundColor: Colors.blue.shade100,
                      ),
                    ],
                  ),
                );
              }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictSection() {
    final conflicts = _localCRDT.getConflicts();

    if (conflicts.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.check_circle, size: 48, color: Colors.green),
              const SizedBox(height: 12),
              const Text(
                'No Conflicts Detected',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'All CRDT merges successful',
                style: TextStyle(color: Colors.grey.shade600),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Colors.orange.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.warning, color: Colors.orange),
                const SizedBox(width: 8),
                const Text(
                  '⚠️ Conflicts Detected (M2.3)',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...conflicts.map((conflict) => _buildConflictCard(conflict)).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildConflictCard(ConflictRecord conflict) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade300),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Item: ${conflict.itemId}',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildConflictOption(
                  'Device A (Local)',
                  conflict.localValue,
                  conflict.localTimestamp,
                  conflict.localClock,
                  conflict.getWinner() == 'Local',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildConflictOption(
                  'Device B (Remote)',
                  conflict.remoteValue,
                  conflict.remoteTimestamp,
                  conflict.remoteClock,
                  conflict.getWinner() == 'Remote',
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Resolution: ${conflict.getWinner()} wins (Latest timestamp)',
            style: TextStyle(
              color: Colors.green.shade700,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () {
                  _localCRDT.resolveConflict(
                    conflict.itemId,
                    conflict.localValue,
                    'device-A',
                  );
                  setState(() {});
                },
                child: const Text('Accept Local'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: () {
                  _localCRDT.resolveConflict(
                    conflict.itemId,
                    conflict.remoteValue,
                    'device-A',
                  );
                  setState(() {});
                },
                child: const Text('Accept Remote'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildConflictOption(
      String label,
      int value,
      DateTime timestamp,
      VectorClock clock,
      bool isWinner,
      ) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isWinner ? Colors.green.shade50 : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isWinner ? Colors.green : Colors.grey.shade300,
          width: isWinner ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: isWinner ? Colors.green.shade700 : Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          Text('Value: $value', style: const TextStyle(fontSize: 12)),
          Text(
            'Time: ${timestamp.hour}:${timestamp.minute}:${timestamp.second}',
            style: const TextStyle(fontSize: 11),
          ),
          Text(
            'Clock: ${clock.toMap().entries.take(2).map((e) => '${e.key.substring(0, 3)}:${e.value}').join(', ')}',
            style: const TextStyle(fontSize: 10),
          ),
          if (isWinner)
            const Padding(
              padding: EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.check, size: 14, color: Colors.green),
                  SizedBox(width: 4),
                  Text(
                    'Winner',
                    style: TextStyle(color: Colors.green, fontSize: 11),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMeshNodesSection() {
    return BlocBuilder<MeshBloc, MeshState>(
      builder: (context, state) {
        if (state is MeshScanning) {
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '📡 Discovered Nodes',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  Text('Found ${state.nodeCount} devices'),
                  const SizedBox(height: 8),
                  if (state.discoveredNodes.isEmpty)
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No nodes discovered yet...'),
                      ),
                    )
                  else
                    ...state.discoveredNodes.map((node) => _NodeTile(node: node)).toList(),
                ],
              ),
            ),
          );
        }
        return const SizedBox();
      },
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.grey.shade700)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _batteryOptimizer.dispose();
    super.dispose();
  }
}

class _NodeTile extends StatelessWidget {
  final MeshNode node;

  const _NodeTile({required this.node});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Icon(Icons.phone_android, color: _getStatusColor(node.status)),
      title: Text(node.deviceName),
      subtitle: Text('RSSI: ${node.signalStrength} dBm • Battery: ${node.batteryLevel}%'),
      trailing: Chip(
        label: Text(
          node.status.toString().split('.').last,
          style: const TextStyle(fontSize: 11),
        ),
        backgroundColor: _getStatusColor(node.status).withOpacity(0.2),
      ),
    );
  }

  Color _getStatusColor(NodeStatus status) {
    switch (status) {
      case NodeStatus.OFFLINE:
        return Colors.grey;
      case NodeStatus.SCANNING:
        return Colors.blue;
      case NodeStatus.CONNECTED:
        return Colors.green;
      case NodeStatus.RELAYING:
        return Colors.orange;
    }
  }
}
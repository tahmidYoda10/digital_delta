import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/delivery/models/delivery_model.dart';
import '../../../../core/delivery/models/cargo_item.dart';
import '../../../../core/routing/models/route.dart' as routing;
import '../../../../core/routing/vehicle_constraints.dart';
import '../../../../core/auth/rbac_manager.dart';
import '../../../../core/auth/user_role.dart';
import '../../../../core/auth/permission_guard.dart';
import '../../../auth/data/auth_repository_impl.dart';
import '../../domain/models/triage_decision.dart';
import '../bloc/triage_bloc.dart';
import '../bloc/triage_event.dart';
import '../bloc/triage_state.dart';
import '../widgets/cargo_priority_card.dart';

class TriageDashboardPage extends StatelessWidget {
  const TriageDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => TriageBloc(),
      child: const _TriageDashboardView(),
    );
  }
}

class _TriageDashboardView extends StatefulWidget {
  const _TriageDashboardView();

  @override
  State<_TriageDashboardView> createState() => _TriageDashboardViewState();
}

class _TriageDashboardViewState extends State<_TriageDashboardView> {
  late RBACManager _rbacManager;
  late PermissionGuard _permissionGuard;

  @override
  void initState() {
    super.initState();

    // Get RBAC manager
    final authRepo = RepositoryProvider.of<AuthRepositoryImpl>(context, listen: false);
    _rbacManager = authRepo.rbacManager;
    _permissionGuard = PermissionGuard(_rbacManager);

    // ✅ ROUTE GUARD - Check access
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _permissionGuard.canNavigate(context, 'triage:view');
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 Triage Dashboard'),
        actions: [
          // ✅ ONLY SHOW IF PERMITTED
          if (_rbacManager.hasPermission('triage:execute'))
            IconButton(
              icon: const Icon(Icons.science),
              tooltip: 'Run Simulation',
              onPressed: _runSimulation,
            ),
        ],
      ),
      body: BlocConsumer<TriageBloc, TriageState>(
        listener: (context, state) {
          if (state is TriageDecisionMade) {
            _showDecisionDialog(context, state);
          }
        },
        builder: (context, state) {
          if (state is TriageMonitoring) {
            return Column(
              children: [
                _buildPermissionBanner(),
                Expanded(child: _buildMonitoringView(state)),
              ],
            );
          } else if (state is TriageDecisionMade) {
            return _buildDecisionView(state);
          }

          return _buildInitialView();
        },
      ),
    );
  }

  // ✅ PERMISSION BANNER
  Widget _buildPermissionBanner() {
    if (_rbacManager.hasPermission('triage:execute')) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[100],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[300]!),
      ),
      child: Row(
        children: [
          Icon(Icons.info, color: Colors.orange[700]),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'View-Only Mode',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'You can view triage decisions but cannot trigger them. Contact a Camp Commander.',
                  style: TextStyle(fontSize: 12, color: Colors.orange[800]),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInitialView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.monitor_heart, size: 100, color: Colors.grey[400]),
          const SizedBox(height: 24),
          Text(
            'No Active Deliveries',
            style: TextStyle(fontSize: 20, color: Colors.grey[600]),
          ),
          const SizedBox(height: 16),

          // ✅ Only show if has permission
          if (_rbacManager.hasPermission('triage:execute'))
            ElevatedButton.icon(
              onPressed: _runSimulation,
              icon: const Icon(Icons.play_arrow),
              label: const Text('Run Simulation'),
            ),
        ],
      ),
    );
  }

  Widget _buildMonitoringView(TriageMonitoring state) {
    final status = state.status;
    final cargoList = status['cargo'] as List<dynamic>;
    final eta = DateTime.parse(status['eta'] as String);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildSummaryCard(state),
        const SizedBox(height: 16),
        Text(
          'Cargo Status',
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        ...cargoList.map((cargoData) {
          final cargo = _parseCargoFromStatus(cargoData);
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: CargoPriorityCard(cargo: cargo, eta: eta),
          );
        }),
      ],
    );
  }

  Widget _buildSummaryCard(TriageMonitoring state) {
    final status = state.status;
    final etaMinutes = status['eta_minutes'] as double;

    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.local_shipping, size: 32, color: Colors.blue),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Delivery ${state.deliveryId}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text('Status: ${status['status']}'),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoChip(
                  icon: Icons.access_time,
                  label: 'ETA',
                  value: '${etaMinutes.toStringAsFixed(0)} min',
                ),
                _InfoChip(
                  icon: Icons.priority_high,
                  label: 'Priority',
                  value: _formatPriority(status['highest_priority'] as String),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDecisionView(TriageDecisionMade state) {
    final decision = state.decision;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Card(
          color: Colors.orange[50],
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  _getDecisionIcon(decision.action),
                  size: 64,
                  color: Colors.orange,
                ),
                const SizedBox(height: 16),
                Text(
                  'TRIAGE DECISION',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[900],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  decision.action.toString().split('.').last,
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                Text(
                  decision.reason,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDecisionDialog(BuildContext context, TriageDecisionMade state) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning, color: Colors.orange),
            SizedBox(width: 8),
            Text('Triage Decision'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Action: ${state.decision.action.toString().split('.').last}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(state.decision.reason),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Acknowledge'),
          ),
        ],
      ),
    );
  }

  // ✅ PROTECTED SIMULATION
  void _runSimulation() {
    if (!_permissionGuard.checkAndShowError(
      context,
      'triage:execute',
      customMessage: 'Only Camp Commander can trigger triage\nYour role: ${RolePermissions.getRoleName(_rbacManager.currentRole!)}',
    )) {
      return; // ❌ Blocked
    }

    // ✅ PROCEED WITH SIMULATION
    final demoDelivery = DeliveryModel.create(
      supplyId: 'SUPPLY-SIM-001',
      driverId: 'DRIVER-001',
      cargo: [
        CargoItem(
          id: 'CARGO-P0-001',
          name: 'Antivenom',
          weightKg: 5.0,
          priority: CargoPriority.P0_CRITICAL,
          createdAt: DateTime.now(),
          slaDeadline: DateTime.now().add(const Duration(hours: 2)),
          medicalCategory: 'antivenom',
        ),
        CargoItem(
          id: 'CARGO-P1-001',
          name: 'Surgical Kit',
          weightKg: 10.0,
          priority: CargoPriority.P1_HIGH,
          createdAt: DateTime.now(),
          slaDeadline: DateTime.now().add(const Duration(hours: 6)),
          medicalCategory: 'surgical',
        ),
        CargoItem(
          id: 'CARGO-P2-001',
          name: 'Water Purifier',
          weightKg: 15.0,
          priority: CargoPriority.P2_STANDARD,
          createdAt: DateTime.now(),
          slaDeadline: DateTime.now().add(const Duration(hours: 24)),
        ),
        CargoItem(
          id: 'CARGO-P3-001',
          name: 'Blankets',
          weightKg: 20.0,
          priority: CargoPriority.P3_LOW,
          createdAt: DateTime.now(),
          slaDeadline: DateTime.now().add(const Duration(hours: 72)),
        ),
      ],
      deviceId: 'DEVICE-SIM-001',
    );

    final dummyRoute = routing.Route(
      id: 'ROUTE-SIM-001',
      nodes: [],
      edges: [],
      vehicleConstraints: VehicleConstraints.truck,
      totalDistance: 50.0,
      estimatedTime: 65.0,
      calculatedAt: DateTime.now(),
    );

    context.read<TriageBloc>().add(TriageRegisterDelivery(
      delivery: demoDelivery,
      route: dummyRoute,
    ));

    // Simulate route delay after 3 seconds
    Future.delayed(const Duration(seconds: 3), () {
      final delayedRoute = routing.Route(
        id: 'ROUTE-SIM-002',
        nodes: [],
        edges: [],
        vehicleConstraints: VehicleConstraints.truck,
        totalDistance: 50.0,
        estimatedTime: 180.0,
        calculatedAt: DateTime.now(),
      );

      context.read<TriageBloc>().add(TriageUpdateRoute(
        deliveryId: demoDelivery.id,
        newRoute: delayedRoute,
        oldRoute: dummyRoute,
      ));
    });
  }

  CargoItem _parseCargoFromStatus(dynamic cargoData) {
    final data = cargoData as Map<String, dynamic>;
    final priorityStr = data['priority'] as String;
    final priority = CargoPriority.values.firstWhere(
          (p) => p.toString() == priorityStr,
      orElse: () => CargoPriority.P2_STANDARD,
    );

    return CargoItem(
      id: data['id'],
      name: data['name'],
      weightKg: 0.0,
      priority: priority,
      createdAt: DateTime.now(),
      slaDeadline: DateTime.parse(data['sla_deadline']),
    );
  }

  IconData _getDecisionIcon(TriageAction action) {
    switch (action) {
      case TriageAction.CONTINUE:
        return Icons.check_circle;
      case TriageAction.REROUTE:
        return Icons.directions;
      case TriageAction.PREEMPT:
        return Icons.warning;
      case TriageAction.HANDOFF_DRONE:
        return Icons.flight;
      case TriageAction.ABORT:
        return Icons.cancel;
      default:
        return Icons.help_outline;
    }
  }

  String _formatPriority(String priority) {
    return priority.split('_').last;
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 24, color: Colors.blue),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          value,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
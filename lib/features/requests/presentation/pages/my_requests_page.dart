import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/delivery/models/supply_request.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/request_repository.dart';

class MyRequestsPage extends StatefulWidget {
  const MyRequestsPage({super.key});

  @override
  State<MyRequestsPage> createState() => _MyRequestsPageState();
}

class _MyRequestsPageState extends State<MyRequestsPage> {
  final _requestRepo = RequestRepository();
  List<SupplyRequest> _myRequests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadMyRequests();
  }

  Future<void> _loadMyRequests() async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    setState(() => _loading = true);

    try {
      final requests = await _requestRepo.getMyRequests(authState.user.id);
      if (mounted) {
        setState(() {
          _myRequests = requests;
          _loading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.error('Failed to load my requests', e, stack);
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 My Requests'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadMyRequests,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _myRequests.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox, size: 100, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No requests yet',
                style: TextStyle(fontSize: 20, color: Colors.grey[600])),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/request-supplies')
                    .then((_) => _loadMyRequests());
              },
              icon: const Icon(Icons.add),
              label: const Text('Create Request'),
            ),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadMyRequests,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _myRequests.length,
          itemBuilder: (context, index) {
            return _RequestCard(request: _myRequests[index]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/request-supplies')
              .then((_) => _loadMyRequests());
        },
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
    );
  }
}

class _RequestCard extends StatelessWidget {
  final SupplyRequest request;

  const _RequestCard({required this.request});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  request.medicalReason != null
                      ? Icons.local_hospital
                      : Icons.inventory,
                  color: request.medicalReason != null ? Colors.red : Colors.blue,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.itemName,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                _StatusBadge(status: request.status),
              ],
            ),
            const Divider(height: 24),
            Text('Quantity: ${request.quantity}'),
            Text('Priority: ${request.priority.toString().split('.').last}'),
            Text(
                'Requested: ${_formatDateTime(request.createdAt)}'),
            if (request.approvedAt != null)
              Text(
                  'Approved: ${_formatDateTime(request.approvedAt!)}',
                  style: const TextStyle(color: Colors.green)),
            if (request.rejectedReason != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Rejected: ${request.rejectedReason}',
                    style: TextStyle(color: Colors.red.shade700),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }
}

class _StatusBadge extends StatelessWidget {
  final RequestStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final config = _getStatusConfig();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: config['color'],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        config['label'],
        style: const TextStyle(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusConfig() {
    switch (status) {
      case RequestStatus.PENDING:
        return {'label': 'PENDING', 'color': Colors.orange};
      case RequestStatus.APPROVED:
        return {'label': 'APPROVED', 'color': Colors.green};
      case RequestStatus.IN_PROGRESS:
        return {'label': 'IN PROGRESS', 'color': Colors.blue};
      case RequestStatus.FULFILLED:
        return {'label': 'FULFILLED', 'color': Colors.teal};
      case RequestStatus.REJECTED:
        return {'label': 'REJECTED', 'color': Colors.red};
    }
  }
}
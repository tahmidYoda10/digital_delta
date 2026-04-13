import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/delivery/models/supply_request.dart';
import '../../../../core/auth/permission_guard.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../auth/data/auth_repository_impl.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/request_repository.dart';

class ApproveRequestsPage extends StatefulWidget {
  const ApproveRequestsPage({super.key});

  @override
  State<ApproveRequestsPage> createState() => _ApproveRequestsPageState();
}

class _ApproveRequestsPageState extends State<ApproveRequestsPage> {
  final _requestRepo = RequestRepository();
  List<SupplyRequest> _pendingRequests = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      // Check permission
      final authRepo = RepositoryProvider.of<AuthRepositoryImpl>(context, listen: false);
      final permissionGuard = PermissionGuard(authRepo.rbacManager);

      if (!permissionGuard.canNavigate(context, 'request:approve')) {
        return;
      }

      _loadPendingRequests();
    });
  }

  Future<void> _loadPendingRequests() async {
    setState(() => _loading = true);
    try {
      final requests = await _requestRepo.getPendingRequests();
      if (mounted) {
        setState(() {
          _pendingRequests = requests;
          _loading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.error('Failed to load pending requests', e, stack);
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('✅ Approve Requests'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadPendingRequests,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _pendingRequests.isEmpty
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.check_circle_outline,
                size: 100, color: Colors.grey[400]),
            const SizedBox(height: 16),
            Text('No pending requests',
                style: TextStyle(fontSize: 20, color: Colors.grey[600])),
          ],
        ),
      )
          : RefreshIndicator(
        onRefresh: _loadPendingRequests,
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: _pendingRequests.length,
          itemBuilder: (context, index) {
            return _ApprovalCard(
              request: _pendingRequests[index],
              onApprove: () => _approveRequest(_pendingRequests[index]),
              onReject: () => _rejectRequest(_pendingRequests[index]),
            );
          },
        ),
      ),
    );
  }

  Future<void> _approveRequest(SupplyRequest request) async {
    final authState = context.read<AuthBloc>().state;
    if (authState is! AuthAuthenticated) return;

    try {
      await _requestRepo.approveRequest(request.id, authState.user.id);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Approved: ${request.itemName}'),
          backgroundColor: Colors.green,
        ),
      );

      _loadPendingRequests();
    } catch (e, stack) {
      AppLogger.error('Failed to approve request', e, stack);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to approve: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _rejectRequest(SupplyRequest request) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _RejectDialog(),
    );

    if (reason == null || reason.isEmpty) return;

    try {
      await _requestRepo.rejectRequest(request.id, reason);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Rejected: ${request.itemName}'),
          backgroundColor: Colors.orange,
        ),
      );

      _loadPendingRequests();
    } catch (e, stack) {
      AppLogger.error('Failed to reject request', e, stack);
    }
  }
}

// Approval Card Widget
class _ApprovalCard extends StatelessWidget {
  final SupplyRequest request;
  final VoidCallback onApprove;
  final VoidCallback onReject;

  const _ApprovalCard({
    required this.request,
    required this.onApprove,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
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
                _PriorityBadge(priority: request.priority),
              ],
            ),
            const Divider(height: 24),

            // Details
            _InfoRow(icon: Icons.numbers, label: 'Quantity', value: '${request.quantity}'),
            _InfoRow(
                icon: Icons.person,
                label: 'Requested by',
                value: request.requesterId.substring(0, 8)),
            _InfoRow(
                icon: Icons.access_time,
                label: 'Requested at',
                value: _formatDateTime(request.createdAt)),

            if (request.medicalReason != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red.shade200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.warning, color: Colors.red.shade700, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Medical Emergency',
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(request.medicalReason!),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReject,
                    icon: const Icon(Icons.close, color: Colors.red),
                    label: const Text('Reject', style: TextStyle(color: Colors.red)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: onApprove,
                    icon: const Icon(Icons.check),
                    label: const Text('Approve'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inMinutes < 60) {
      return '${diff.inMinutes} min ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours} hours ago';
    } else {
      return '${diff.inDays} days ago';
    }
  }
}

// Info Row Widget
class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey[600]),
          const SizedBox(width: 8),
          Text('$label: ', style: TextStyle(color: Colors.grey[700])),
          Text(value, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

// Priority Badge
class _PriorityBadge extends StatelessWidget {
  final RequestPriority priority;

  const _PriorityBadge({required this.priority});

  @override
  Widget build(BuildContext context) {
    final config = _getPriorityConfig();
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

  Map<String, dynamic> _getPriorityConfig() {
    switch (priority) {
      case RequestPriority.URGENT:
        return {'label': 'URGENT', 'color': Colors.red};
      case RequestPriority.HIGH:
        return {'label': 'HIGH', 'color': Colors.orange};
      case RequestPriority.MEDIUM:
        return {'label': 'MEDIUM', 'color': Colors.blue};
      case RequestPriority.LOW:
        return {'label': 'LOW', 'color': Colors.green};
    }
  }
}

// Reject Dialog
class _RejectDialog extends StatelessWidget {
  final _controller = TextEditingController();

  _RejectDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Reject Request'),
      content: TextField(
        controller: _controller,
        decoration: const InputDecoration(
          labelText: 'Reason for rejection',
          hintText: 'e.g., Insufficient stock',
          border: OutlineInputBorder(),
        ),
        maxLines: 3,
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, _controller.text),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Reject'),
        ),
      ],
    );
  }
}
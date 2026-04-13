import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/delivery/models/supply_request.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../data/request_repository.dart';

class AllRequestsPage extends StatefulWidget {
  const AllRequestsPage({super.key});

  @override
  State<AllRequestsPage> createState() => _AllRequestsPageState();
}

class _AllRequestsPageState extends State<AllRequestsPage> {
  final _requestRepo = RequestRepository();
  List<SupplyRequest> _allRequests = [];
  bool _loading = true;
  String _selectedFilter = 'ALL';

  @override
  void initState() {
    super.initState();
    _loadAllRequests();
  }

  Future<void> _loadAllRequests() async {
    setState(() => _loading = true);

    try {
      final requests = await _requestRepo.getAllRequests(); // ✅ FIXED
      if (mounted) {
        setState(() {
          _allRequests = requests;
          _loading = false;
        });
      }
    } catch (e, stack) {
      AppLogger.error('Failed to load requests', e, stack);
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  List<SupplyRequest> get _filteredRequests {
    if (_selectedFilter == 'ALL') {
      return _allRequests;
    }

    final status = RequestStatus.values.firstWhere(
          (s) => s.toString().split('.').last == _selectedFilter,
      orElse: () => RequestStatus.PENDING,
    );

    return _allRequests.where((r) => r.status == status).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('📋 All Requests'),
        backgroundColor: Colors.green.shade700,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAllRequests,
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter chips
          Container(
            padding: const EdgeInsets.all(8),
            color: Colors.grey.shade100,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterChip(
                    label: 'ALL (${_allRequests.length})',
                    value: 'ALL',
                    selectedValue: _selectedFilter,
                    onSelected: (value) => setState(() => _selectedFilter = value),
                  ),
                  _FilterChip(
                    label: 'PENDING',
                    value: 'PENDING',
                    selectedValue: _selectedFilter,
                    color: Colors.orange,
                    onSelected: (value) => setState(() => _selectedFilter = value),
                  ),
                  _FilterChip(
                    label: 'APPROVED',
                    value: 'APPROVED',
                    selectedValue: _selectedFilter,
                    color: Colors.green,
                    onSelected: (value) => setState(() => _selectedFilter = value),
                  ),
                  _FilterChip(
                    label: 'IN_PROGRESS',
                    value: 'IN_PROGRESS',
                    selectedValue: _selectedFilter,
                    color: Colors.blue,
                    onSelected: (value) => setState(() => _selectedFilter = value),
                  ),
                  _FilterChip(
                    label: 'FULFILLED',
                    value: 'FULFILLED',
                    selectedValue: _selectedFilter,
                    color: Colors.teal,
                    onSelected: (value) => setState(() => _selectedFilter = value),
                  ),
                  _FilterChip(
                    label: 'REJECTED',
                    value: 'REJECTED',
                    selectedValue: _selectedFilter,
                    color: Colors.red,
                    onSelected: (value) => setState(() => _selectedFilter = value),
                  ),
                ],
              ),
            ),
          ),

          // Requests list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _filteredRequests.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 100, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No ${_selectedFilter.toLowerCase()} requests',
                    style: TextStyle(fontSize: 20, color: Colors.grey[600]),
                  ),
                ],
              ),
            )
                : RefreshIndicator(
              onRefresh: _loadAllRequests,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _filteredRequests.length,
                itemBuilder: (context, index) {
                  return _RequestCard(
                    request: _filteredRequests[index],
                    onTap: () => _showRequestDetails(
                      context,
                      _filteredRequests[index],
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showRequestDetails(BuildContext context, SupplyRequest request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.5,
        maxChildSize: 0.95,
        expand: false,
        builder: (context, scrollController) => SingleChildScrollView(
          controller: scrollController,
          padding: const EdgeInsets.all(24),
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
                    color: request.medicalReason != null
                        ? Colors.red
                        : Colors.blue,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          request.itemName,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'ID: ${request.id.substring(0, 8)}...',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _StatusBadge(status: request.status),
                ],
              ),
              const Divider(height: 32),

              // Details
              _DetailRow(
                icon: Icons.numbers,
                label: 'Quantity',
                value: request.quantity.toString(),
              ),
              _DetailRow(
                icon: Icons.priority_high,
                label: 'Priority',
                value: request.priority.toString().split('.').last,
                valueColor: _getPriorityColor(request.priority),
              ),
              _DetailRow(
                icon: Icons.person,
                label: 'Requester ID',
                value: request.requesterId.substring(0, 8),
              ),
              _DetailRow(
                icon: Icons.location_on,
                label: 'Camp ID',
                value: request.campId,
              ),
              _DetailRow(
                icon: Icons.access_time,
                label: 'Created At',
                value: _formatDateTime(request.createdAt),
              ),

              if (request.approvedAt != null) ...[
                _DetailRow(
                  icon: Icons.check_circle,
                  label: 'Approved At',
                  value: _formatDateTime(request.approvedAt!),
                  valueColor: Colors.green,
                ),
                _DetailRow(
                  icon: Icons.person_outline,
                  label: 'Approved By',
                  value: request.approvedBy?.substring(0, 8) ?? 'N/A',
                ),
              ],

              if (request.medicalReason != null) ...[
                const SizedBox(height: 16),
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
                          Icon(Icons.warning, color: Colors.red.shade700),
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

              if (request.rejectedReason != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.info, color: Colors.orange.shade700),
                          const SizedBox(width: 8),
                          Text(
                            'Rejection Reason',
                            style: TextStyle(
                              color: Colors.orange.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(request.rejectedReason!),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Close button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Close'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    return '${dateTime.day}/${dateTime.month}/${dateTime.year} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}';
  }

  Color _getPriorityColor(RequestPriority priority) {
    switch (priority) {
      case RequestPriority.URGENT:
        return Colors.red;
      case RequestPriority.HIGH:
        return Colors.orange;
      case RequestPriority.MEDIUM:
        return Colors.blue;
      case RequestPriority.LOW:
        return Colors.green;
    }
  }
}

// Filter chip widget
class _FilterChip extends StatelessWidget {
  final String label;
  final String value;
  final String selectedValue;
  final Color? color;
  final ValueChanged<String> onSelected;

  const _FilterChip({
    required this.label,
    required this.value,
    required this.selectedValue,
    this.color,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selectedValue == value;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(value),
        backgroundColor: Colors.white,
        selectedColor: (color ?? Colors.blue).withOpacity(0.2),
        checkmarkColor: color ?? Colors.blue,
        labelStyle: TextStyle(
          color: isSelected ? (color ?? Colors.blue) : Colors.black87,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}

// Request card widget
class _RequestCard extends StatelessWidget {
  final SupplyRequest request;
  final VoidCallback onTap;

  const _RequestCard({
    required this.request,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
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
                    color: request.medicalReason != null
                        ? Colors.red
                        : Colors.blue,
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
              const SizedBox(height: 8),
              Text('Quantity: ${request.quantity}'),
              Text('Priority: ${request.priority.toString().split('.').last}'),
              Text(
                'Requested: ${_formatDateTime(request.createdAt)}',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
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

// Status badge widget
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

// Detail row widget
class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? Colors.black87,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
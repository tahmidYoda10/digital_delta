import 'package:flutter/material.dart';
import '../../../../core/delivery/models/cargo_item.dart';

class CargoPriorityCard extends StatelessWidget {
  final CargoItem cargo;
  final DateTime eta;

  const CargoPriorityCard({
    super.key,
    required this.cargo,
    required this.eta,
  });

  @override
  Widget build(BuildContext context) {
    final willBreach = eta.isAfter(cargo.slaDeadline);
    final remaining = cargo.getRemainingTime();
    final atRisk = cargo.isSLAAtRisk();

    return Card(
      color: willBreach
          ? Colors.red[50]
          : atRisk
          ? Colors.orange[50]
          : Colors.green[50],
      child: ListTile(
        leading: Icon(
          _getPriorityIcon(cargo.priority),
          color: _getPriorityColor(cargo.priority),
          size: 32,
        ),
        title: Text(
          cargo.name,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Priority: ${_getPriorityLabel(cargo.priority)}'),
            Text('SLA: ${remaining.inMinutes} min remaining'),
            if (cargo.medicalCategory != null)
              Text('Category: ${cargo.medicalCategory}'),
          ],
        ),
        trailing: willBreach
            ? const Chip(
          label: Text('BREACH!'),
          backgroundColor: Colors.red,
          labelStyle: TextStyle(color: Colors.white),
        )
            : atRisk
            ? const Chip(
          label: Text('AT RISK'),
          backgroundColor: Colors.orange,
        )
            : const Chip(
          label: Text('OK'),
          backgroundColor: Colors.green,
          labelStyle: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  IconData _getPriorityIcon(CargoPriority priority) {
    switch (priority) {
      case CargoPriority.P0_CRITICAL:
        return Icons.local_hospital;
      case CargoPriority.P1_HIGH:
        return Icons.medical_services;
      case CargoPriority.P2_STANDARD:
        return Icons.inventory;
      case CargoPriority.P3_LOW:
        return Icons.checkroom;
      default:
        return Icons.help_outline;
    }
  }

  Color _getPriorityColor(CargoPriority priority) {
    switch (priority) {
      case CargoPriority.P0_CRITICAL:
        return Colors.red;
      case CargoPriority.P1_HIGH:
        return Colors.orange;
      case CargoPriority.P2_STANDARD:
        return Colors.blue;
      case CargoPriority.P3_LOW:
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getPriorityLabel(CargoPriority priority) {
    switch (priority) {
      case CargoPriority.P0_CRITICAL:
        return 'P0 - Critical (2h)';
      case CargoPriority.P1_HIGH:
        return 'P1 - High (6h)';
      case CargoPriority.P2_STANDARD:
        return 'P2 - Standard (24h)';
      case CargoPriority.P3_LOW:
        return 'P3 - Low (72h)';
      default:
        return 'Unknown';
    }
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/delivery/models/supply_request.dart';
import '../../../../core/auth/rbac_manager.dart';
import '../../../../core/crypto/key_manager.dart';
import '../../../auth/data/auth_repository_impl.dart';
import '../../data/request_repository.dart';

class RequestSuppliesPage extends StatefulWidget {
  const RequestSuppliesPage({super.key});

  @override
  State<RequestSuppliesPage> createState() => _RequestSuppliesPageState();
}

class _RequestSuppliesPageState extends State<RequestSuppliesPage> {
  final _formKey = GlobalKey<FormState>();
  final _itemController = TextEditingController();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  final _requestRepo = RequestRepository();

  RequestPriority _selectedPriority = RequestPriority.MEDIUM;
  bool _isMedical = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🆘 Request Supplies'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(Icons.info, color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Submit your supply request. A Camp Commander will review and approve it.',
                        style: TextStyle(color: Colors.blue[900]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _itemController,
              decoration: const InputDecoration(
                labelText: 'Item Name',
                hintText: 'e.g., Water, Food, Medicine',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.inventory),
              ),
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Please enter item name';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(
                labelText: 'Quantity',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.numbers),
              ),
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || int.tryParse(value) == null) {
                  return 'Please enter valid quantity';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            DropdownButtonFormField<RequestPriority>(
              value: _selectedPriority,
              decoration: const InputDecoration(
                labelText: 'Priority',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.priority_high),
              ),
              items: RequestPriority.values.map((priority) {
                return DropdownMenuItem(
                  value: priority,
                  child: Text(_getPriorityLabel(priority)),
                );
              }).toList(),
              onChanged: (value) {
                if (value != null) {
                  setState(() => _selectedPriority = value);
                }
              },
            ),
            const SizedBox(height: 16),

            CheckboxListTile(
              value: _isMedical,
              onChanged: (value) {
                setState(() => _isMedical = value ?? false);
              },
              title: const Text('This is a medical emergency'),
              subtitle: const Text('Will be prioritized immediately'),
              secondary: const Icon(Icons.local_hospital, color: Colors.red),
            ),

            if (_isMedical) ...[
              const SizedBox(height: 16),
              TextFormField(
                controller: _reasonController,
                decoration: const InputDecoration(
                  labelText: 'Medical Reason',
                  hintText: 'Describe the emergency',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.medical_information),
                ),
                maxLines: 3,
                validator: (value) {
                  if (_isMedical && (value == null || value.isEmpty)) {
                    return 'Please describe the medical emergency';
                  }
                  return null;
                },
              ),
            ],

            const SizedBox(height: 24),

            ElevatedButton.icon(
              onPressed: _submitRequest,
              icon: const Icon(Icons.send),
              label: const Text('SUBMIT REQUEST'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: _isMedical ? Colors.red : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final authRepo = RepositoryProvider.of<AuthRepositoryImpl>(context, listen: false);
    final currentUser = authRepo.rbacManager.currentUser;
    final keyManager = RepositoryProvider.of<KeyManager>(context, listen: false);

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('⛔ You must be logged in'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final request = SupplyRequest.create(
      requesterId: currentUser.id,
      campId: 'CAMP-SYLHET-01', // TODO: Get from user location
      itemName: _itemController.text.trim(),
      quantity: int.parse(_quantityController.text.trim()),
      priority: _isMedical ? RequestPriority.URGENT : _selectedPriority,
      deviceId: keyManager.deviceId,
      medicalReason: _isMedical ? _reasonController.text.trim() : null,
    );

    try {
      await _requestRepo.createRequest(request);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Request submitted! Awaiting approval.'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Failed to submit request: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _getPriorityLabel(RequestPriority priority) {
    switch (priority) {
      case RequestPriority.URGENT:
        return '🔴 Urgent';
      case RequestPriority.HIGH:
        return '🟠 High';
      case RequestPriority.MEDIUM:
        return '🟡 Medium';
      case RequestPriority.LOW:
        return '🟢 Low';
    }
  }
}
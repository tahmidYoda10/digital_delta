import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/delivery/models/supply_request.dart';
import '../../../../core/auth/user_role.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../requests/data/request_repository.dart';

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

  RequestPriority _selectedPriority = RequestPriority.MEDIUM;
  bool _isMedical = false;
  bool _isSubmitting = false;

  @override
  void dispose() {
    _itemController.dispose();
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🆘 Request Supplies'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, authState) {
          if (authState is! AuthAuthenticated) {
            return const Center(
              child: Text('Please login to submit requests'),
            );
          }

          return Form(
            key: _formKey,
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Info card
                Card(
                  color: Colors.blue.shade50,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue.shade700),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Submit your supply request. A Camp Commander will review and approve it.',
                            style: TextStyle(color: Colors.blue.shade900),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Item name
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

                // Quantity
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

                // Priority
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

                // Medical checkbox
                CheckboxListTile(
                  value: _isMedical,
                  onChanged: (value) {
                    setState(() => _isMedical = value ?? false);
                  },
                  title: const Text('This is a medical emergency'),
                  subtitle: const Text('Will be prioritized immediately'),
                  secondary: const Icon(Icons.local_hospital, color: Colors.red),
                ),

                // Medical reason (if checked)
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

                // Submit button
                ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : () => _submitRequest(authState.user),
                  icon: _isSubmitting
                      ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                      : const Icon(Icons.send),
                  label: Text(_isSubmitting ? 'SUBMITTING...' : 'SUBMIT REQUEST'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                    backgroundColor: _isMedical ? Colors.red : Colors.blue,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _submitRequest(dynamic user) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    try {
      final requestRepo = RequestRepository();

      final request = SupplyRequest.create(
        requesterId: user.id,
        campId: 'default-camp', // TODO: Get from user location
        itemName: _itemController.text.trim(),
        quantity: int.parse(_quantityController.text),
        priority: _isMedical ? RequestPriority.URGENT : _selectedPriority,
        deviceId: user.deviceId,
        medicalReason: _isMedical ? _reasonController.text.trim() : null,
      );

      await requestRepo.createRequest(request);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Text('✅ Request submitted! Awaiting approval.'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.pop(context);
    } catch (e, stack) {
      AppLogger.error('Failed to submit request', e, stack);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed to submit request: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
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
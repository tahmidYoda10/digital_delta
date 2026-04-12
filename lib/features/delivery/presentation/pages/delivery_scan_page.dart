import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../bloc/delivery_bloc.dart';
import '../bloc/delivery_event.dart';
import '../bloc/delivery_state.dart';
import '../../../../core/delivery/models/delivery_model.dart';
import '../../../../core/delivery/models/cargo_item.dart';
import '../../../../core/delivery/pod_verifier.dart';

class DeliveryScanPage extends StatefulWidget {
  const DeliveryScanPage({super.key});

  @override
  State<DeliveryScanPage> createState() => _DeliveryScanPageState();
}

class _DeliveryScanPageState extends State<DeliveryScanPage> {
  MobileScannerController cameraController = MobileScannerController();
  bool isScanning = false;

  @override
  void dispose() {
    cameraController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Proof of Delivery'),
        actions: [
          IconButton(
            icon: Icon(isScanning ? Icons.flash_off : Icons.flash_on),
            onPressed: () => cameraController.toggleTorch(),
          ),
        ],
      ),
      body: BlocConsumer<DeliveryBloc, DeliveryState>(
        listener: (context, state) {
          if (state is DeliveryPoDGenerated) {
            _showQRDialog(context, state.qrPayload);
          } else if (state is DeliveryPoDVerified) {
            _showVerificationResult(context, state.result);
          }
        },
        builder: (context, state) {
          if (state is DeliveryLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Demo: Generate PoD button
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: ElevatedButton.icon(
                  onPressed: () => _generateDemoPoD(context),
                  icon: const Icon(Icons.qr_code),
                  label: const Text('Generate Demo PoD'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                ),
              ),

              const Divider(),

              // QR Scanner
              Expanded(
                child: isScanning
                    ? Stack(
                  children: [
                    MobileScanner(
                      controller: cameraController,
                      onDetect: (capture) {
                        final List<Barcode> barcodes = capture.barcodes;
                        for (final barcode in barcodes) {
                          if (barcode.rawValue != null) {
                            _handleQRCode(barcode.rawValue!);
                            setState(() => isScanning = false);
                            break;
                          }
                        }
                      },
                    ),
                    // Overlay with scanning guide
                    Center(
                      child: Container(
                        width: 250,
                        height: 250,
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.green, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    // Close button
                    Positioned(
                      top: 16,
                      right: 16,
                      child: FloatingActionButton(
                        mini: true,
                        backgroundColor: Colors.red,
                        onPressed: () {
                          setState(() => isScanning = false);
                        },
                        child: const Icon(Icons.close),
                      ),
                    ),
                  ],
                )
                    : Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.qr_code_scanner, size: 100, color: Colors.grey),
                      const SizedBox(height: 24),
                      Text(
                        'Scan QR Code for Verification',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          setState(() => isScanning = true);
                        },
                        icon: const Icon(Icons.qr_code_scanner),
                        label: const Text('Start Scanning'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.all(16),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleQRCode(String qrData) {
    context.read<DeliveryBloc>().add(
      DeliveryVerifyPoDRequested(qrData),
    );
  }

  void _generateDemoPoD(BuildContext context) {
    // Create demo delivery
    final demoDelivery = DeliveryModel.create(
      supplyId: 'SUPPLY-001',
      driverId: 'DRIVER-001',
      cargo: [
        CargoItem(
          id: 'CARGO-001',
          name: 'Medical Supplies',
          weightKg: 50.0,
          priority: CargoPriority.P0_CRITICAL,
          createdAt: DateTime.now(),
          slaDeadline: DateTime.now().add(const Duration(hours: 2)),
          medicalCategory: 'antivenom',
        ),
      ],
      deviceId: 'DEVICE-001',
    );

    context.read<DeliveryBloc>().add(
      DeliveryGeneratePoDRequested(
        delivery: demoDelivery,
        recipientPublicKey: 'DEMO_RECIPIENT_KEY',
      ),
    );
  }

  void _showQRDialog(BuildContext context, String qrPayload) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('PoD QR Code Generated'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 300,
              height: 300,
              child: QrImageView(
                data: qrPayload,
                version: QrVersions.auto,
                size: 280,
                backgroundColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Scan this QR code to verify delivery',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              // Show scanning view
              setState(() => isScanning = true);
            },
            child: const Text('Scan Now'),
          ),
        ],
      ),
    );
  }

  void _showVerificationResult(BuildContext context, VerificationResult result) {
    final isValid = result == VerificationResult.VALID;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            Icon(
              isValid ? Icons.check_circle : Icons.error,
              color: isValid ? Colors.green : Colors.red,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                isValid ? 'PoD Verified' : 'Verification Failed',
                style: TextStyle(
                  color: isValid ? Colors.green : Colors.red,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _getResultMessage(result),
              style: const TextStyle(fontSize: 16),
            ),
            if (isValid) ...[
              const SizedBox(height: 16),
              const Divider(),
              const Text(
                'Delivery Details:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Delivery ID: DELIVERY-001'),
              const Text('• Driver: DRIVER-001'),
              const Text('• Status: Ready for handoff'),
            ],
          ],
        ),
        actions: [
          if (isValid)
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                // Trigger counter-signature
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✅ Delivery counter-signed successfully!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              icon: const Icon(Icons.done),
              label: const Text('Counter-Sign & Accept'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
              ),
            ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(isValid ? 'Cancel' : 'Close'),
          ),
        ],
      ),
    );
  }

  String _getResultMessage(VerificationResult result) {
    switch (result) {
      case VerificationResult.VALID:
        return 'Delivery verified successfully. Ready for counter-signature.';
      case VerificationResult.INVALID_SIGNATURE:
        return 'Invalid signature detected. The QR code may be corrupted.';
      case VerificationResult.REPLAY_ATTACK:
        return '⚠️ Security Alert: This QR code was already used. Possible replay attack!';
      case VerificationResult.TAMPERED:
        return '⚠️ Security Alert: Payload has been tampered with. Do not accept!';
      case VerificationResult.EXPIRED:
        return 'PoD has expired (older than 24 hours). Request new QR code.';
    }
  }
}
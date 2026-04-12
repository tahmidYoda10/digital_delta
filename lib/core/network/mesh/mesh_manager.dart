import 'dart:async';
import 'dart:convert';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../constants/app_constants.dart';
import '../../utils/app_logger.dart';
import '../../crypto/key_manager.dart';
import '../../crypto/encryption_service.dart';
import 'mesh_message.dart';
import 'mesh_node.dart';
import 'message_store.dart';

class MeshManager {
  final KeyManager _keyManager;
  final MessageStore _messageStore = MessageStore();
  final Map<String, MeshNode> _discoveredNodes = {};

  BluetoothCharacteristic? _txCharacteristic;
  BluetoothCharacteristic? _rxCharacteristic;

  StreamSubscription? _scanSubscription;
  StreamSubscription? _characteristicSubscription;

  Timer? _relayTimer;
  Timer? _heartbeatTimer;

  bool _isInitialized = false;
  MeshNode? _localNode;

  final StreamController<MeshMessage> _messageController = StreamController.broadcast();
  final StreamController<List<MeshNode>> _nodesController = StreamController.broadcast();

  Stream<MeshMessage> get messageStream => _messageController.stream;
  Stream<List<MeshNode>> get nodesStream => _nodesController.stream;

  MeshManager({required KeyManager keyManager}) : _keyManager = keyManager;

  /// Initialize mesh network
  Future<void> initialize() async {
    if (_isInitialized) {
      AppLogger.warning('Mesh already initialized');
      return;
    }

    try {
      AppLogger.info('🔷 Initializing Bluetooth mesh network...');

      // Check Bluetooth support
      if (!await FlutterBluePlus.isAvailable) {
        throw Exception('Bluetooth not available on this device');
      }

      // Request permissions
      await _requestPermissions();

      // Create local node
      _localNode = MeshNode(
        deviceId: _keyManager.deviceId,
        deviceName: 'DD-${_keyManager.deviceId.substring(0, 6)}',
        discoveredAt: DateTime.now(),
        lastSeenAt: DateTime.now(),
        role: NodeRole.HYBRID,
        status: NodeStatus.OFFLINE,
      );

      // Start periodic tasks
      _startRelayTimer();
      _startHeartbeatTimer();

      _isInitialized = true;
      AppLogger.info('✅ Mesh network initialized');

    } catch (e, stack) {
      AppLogger.error('Failed to initialize mesh', e, stack);
      rethrow;
    }
  }

  /// Request Bluetooth permissions
  Future<void> _requestPermissions() async {
    final permissions = [
      Permission.bluetooth,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
      Permission.locationWhenInUse,
    ];

    for (var permission in permissions) {
      final status = await permission.request();
      if (!status.isGranted) {
        AppLogger.warning('Permission denied: $permission');
      }
    }
  }

  /// Start scanning for nearby devices
  Future<void> startScanning() async {
    if (!_isInitialized) {
      throw Exception('Mesh not initialized');
    }

    try {
      AppLogger.info('🔍 Starting Bluetooth scan...');

      _localNode?.status = NodeStatus.SCANNING;

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 15),
        androidUsesFineLocation: true,
      );

      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        for (var result in results) {
          _handleDiscoveredDevice(result);
        }
      });

    } catch (e, stack) {
      AppLogger.error('Scan failed', e, stack);
    }
  }

  /// Handle discovered device
  void _handleDiscoveredDevice(ScanResult result) {
    final device = result.device;
    final deviceId = device.remoteId.toString();

    // Filter only Digital Delta devices
    if (!device.platformName.startsWith('DD-')) {
      return;
    }

    if (!_discoveredNodes.containsKey(deviceId)) {
      final node = MeshNode(
        deviceId: deviceId,
        deviceName: device.platformName,
        bluetoothDevice: device,
        discoveredAt: DateTime.now(),
        lastSeenAt: DateTime.now(),
        signalStrength: result.rssi,
      );

      _discoveredNodes[deviceId] = node;
      AppLogger.info('📡 Discovered node: ${node.deviceName} (RSSI: ${result.rssi})');
    } else {
      // Update existing node
      _discoveredNodes[deviceId]!.signalStrength = result.rssi;
      _discoveredNodes[deviceId]!.updateLastSeen();
    }

    _notifyNodesUpdate();
  }

  /// Connect to a peer device
  Future<void> connectToPeer(String deviceId) async {
    final node = _discoveredNodes[deviceId];
    if (node == null || node.bluetoothDevice == null) {
      AppLogger.warning('Node not found: $deviceId');
      return;
    }

    try {
      AppLogger.info('🔗 Connecting to ${node.deviceName}...');

      await node.bluetoothDevice!.connect(
        timeout: const Duration(seconds: 15),
        autoConnect: false,
      );

      // Discover services
      final services = await node.bluetoothDevice!.discoverServices();

      for (var service in services) {
        if (service.uuid.toString() == AppConstants.meshServiceUUID) {
          for (var characteristic in service.characteristics) {
            if (characteristic.uuid.toString() == AppConstants.meshCharUUID) {
              _rxCharacteristic = characteristic;

              // Subscribe to notifications
              await characteristic.setNotifyValue(true);
              _characteristicSubscription = characteristic.value.listen((value) {
                _handleReceivedData(value);
              });

              _txCharacteristic = characteristic;
            }
          }
        }
      }

      node.status = NodeStatus.CONNECTED;
      AppLogger.info('✅ Connected to ${node.deviceName}');

    } catch (e, stack) {
      AppLogger.error('Connection failed', e, stack);
      node.status = NodeStatus.OFFLINE;
    }
  }

  /// Send message through mesh (M3.1 Store-and-Forward)
  Future<bool> sendMessage(MeshMessage message) async {
    try {
      // Add to pending queue
      if (!_messageStore.addPending(message)) {
        return false;
      }

      // Try immediate delivery if connected
      if (_txCharacteristic != null) {
        await _transmitMessage(message);
        return true;
      }

      // Otherwise, will be relayed later
      AppLogger.info('📤 Message queued for relay: ${message.id}');
      return true;

    } catch (e, stack) {
      AppLogger.error('Failed to send message', e, stack);
      _messageStore.markAsFailed(message);
      return false;
    }
  }

  /// Transmit message via Bluetooth
  Future<void> _transmitMessage(MeshMessage message) async {
    if (_txCharacteristic == null) {
      throw Exception('No TX characteristic available');
    }

    try {
      final bytes = message.toBytes();

      // Split into chunks if needed (BLE MTU limit ~512 bytes)
      const chunkSize = 512;
      for (var i = 0; i < bytes.length; i += chunkSize) {
        final end = (i + chunkSize < bytes.length) ? i + chunkSize : bytes.length;
        final chunk = bytes.sublist(i, end);

        await _txCharacteristic!.write(chunk, withoutResponse: false);
      }

      AppLogger.debug('📡 Transmitted: ${message.id}');

    } catch (e, stack) {
      AppLogger.error('Transmission failed', e, stack);
      rethrow;
    }
  }

  /// Handle received data
  void _handleReceivedData(List<int> data) {
    try {
      final message = MeshMessage.fromBytes(data);

      AppLogger.info('📥 Received: ${message.type} from ${message.senderId}');

      // Check if for this device
      if (message.recipientId == null || message.recipientId == _keyManager.deviceId) {
        _messageController.add(message);
      }

      // Relay if needed (M3.1)
      if (message.canRelay() &&
          !message.hasVisited(_keyManager.deviceId) &&
          _localNode?.role != NodeRole.CLIENT) {
        _relayMessage(message);
      }

    } catch (e, stack) {
      AppLogger.error('Failed to parse received data', e, stack);
    }
  }

  /// Relay message to other nodes (M3.2)
  Future<void> _relayMessage(MeshMessage message) async {
    try {
      final relayedMessage = message.relay(_keyManager.deviceId);

      _messageStore.addPending(relayedMessage);
      _localNode?.relayedMessageCount++;
      _localNode?.status = NodeStatus.RELAYING;

      AppLogger.debug('🔄 Relaying message: ${message.id} (TTL: ${relayedMessage.ttl})');

    } catch (e) {
      AppLogger.error('Relay failed', e);
    }
  }

  /// Periodic relay timer
  void _startRelayTimer() {
    _relayTimer = Timer.periodic(
      Duration(milliseconds: AppConstants.meshBroadcastIntervalMs),
          (timer) async {
        final message = _messageStore.getNextPending();
        if (message != null && _txCharacteristic != null) {
          await _transmitMessage(message);
        }
      },
    );
  }

  /// Periodic heartbeat
  void _startHeartbeatTimer() {
    _heartbeatTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      final heartbeat = MeshMessage.create(
        type: MessageType.HEARTBEAT,
        senderId: _keyManager.deviceId,
        payload: {
          'battery': _localNode?.batteryLevel ?? 100,
          'role': _localNode?.role.toString(),
        },
      );
      sendMessage(heartbeat);
    });
  }

  /// Notify nodes update
  void _notifyNodesUpdate() {
    _nodesController.add(_discoveredNodes.values.toList());
  }

  /// Get mesh statistics
  Map<String, dynamic> getStats() {
    return {
      'localNode': _localNode?.toJson(),
      'discoveredNodes': _discoveredNodes.length,
      'messageStore': _messageStore.getStats(),
      'isConnected': _txCharacteristic != null,
    };
  }

  /// Dispose
  void dispose() {
    _scanSubscription?.cancel();
    _characteristicSubscription?.cancel();
    _relayTimer?.cancel();
    _heartbeatTimer?.cancel();
    _messageController.close();
    _nodesController.close();
    FlutterBluePlus.stopScan();
  }
}
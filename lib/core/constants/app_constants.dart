class AppConstants {
  // App Info
  static const String appName = 'Digital Delta';
  static const String appVersion = '1.0.0';

  // Database
  static const String dbName = 'digital_delta.db';
  static const int dbVersion = 1;
  static const int maxRamUsageMB = 150; // Constraint C3

  // Mesh Network
  static const String meshServiceUUID = '0000181C-0000-1000-8000-00805F9B34FB';
  static const String meshCharUUID = '00002A3D-0000-1000-8000-00805F9B34FB';
  static const int meshMessageTTL = 10; // hops
  static const int meshBroadcastIntervalMs = 5000;

  // Routing
  static const int routeRecalcThresholdMs = 2000; // M4.2 requirement
  static const double riskThresholdForReroute = 0.7; // M7.3

  // Triage
  static const Map<String, int> prioritySLA = {
    'P0': 2 * 60, // 2 hours in minutes
    'P1': 6 * 60,
    'P2': 24 * 60,
    'P3': 72 * 60,
  };

  // Crypto
  static const int rsaKeySize = 2048;
  static const String aesMode = 'AES-256-GCM';

  // ML
  static const String mlModelPath = 'assets/models/route_decay.onnx';
  static const double mlInferenceThreshold = 0.7;
}
import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../utils/app_logger.dart';

class KeyManager {
  static const String _privateKeyKey = 'rsa_private_key';
  static const String _publicKeyKey = 'rsa_public_key';
  static const String _deviceIdKey = 'device_id';

  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>? _keyPair;
  String? _deviceId;

  /// Initialize or load existing key pair (M1.2)
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    // Load or generate device ID
    _deviceId = prefs.getString(_deviceIdKey);
    if (_deviceId == null) {
      _deviceId = _generateDeviceId();
      await prefs.setString(_deviceIdKey, _deviceId!);
      AppLogger.info('📱 Generated new device ID: $_deviceId');
    }

    // Check if keys already exist
    String? privateKeyPem = prefs.getString(_privateKeyKey);
    String? publicKeyPem = prefs.getString(_publicKeyKey);

    if (privateKeyPem != null && publicKeyPem != null) {
      AppLogger.info('🔑 Loading existing RSA key pair');
      _keyPair = _loadKeyPairFromPem(privateKeyPem, publicKeyPem);
    } else {
      AppLogger.info('🔑 Generating new RSA-2048 key pair...');
      _keyPair = await _generateRSAKeyPair();

      // Store keys
      await prefs.setString(_privateKeyKey, _encodePrivateKeyToPem(_keyPair!.privateKey));
      await prefs.setString(_publicKeyKey, _encodePublicKeyToPem(_keyPair!.publicKey));

      AppLogger.info('✅ RSA key pair generated and stored');
    }
  }

  /// Generate RSA-2048 key pair
  Future<AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>> _generateRSAKeyPair() async {
    final secureRandom = _getSecureRandom();

    final keyGen = RSAKeyGenerator()
      ..init(ParametersWithRandom(
        RSAKeyGeneratorParameters(BigInt.parse('65537'), 2048, 64),
        secureRandom,
      ));

    final pair = keyGen.generateKeyPair();
    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(
      pair.publicKey as RSAPublicKey,
      pair.privateKey as RSAPrivateKey,
    );
  }

  /// Secure random generator
  SecureRandom _getSecureRandom() {
    final secureRandom = FortunaRandom();
    final random = Random.secure();
    final seeds = List<int>.generate(32, (_) => random.nextInt(256));
    secureRandom.seed(KeyParameter(Uint8List.fromList(seeds)));
    return secureRandom;
  }

  String _generateDeviceId() {
    final random = Random.secure();
    final values = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(values).substring(0, 22);
  }

  String get deviceId => _deviceId ?? 'unknown';
  String get publicKeyPem => _encodePublicKeyToPem(_keyPair!.publicKey);
  RSAPrivateKey get privateKey => _keyPair!.privateKey;
  RSAPublicKey get publicKey => _keyPair!.publicKey;

  // PEM encoding/decoding helpers
  String _encodePublicKeyToPem(RSAPublicKey publicKey) {
    final modulus = publicKey.modulus!.toRadixString(16);
    final exponent = publicKey.exponent!.toRadixString(16);
    return jsonEncode({'modulus': modulus, 'exponent': exponent});
  }

  String _encodePrivateKeyToPem(RSAPrivateKey privateKey) {
    final modulus = privateKey.modulus!.toRadixString(16);
    final exponent = privateKey.exponent!.toRadixString(16);
    final p = privateKey.p!.toRadixString(16);
    final q = privateKey.q!.toRadixString(16);
    return jsonEncode({'modulus': modulus, 'exponent': exponent, 'p': p, 'q': q});
  }

  AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey> _loadKeyPairFromPem(
      String privatePem,
      String publicPem,
      ) {
    final privateData = jsonDecode(privatePem);
    final publicData = jsonDecode(publicPem);

    final privateKey = RSAPrivateKey(
      BigInt.parse(privateData['modulus'], radix: 16),
      BigInt.parse(privateData['exponent'], radix: 16),
      BigInt.parse(privateData['p'], radix: 16),
      BigInt.parse(privateData['q'], radix: 16),
    );

    final publicKey = RSAPublicKey(
      BigInt.parse(publicData['modulus'], radix: 16),
      BigInt.parse(publicData['exponent'], radix: 16),
    );

    return AsymmetricKeyPair<RSAPublicKey, RSAPrivateKey>(publicKey, privateKey);
  }

  /// Encrypt data with public key
  String encrypt(String plaintext, RSAPublicKey publicKey) {
    final encryptor = OAEPEncoding(RSAEngine())
      ..init(true, PublicKeyParameter<RSAPublicKey>(publicKey));

    final input = Uint8List.fromList(utf8.encode(plaintext));
    final output = encryptor.process(input);

    return base64.encode(output);
  }

  /// Decrypt data with private key
  String decrypt(String ciphertext) {
    final decryptor = OAEPEncoding(RSAEngine())
      ..init(false, PrivateKeyParameter<RSAPrivateKey>(privateKey));

    final input = base64.decode(ciphertext);
    final output = decryptor.process(Uint8List.fromList(input));

    return utf8.decode(output);
  }
}
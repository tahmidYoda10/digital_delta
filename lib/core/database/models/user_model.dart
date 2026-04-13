import 'package:uuid/uuid.dart';
import '../crdt/vector_clock.dart';
import '../../auth/user_role.dart';

class UserModel {
  final String id;
  final String username;
  final String publicKey;
  final UserRole role;
  final DateTime createdAt;
  final VectorClock vectorClock;
  final String deviceId;

  UserModel({
    required this.id,
    required this.username,
    required this.publicKey,
    required this.role,
    required this.createdAt,
    required this.vectorClock,
    required this.deviceId,
  });

  factory UserModel.create({
    required String username,
    required String publicKey,
    required UserRole role,
    required String deviceId,
  }) {
    final vectorClock = VectorClock();
    vectorClock.increment(deviceId);

    return UserModel(
      id: const Uuid().v4(),
      username: username,
      publicKey: publicKey,
      role: role,
      createdAt: DateTime.now(),
      vectorClock: vectorClock,
      deviceId: deviceId,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'public_key': publicKey,
      'role': role.toString(),
      'created_at': createdAt.toIso8601String(),
      'vector_clock': vectorClock.toJson(),
      'device_id': deviceId,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'],
      username: map['username'],
      publicKey: map['public_key'],
      role: RolePermissions.fromString(map['role'].toString().split('.').last),
      createdAt: DateTime.parse(map['created_at']),
      vectorClock: VectorClock.fromJson(map['vector_clock']),
      deviceId: map['device_id'],
    );
  }

  @override
  String toString() {
    return 'UserModel(id: $id, username: $username, role: ${RolePermissions.getRoleName(role)})';
  }
}
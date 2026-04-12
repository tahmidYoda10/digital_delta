import '../crdt/vector_clock.dart';

enum UserRole {
  FIELD_VOLUNTEER,
  SUPPLY_MANAGER,
  DRONE_OPERATOR,
  CAMP_COMMANDER,
  SYNC_ADMIN,
}

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
      role: UserRole.values.firstWhere(
            (e) => e.toString() == map['role'],
        orElse: () => UserRole.FIELD_VOLUNTEER,
      ),
      createdAt: DateTime.parse(map['created_at']),
      vectorClock: VectorClock.fromJson(map['vector_clock']),
      deviceId: map['device_id'],
    );
  }

  /// Check permissions (M1.3 RBAC)
  bool canManageSupplies() {
    return role == UserRole.SUPPLY_MANAGER ||
        role == UserRole.CAMP_COMMANDER ||
        role == UserRole.SYNC_ADMIN;
  }

  bool canOperateDrone() {
    return role == UserRole.DRONE_OPERATOR ||
        role == UserRole.SYNC_ADMIN;
  }

  bool canSyncData() {
    return role == UserRole.SYNC_ADMIN;
  }

  bool canViewAuditLogs() {
    return role == UserRole.CAMP_COMMANDER ||
        role == UserRole.SYNC_ADMIN;
  }
}
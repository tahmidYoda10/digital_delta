import 'package:flutter/material.dart'; // ✅ ADD THIS LINE

/// M1.3 - Role-Based Access Control (RBAC)
enum UserRole {
  AFFECTED_CITIZEN,   // Flood victims in camps
  FIELD_VOLUNTEER,    // Basic field operations
  SUPPLY_MANAGER,     // Inventory management
  DRONE_OPERATOR,     // Drone control
  CAMP_COMMANDER,     // Camp coordination
  SYNC_ADMIN,         // System sync & maintenance
}

class RolePermissions {
  final UserRole role;
  final Set<String> permissions;

  const RolePermissions({
    required this.role,
    required this.permissions,
  });

  /// Define role permissions (M1.3)
  static const Map<UserRole, Set<String>> rolePermissionsMap = {
    UserRole.AFFECTED_CITIZEN: {
      'delivery:receive',
      'pod:sign',
      'inventory:view_local',
      'request:create',
      'notification:receive',
    },

    UserRole.FIELD_VOLUNTEER: {
      'delivery:read',
      'delivery:create',
      'pod:scan',
      'pod:generate',
      'mesh:relay',
      'request:view',
    },

    UserRole.SUPPLY_MANAGER: {
      'delivery:read',
      'delivery:create',
      'delivery:update',
      'inventory:read',
      'inventory:write',
      'mesh:relay',
      'triage:view',
      'request:approve',
    },

    UserRole.DRONE_OPERATOR: {
      'delivery:read',
      'drone:control',
      'handoff:create',
      'mesh:relay',
      'triage:view',
    },

    UserRole.CAMP_COMMANDER: {
      'delivery:read',
      'delivery:update',
      'triage:execute',
      'triage:view',
      'inventory:read',
      'inventory:write',
      'mesh:relay',
      'reports:view',
      'request:approve',
      'request:prioritize',
    },

    UserRole.SYNC_ADMIN: {
      'delivery:read',
      'delivery:update',
      'delivery:delete',
      'inventory:read',
      'inventory:write',
      'inventory:delete',
      'mesh:admin',
      'sync:force',
      'audit:view',
      'user:manage',
      'triage:execute',
      'triage:override',
      'request:override',
    },
  };

  static bool hasPermission(UserRole role, String permission) {
    final permissions = rolePermissionsMap[role] ?? {};
    return permissions.contains(permission);
  }

  static Set<String> getPermissions(UserRole role) {
    return rolePermissionsMap[role] ?? {};
  }

  static UserRole fromString(String roleStr) {
    return UserRole.values.firstWhere(
          (r) => r.toString().split('.').last == roleStr,
      orElse: () => UserRole.FIELD_VOLUNTEER,
    );
  }

  static String getRoleName(UserRole role) {
    switch (role) {
      case UserRole.AFFECTED_CITIZEN:
        return 'Affected Citizen';
      case UserRole.FIELD_VOLUNTEER:
        return 'Field Volunteer';
      case UserRole.SUPPLY_MANAGER:
        return 'Supply Manager';
      case UserRole.DRONE_OPERATOR:
        return 'Drone Operator';
      case UserRole.CAMP_COMMANDER:
        return 'Camp Commander';
      case UserRole.SYNC_ADMIN:
        return 'Sync Administrator';
    }
  }

  static String getRoleDescription(UserRole role) {
    switch (role) {
      case UserRole.AFFECTED_CITIZEN:
        return 'Can receive supplies, sign delivery receipts, and request aid';
      case UserRole.FIELD_VOLUNTEER:
        return 'Delivers supplies and generates proof-of-delivery';
      case UserRole.SUPPLY_MANAGER:
        return 'Manages inventory and approves supply requests';
      case UserRole.DRONE_OPERATOR:
        return 'Operates drones for last-mile delivery';
      case UserRole.CAMP_COMMANDER:
        return 'Coordinates camp operations and triage decisions';
      case UserRole.SYNC_ADMIN:
        return 'Full system access - manages sync and users';
    }
  }

  static IconData getRoleIcon(UserRole role) {
    switch (role) {
      case UserRole.AFFECTED_CITIZEN:
        return Icons.people;
      case UserRole.FIELD_VOLUNTEER:
        return Icons.volunteer_activism;
      case UserRole.SUPPLY_MANAGER:
        return Icons.inventory_2;
      case UserRole.DRONE_OPERATOR:
        return Icons.flight;
      case UserRole.CAMP_COMMANDER:
        return Icons.shield;
      case UserRole.SYNC_ADMIN:
        return Icons.admin_panel_settings;
    }
  }
}
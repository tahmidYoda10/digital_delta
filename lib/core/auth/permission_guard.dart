import 'package:flutter/material.dart';
import 'rbac_manager.dart';
import 'user_role.dart';

class PermissionGuard {
  final RBACManager _rbacManager;

  PermissionGuard(this._rbacManager);

  /// Check permission and show error if denied
  bool checkAndShowError(
      BuildContext context,
      String permission, {
        String? customMessage,
      }) {
    if (_rbacManager.hasPermission(permission)) {
      return true; // ✅ Allowed
    }

    // ❌ Denied - Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.block, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  'Access Denied',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              customMessage ??
                  'Your role (${RolePermissions.getRoleName(_rbacManager.currentRole!)}) '
                      'does not have permission: $permission',
            ),
            const SizedBox(height: 8),
            Text(
              'Required role: ${_getRequiredRole(permission)}',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.white70,
              ),
            ),
          ],
        ),
        backgroundColor: Colors.red.shade700,
        duration: const Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'OK',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );

    return false; // ❌ Not allowed
  }

  /// Show dialog for critical actions
  Future<bool> confirmAction(
      BuildContext context,
      String permission,
      String actionName,
      ) async {
    if (!_rbacManager.hasPermission(permission)) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          icon: const Icon(Icons.error, color: Colors.red, size: 48),
          title: const Text('Access Denied'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('You cannot perform: $actionName'),
              const SizedBox(height: 12),
              Text(
                'Your role: ${RolePermissions.getRoleName(_rbacManager.currentRole!)}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Required: ${_getRequiredRole(permission)}',
                style: TextStyle(color: Colors.grey.shade700),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
      return false;
    }

    return true; // ✅ Allowed
  }

  /// Get which role is required for a permission
  String _getRequiredRole(String permission) {
    for (var entry in RolePermissions.rolePermissionsMap.entries) {
      if (entry.value.contains(permission)) {
        return RolePermissions.getRoleName(entry.key);
      }
    }
    return 'Unknown';
  }

  /// Route guard - blocks navigation
  bool canNavigate(BuildContext context, String permission) {
    if (!_rbacManager.hasPermission(permission)) {
      Navigator.of(context).pop(); // Go back immediately
      checkAndShowError(context, permission);
      return false;
    }
    return true;
  }
}
import '../utils/app_logger.dart';
import '../database/models/user_model.dart';
import 'user_role.dart';

/// M1.3 - RBAC Enforcement Manager
class RBACManager {
  UserModel? _currentUser;

  /// Set current authenticated user
  void setCurrentUser(UserModel user) {
    _currentUser = user;
    AppLogger.info('👤 Current user: ${user.username} (${RolePermissions.getRoleName(user.role)})');
  }

  /// Clear current user (logout)
  void clearCurrentUser() {
    _currentUser = null;
    AppLogger.info('👋 User logged out');
  }

  /// Check if user has permission
  bool hasPermission(String permission) {
    if (_currentUser == null) {
      AppLogger.warning('⛔ No authenticated user');
      return false;
    }

    final hasAccess = RolePermissions.hasPermission(_currentUser!.role, permission);

    if (!hasAccess) {
      AppLogger.warning(
        '⛔ Access denied: ${_currentUser!.username} lacks permission "$permission"',
      );
    }

    return hasAccess;
  }

  /// Enforce permission (throws exception if denied)
  void enforcePermission(String permission) {
    if (!hasPermission(permission)) {
      throw PermissionDeniedException(
        'User ${_currentUser?.username ?? "unknown"} does not have permission: $permission',
      );
    }
  }

  /// Check if user has any of the permissions
  bool hasAnyPermission(List<String> permissions) {
    return permissions.any((permission) => hasPermission(permission));
  }

  /// Check if user has all permissions
  bool hasAllPermissions(List<String> permissions) {
    return permissions.every((permission) => hasPermission(permission));
  }

  /// Get current user
  UserModel? get currentUser => _currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => _currentUser != null;

  /// Get current user role
  UserRole? get currentRole => _currentUser?.role;

  /// Get all permissions for current user
  Set<String> get currentPermissions {
    if (_currentUser == null) return {};
    return RolePermissions.getPermissions(_currentUser!.role);
  }
}

/// Custom exception for permission denial
class PermissionDeniedException implements Exception {
  final String message;

  PermissionDeniedException(this.message);

  @override
  String toString() => 'PermissionDeniedException: $message';
}
import 'package:flutter/material.dart';
import '../rbac_manager.dart';

class ProtectedWidget extends StatelessWidget {
  final String permission;
  final Widget child;
  final Widget? fallback;
  final RBACManager rbacManager;

  const ProtectedWidget({
    super.key,
    required this.permission,
    required this.child,
    required this.rbacManager,
    this.fallback,
  });

  @override
  Widget build(BuildContext context) {
    if (rbacManager.hasPermission(permission)) {
      return child;
    }

    return fallback ?? const SizedBox.shrink();
  }
}
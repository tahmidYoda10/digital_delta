import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/auth/user_role.dart';
import '../../../../core/auth/rbac_manager.dart';
import '../../../../core/auth/permission_guard.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../../auth/presentation/bloc/auth_event.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AuthBloc, AuthState>(
      builder: (context, state) {
        if (state is! AuthAuthenticated) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final user = state.user;
        final role = user.role;

        return Scaffold(
          appBar: AppBar(
            title: Text('Digital Delta - ${RolePermissions.getRoleName(role)}'),
            backgroundColor: _getRoleColor(role),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                onPressed: () {
                  context.read<AuthBloc>().add(AuthLogoutRequested());
                  Navigator.pushReplacementNamed(context, '/login');
                },
              ),
            ],
          ),
          body: _buildRoleBasedHome(context, role),
          drawer: _buildDrawer(context, user),
        );
      },
    );
  }

  Widget _buildRoleBasedHome(BuildContext context, UserRole role) {
    switch (role) {
      case UserRole.AFFECTED_CITIZEN:
        return _CitizenHomeView();
      case UserRole.FIELD_VOLUNTEER:
        return _VolunteerHomeView();
      case UserRole.SUPPLY_MANAGER:
      case UserRole.CAMP_COMMANDER:
        return _ManagerHomeView();
      case UserRole.DRONE_OPERATOR:
        return _DroneOperatorHomeView();
      case UserRole.SYNC_ADMIN:
        return _AdminHomeView();
    }
  }

  Color _getRoleColor(UserRole role) {
    switch (role) {
      case UserRole.AFFECTED_CITIZEN:
        return Colors.blue;
      case UserRole.FIELD_VOLUNTEER:
        return Colors.green;
      case UserRole.SUPPLY_MANAGER:
      case UserRole.CAMP_COMMANDER:
        return Colors.orange;
      case UserRole.DRONE_OPERATOR:
        return Colors.purple;
      case UserRole.SYNC_ADMIN:
        return Colors.red;
    }
  }

  Widget _buildDrawer(BuildContext context, dynamic user) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          UserAccountsDrawerHeader(
            accountName: Text(user.username),
            accountEmail: Text(RolePermissions.getRoleName(user.role)),
            currentAccountPicture: CircleAvatar(
              backgroundColor: Colors.white,
              child: Icon(
                RolePermissions.getRoleIcon(user.role),
                size: 40,
                color: _getRoleColor(user.role),
              ),
            ),
            decoration: BoxDecoration(color: _getRoleColor(user.role)),
          ),
          ListTile(
            leading: const Icon(Icons.home),
            title: const Text('Home'),
            onTap: () => Navigator.pop(context),
          ),
          ListTile(
            leading: const Icon(Icons.person),
            title: const Text('Profile'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile page coming soon')),
              );
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Settings page coming soon')),
              );
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout, color: Colors.red),
            title: const Text('Logout', style: TextStyle(color: Colors.red)),
            onTap: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
              Navigator.pushReplacementNamed(context, '/login');
            },
          ),
        ],
      ),
    );
  }
}

// ========================================
// CITIZEN HOME VIEW
// ========================================
class _CitizenHomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.blue.shade50, Colors.white],
        ),
      ),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Welcome Card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.waving_hand, size: 32, color: Colors.orange.shade700),
                      const SizedBox(width: 12),
                      const Text(
                        'Welcome!',
                        style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'You can request essential supplies and track your deliveries here.',
                    style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Quick Actions
          const Text(
            'Quick Actions',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          // Request Supplies Button
          _ActionCard(
            icon: Icons.add_shopping_cart,
            title: 'Request Supplies',
            subtitle: 'Submit a new request for food, water, medicine, etc.',
            color: Colors.blue,
            onTap: () => Navigator.pushNamed(context, '/request-supplies'),
          ),

          // My Requests Button
          _ActionCard(
            icon: Icons.list_alt,
            title: 'My Requests',
            subtitle: 'View status of your submitted requests',
            color: Colors.green,
            onTap: () => Navigator.pushNamed(context, '/my-requests'),
          ),

          // My Deliveries Button - Coming Soon
          _ActionCard(
            icon: Icons.local_shipping,
            title: 'My Deliveries',
            subtitle: 'Track your incoming deliveries',
            color: Colors.orange,
            onTap: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('🚧 Coming soon! Feature under development.'),
                  backgroundColor: Colors.orange,
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),

          const SizedBox(height: 24),

          // Emergency Help
          Card(
            color: Colors.red.shade50,
            child: ListTile(
              leading: const Icon(Icons.emergency, color: Colors.red, size: 32),
              title: const Text(
                'Medical Emergency?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              subtitle: const Text('Mark your request as urgent'),
              trailing: ElevatedButton(
                onPressed: () => Navigator.pushNamed(context, '/request-supplies'),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Request Now'),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ========================================
// MANAGER/COMMANDER HOME VIEW
// ========================================
class _ManagerHomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Manager Dashboard',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        _ActionCard(
          icon: Icons.approval,
          title: 'Approve Requests',
          subtitle: 'Review pending supply requests',
          color: Colors.green,
          onTap: () => Navigator.pushNamed(context, '/approve-requests'),
        ),

        _ActionCard(
          icon: Icons.inventory_2,
          title: 'Manage Inventory',
          subtitle: 'View and update stock levels',
          color: Colors.blue,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🚧 Coming soon!')),
            );
          },
        ),

        _ActionCard(
          icon: Icons.local_shipping,
          title: 'Deliveries',
          subtitle: 'Track active deliveries',
          color: Colors.orange,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🚧 Coming soon!')),
            );
          },
        ),
      ],
    );
  }
}

// ========================================
// VOLUNTEER HOME VIEW
// ========================================
class _VolunteerHomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Volunteer Dashboard',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        _ActionCard(
          icon: Icons.qr_code_scanner,
          title: 'Scan Delivery',
          subtitle: 'Scan QR code for proof of delivery',
          color: Colors.blue,
          onTap: () => Navigator.pushNamed(context, '/delivery-scan'),
        ),

        _ActionCard(
          icon: Icons.list,
          title: 'View Requests',
          subtitle: 'See all supply requests',
          color: Colors.green,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🚧 Coming soon!')),
            );
          },
        ),
      ],
    );
  }
}

// ========================================
// DRONE OPERATOR HOME VIEW
// ========================================
class _DroneOperatorHomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Drone Operations',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        _ActionCard(
          icon: Icons.flight,
          title: 'Fleet Dashboard',
          subtitle: 'Monitor drone fleet status',
          color: Colors.purple,
          onTap: () => Navigator.pushNamed(context, '/fleet-dashboard'),
        ),

        _ActionCard(
          icon: Icons.map,
          title: 'Flight Map',
          subtitle: 'View active drone routes',
          color: Colors.blue,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🚧 Coming soon!')),
            );
          },
        ),
      ],
    );
  }
}

// ========================================
// ADMIN HOME VIEW
// ========================================
class _AdminHomeView extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'System Administration',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        _ActionCard(
          icon: Icons.people,
          title: 'User Management',
          subtitle: 'Manage users and roles',
          color: Colors.red,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🚧 Coming soon!')),
            );
          },
        ),

        _ActionCard(
          icon: Icons.sync,
          title: 'Mesh Network',
          subtitle: 'View mesh sync status',
          color: Colors.blue,
          onTap: () => Navigator.pushNamed(context, '/mesh-debug'),
        ),

        _ActionCard(
          icon: Icons.history,
          title: 'Audit Logs',
          subtitle: 'View system audit trail',
          color: Colors.orange,
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('🚧 Coming soon!')),
            );
          },
        ),
      ],
    );
  }
}

// ========================================
// REUSABLE ACTION CARD
// ========================================
class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 32),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, color: Colors.grey.shade400, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
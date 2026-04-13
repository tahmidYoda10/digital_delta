import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../network/connection_status_cubit.dart';

class ConnectionStatusBar extends StatelessWidget {
  const ConnectionStatusBar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ConnectionStatusCubit, ConnectionStatus>(
      builder: (context, status) {
        final cubit = context.read<ConnectionStatusCubit>();

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: _getBackgroundColor(status),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                offset: const Offset(0, 2),
                blurRadius: 4,
              ),
            ],
          ),
          child: Row(
            children: [
              Text(
                cubit.getStatusIcon(),
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cubit.getStatusText(),
                  style: TextStyle(
                    color: _getTextColor(status),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (status == ConnectionStatus.OFFLINE)
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/mesh-debug');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _getTextColor(status),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text('Connect'),
                ),
              if (status == ConnectionStatus.CONFLICT)
                TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/mesh-debug');
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: _getTextColor(status),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  ),
                  child: const Text('Resolve'),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _getBackgroundColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.OFFLINE:
        return Colors.red.shade50;
      case ConnectionStatus.SCANNING:
      case ConnectionStatus.SYNCING:
        return Colors.orange.shade50;
      case ConnectionStatus.ONLINE:
        return Colors.green.shade50;
      case ConnectionStatus.CONFLICT:
        return Colors.purple.shade50;
    }
  }

  Color _getTextColor(ConnectionStatus status) {
    switch (status) {
      case ConnectionStatus.OFFLINE:
        return Colors.red.shade900;
      case ConnectionStatus.SCANNING:
      case ConnectionStatus.SYNCING:
        return Colors.orange.shade900;
      case ConnectionStatus.ONLINE:
        return Colors.green.shade900;
      case ConnectionStatus.CONFLICT:
        return Colors.purple.shade900;
    }
  }
}
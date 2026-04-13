import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/crypto/key_manager.dart';
import 'core/crypto/totp_manager.dart';
import 'core/network/connection_status_cubit.dart';  // ✅ NEW
import 'features/auth/data/auth_repository_impl.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/home/presentation/pages/home_page.dart';
import 'features/citizen/presentation/pages/request_supplies_page.dart';
import 'features/requests/presentation/pages/my_requests_page.dart';
import 'features/requests/presentation/pages/approve_requests_page.dart';
import 'features/requests/presentation/pages/all_requests_page.dart';
import 'features/delivery/presentation/pages/delivery_scan_page.dart';
import 'features/delivery/presentation/bloc/delivery_bloc.dart';
import 'features/fleet/presentation/pages/fleet_dashboard_page.dart';
import 'features/fleet/presentation/bloc/fleet_bloc.dart';
import 'features/mesh/presentation/pages/mesh_debug_page.dart';
import 'features/mesh/presentation/bloc/mesh_bloc.dart';
import 'core/network/mesh/mesh_manager.dart';
import 'core/delivery/pod_generator.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize crypto
  final keyManager = KeyManager();
  await keyManager.initialize();

  final totpManager = TOTPManager();
  await totpManager.initialize();

  // Initialize mesh network
  final meshManager = MeshManager(keyManager: keyManager);
  await meshManager.initialize();

  // Initialize PoD generator
  final podGenerator = PoDGenerator(keyManager: keyManager);

  runApp(DigitalDeltaApp(
    keyManager: keyManager,
    totpManager: totpManager,
    meshManager: meshManager,
    podGenerator: podGenerator,
  ));
}

class DigitalDeltaApp extends StatelessWidget {
  final KeyManager keyManager;
  final TOTPManager totpManager;
  final MeshManager meshManager;
  final PoDGenerator podGenerator;

  const DigitalDeltaApp({
    super.key,
    required this.keyManager,
    required this.totpManager,
    required this.meshManager,
    required this.podGenerator,
  });

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<AuthRepositoryImpl>(
          create: (context) => AuthRepositoryImpl(
            totpManager: totpManager,
            keyManager: keyManager,
          ),
        ),
        RepositoryProvider<MeshManager>.value(value: meshManager),
        RepositoryProvider<PoDGenerator>.value(value: podGenerator),
        RepositoryProvider<KeyManager>.value(value: keyManager),
      ],
      child: MultiBlocProvider(
        providers: [
          // ✅ NEW: Global Connection Status
          BlocProvider(
            create: (context) => ConnectionStatusCubit(),
          ),

          // Auth BLoC
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepositoryImpl>(),
              totpManager: totpManager,
            )..add(AuthCheckRequested()),
          ),

          // Delivery BLoC
          BlocProvider(
            create: (context) => DeliveryBloc(
              podGenerator: podGenerator,
              keyManager: keyManager,
            ),
          ),

          // Fleet BLoC
          BlocProvider(
            create: (context) => FleetBloc(),
          ),

          // Mesh BLoC
          BlocProvider(
            create: (context) => MeshBloc(
              meshManager: meshManager,
            ),
          ),
        ],
        child: MaterialApp(
          title: 'Digital Delta',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
            useMaterial3: true,
          ),
          initialRoute: '/login',
          routes: {
            '/login': (context) => const LoginPage(),
            '/home': (context) => const HomePage(),
            '/request-supplies': (context) => const RequestSuppliesPage(),
            '/my-requests': (context) => const MyRequestsPage(),
            '/approve-requests': (context) => const ApproveRequestsPage(),
            '/all-requests': (context) => const AllRequestsPage(),
            '/delivery-scan': (context) => const DeliveryScanPage(),
            '/fleet-dashboard': (context) => const FleetDashboardPage(),
            '/mesh-debug': (context) => const MeshDebugPage(),
          },
        ),
      ),
    );
  }
}
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/utils/app_logger.dart';
import 'core/constants/app_constants.dart';
import 'core/database/database_helper.dart';
import 'core/crypto/key_manager.dart';
import 'core/crypto/totp_manager.dart';
import 'core/routing/graph_manager.dart';
import 'core/ml/ml_model.dart';
import 'core/delivery/pod_generator.dart';
import 'core/delivery/pod_verifier.dart';
import 'features/auth/data/auth_repository_impl.dart';
import 'features/auth/presentation/bloc/auth_bloc.dart';
import 'features/auth/presentation/bloc/auth_event.dart';
import 'features/auth/presentation/pages/login_page.dart';
import 'features/routing/presentation/bloc/routing_bloc.dart';
import 'features/routing/presentation/bloc/routing_event.dart';
import 'features/routing/presentation/pages/map_page.dart';
import 'features/delivery/presentation/bloc/delivery_bloc.dart';
import 'features/delivery/presentation/pages/delivery_scan_page.dart';
import 'features/triage/presentation/pages/triage_dashboard_page.dart';
import 'features/prediction/presentation/bloc/prediction_bloc.dart';
import 'features/prediction/presentation/bloc/prediction_event.dart';
import 'features/prediction/presentation/pages/prediction_dashboard_page.dart';
import 'features/prediction/data/rainfall_datasource.dart';
import 'features/fleet/presentation/bloc/fleet_bloc.dart';
import 'features/fleet/presentation/bloc/fleet_event.dart';
import 'features/fleet/presentation/pages/fleet_dashboard_page.dart';
import 'features/fleet/domain/usecases/calculate_rendezvous_usecase.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppLogger.info('🚀 ${AppConstants.appName} v${AppConstants.appVersion} Starting...');

  await initializeServices();

  runApp(const DigitalDeltaApp());
}

// ✅ FUNCTION DEFINED FIRST (before being called)
Future<void> _loadDemoGraphData(GraphManager graphManager) async {
  // Check if data already loaded
  if (graphManager.nodes.isNotEmpty) {
    AppLogger.info('Graph data already exists, skipping load');
    return;
  }

  // Sylhet Division Demo Graph
  final demoGraph = {
    "nodes": [
      {"id": "N1", "name": "Sylhet City Hub", "type": "central_command", "lat": 24.8949, "lng": 91.8667},
      {"id": "N2", "name": "Osmani Airport", "type": "supply_drop", "lat": 24.9632, "lng": 91.8668},
      {"id": "N3", "name": "Sunamganj Camp", "type": "relief_camp", "lat": 25.0658, "lng": 91.4073},
      {"id": "N4", "name": "Companyganj Outpost", "type": "relief_camp", "lat": 25.0715, "lng": 91.7554},
      {"id": "N5", "name": "Kanaighat Point", "type": "waypoint", "lat": 24.9945, "lng": 92.2611},
      {"id": "N6", "name": "Habiganj Hospital", "type": "hospital", "lat": 24.3840, "lng": 91.4169}
    ],
    "edges": [
      {"id": "E1", "source": "N1", "target": "N2", "type": "road", "base_weight_mins": 20, "is_flooded": false},
      {"id": "E2", "source": "N1", "target": "N3", "type": "road", "base_weight_mins": 90, "is_flooded": false},
      {"id": "E3", "source": "N2", "target": "N4", "type": "road", "base_weight_mins": 45, "is_flooded": false},
      {"id": "E4", "source": "N1", "target": "N5", "type": "road", "base_weight_mins": 60, "is_flooded": false},
      {"id": "E5", "source": "N1", "target": "N6", "type": "road", "base_weight_mins": 120, "is_flooded": false},
      {"id": "E6", "source": "N1", "target": "N3", "type": "river", "base_weight_mins": 150, "is_flooded": false},
      {"id": "E7", "source": "N3", "target": "N4", "type": "river", "base_weight_mins": 30, "is_flooded": false}
    ]
  };

  await graphManager.importFromJson(demoGraph);
  AppLogger.info('✅ Demo graph loaded: ${graphManager.nodes.length} nodes, ${graphManager.edges.length} edges');
}

Future<void> initializeServices() async {
  try {
    AppLogger.info('📦 Initializing database...');
    final db = DatabaseHelper.instance;
    await db.database;

    AppLogger.info('🔑 Initializing crypto...');
    final keyManager = KeyManager();
    await keyManager.initialize();

    AppLogger.info('🔐 Initializing TOTP...');
    final totpManager = TOTPManager();
    await totpManager.initialize();

    // ✅ Load demo graph data
    AppLogger.info('🗺️ Loading demo graph data...');
    final graphManager = GraphManager();
    await graphManager.initialize();
    await _loadDemoGraphData(graphManager);

    AppLogger.info('✅ All services initialized');

  } catch (e, stack) {
    AppLogger.critical('Failed to initialize services', e, stack);
  }
}

class DigitalDeltaApp extends StatelessWidget {
  const DigitalDeltaApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<KeyManager>(
          create: (context) => KeyManager()..initialize(),
        ),
        RepositoryProvider<TOTPManager>(
          create: (context) => TOTPManager()..initialize(),
        ),
        RepositoryProvider<GraphManager>(
          create: (context) => GraphManager()..initialize(),
        ),
        RepositoryProvider<MLModel>(
          create: (context) => MLModel(),
        ),
        RepositoryProvider<RainfallDataSource>(
          create: (context) => RainfallDataSource(),
        ),
        RepositoryProvider<AuthRepositoryImpl>(
          create: (context) => AuthRepositoryImpl(
            totpManager: context.read<TOTPManager>(),
            keyManager: context.read<KeyManager>(),
          ),
        ),
        RepositoryProvider<PoDGenerator>(
          create: (context) => PoDGenerator(
            keyManager: context.read<KeyManager>(),
          ),
        ),
        RepositoryProvider<PoDVerifier>(
          create: (context) => PoDVerifier(
            keyManager: context.read<KeyManager>(),
            generator: context.read<PoDGenerator>(),
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider(
            create: (context) => AuthBloc(
              authRepository: context.read<AuthRepositoryImpl>(),
              totpManager: context.read<TOTPManager>(),
            )..add(AuthCheckRequested()),
          ),
          BlocProvider(
            create: (context) => RoutingBloc(
              graphManager: context.read<GraphManager>(),
            )..add(RoutingInitializeRequested()),
          ),
          BlocProvider(
            create: (context) => DeliveryBloc(
              podGenerator: context.read<PoDGenerator>(),
              podVerifier: context.read<PoDVerifier>(),
            ),
          ),
          BlocProvider(
            create: (context) => PredictionBloc(
              mlModel: context.read<MLModel>(),
              graphManager: context.read<GraphManager>(),
              rainfallDataSource: context.read<RainfallDataSource>(),
            )..add(PredictionInitializeRequested()),
          ),
          BlocProvider(
            create: (context) => FleetBloc(
              calculateRendezvousUseCase: CalculateRendezvousUseCase(),
            )..add(FleetInitializeRequested()),
          ),
        ],
        child: MaterialApp(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.light,
          ),
          darkTheme: ThemeData(
            primarySwatch: Colors.blue,
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          themeMode: ThemeMode.system,
          home: const LoginPage(),
          routes: {
            '/login': (context) => const LoginPage(),
            '/home': (context) => const MainDashboard(),
            '/map': (context) => const MapPage(),
            '/delivery': (context) => const DeliveryScanPage(),
            '/triage': (context) => const TriageDashboardPage(),
            '/prediction': (context) => const PredictionDashboardPage(),
            '/fleet': (context) => const FleetDashboardPage(),
          },
        ),
      ),
    );
  }
}

class MainDashboard extends StatelessWidget {
  const MainDashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Delta'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              context.read<AuthBloc>().add(AuthLogoutRequested());
              Navigator.of(context).pushReplacementNamed('/login');
            },
          ),
        ],
      ),
      body: GridView.count(
        crossAxisCount: 2,
        padding: const EdgeInsets.all(16),
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        children: [
          _buildDashboardCard(
            context,
            title: 'Route Map',
            icon: Icons.map,
            color: Colors.blue,
            route: '/map',
          ),
          _buildDashboardCard(
            context,
            title: 'Proof of Delivery',
            icon: Icons.qr_code_scanner,
            color: Colors.green,
            route: '/delivery',
          ),
          _buildDashboardCard(
            context,
            title: 'Triage Engine',
            icon: Icons.emergency,
            color: Colors.red,
            route: '/triage',
          ),
          _buildDashboardCard(
            context,
            title: 'ML Predictions',
            icon: Icons.analytics,
            color: Colors.purple,
            route: '/prediction',
          ),
          _buildDashboardCard(
            context,
            title: 'Fleet Management',
            icon: Icons.airplanemode_active,
            color: Colors.orange,
            route: '/fleet',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardCard(
      BuildContext context, {
        required String title,
        required IconData icon,
        required Color color,
        required String route,
      }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: () => Navigator.pushNamed(context, route),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 64, color: color),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
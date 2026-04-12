import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../constants/app_constants.dart';
import '../utils/app_logger.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _database;

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), AppConstants.dbName);

    AppLogger.info('📦 Initializing database at: $path');

    return await openDatabase(
      path,
      version: AppConstants.dbVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onCreate(Database db, int version) async {
    AppLogger.info('🔨 Creating database tables...');

    // M1: Users table with RBAC
    await db.execute('''
      CREATE TABLE users (
        id TEXT PRIMARY KEY,
        username TEXT UNIQUE NOT NULL,
        public_key TEXT NOT NULL,
        role TEXT NOT NULL,
        created_at TEXT NOT NULL,
        vector_clock TEXT NOT NULL,
        device_id TEXT NOT NULL
      )
    ''');

    // M1: Auth logs (immutable audit trail)
    await db.execute('''
      CREATE TABLE auth_logs (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        event_type TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        device_id TEXT NOT NULL,
        prev_hash TEXT,
        current_hash TEXT NOT NULL,
        FOREIGN KEY (user_id) REFERENCES users(id)
      )
    ''');

    // M2: CRDT metadata table
    await db.execute('''
      CREATE TABLE crdt_metadata (
        table_name TEXT NOT NULL,
        record_id TEXT NOT NULL,
        vector_clock TEXT NOT NULL,
        device_id TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        operation TEXT NOT NULL,
        tombstone INTEGER DEFAULT 0,
        PRIMARY KEY (table_name, record_id, device_id)
      )
    ''');

    // M4: Supply inventory (CRDT-backed)
    await db.execute('''
      CREATE TABLE supplies (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        quantity INTEGER NOT NULL,
        priority TEXT NOT NULL,
        location_id TEXT,
        vector_clock TEXT NOT NULL,
        device_id TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    // M4: Network graph nodes
    await db.execute('''
      CREATE TABLE nodes (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        latitude REAL NOT NULL,
        longitude REAL NOT NULL,
        is_active INTEGER DEFAULT 1
      )
    ''');

    // M4: Network graph edges
    await db.execute('''
      CREATE TABLE edges (
        id TEXT PRIMARY KEY,
        source_id TEXT NOT NULL,
        target_id TEXT NOT NULL,
        edge_type TEXT NOT NULL,
        base_weight REAL NOT NULL,
        current_weight REAL NOT NULL,
        is_flooded INTEGER DEFAULT 0,
        risk_score REAL DEFAULT 0.0,
        FOREIGN KEY (source_id) REFERENCES nodes(id),
        FOREIGN KEY (target_id) REFERENCES nodes(id)
      )
    ''');

    // M5: Deliveries (Proof of Delivery)
    await db.execute('''
      CREATE TABLE deliveries (
        id TEXT PRIMARY KEY,
        supply_id TEXT NOT NULL,
        driver_id TEXT NOT NULL,
        recipient_id TEXT,
        route_id TEXT,
        status TEXT NOT NULL,
        qr_signature TEXT,
        vector_clock TEXT NOT NULL,
        created_at TEXT NOT NULL,
        completed_at TEXT,
        FOREIGN KEY (supply_id) REFERENCES supplies(id)
      )
    ''');

    // M6: Triage decisions log
    await db.execute('''
      CREATE TABLE triage_events (
        id TEXT PRIMARY KEY,
        delivery_id TEXT NOT NULL,
        decision_type TEXT NOT NULL,
        reason TEXT NOT NULL,
        timestamp TEXT NOT NULL,
        FOREIGN KEY (delivery_id) REFERENCES deliveries(id)
      )
    ''');

    AppLogger.info('✅ Database tables created successfully');
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    AppLogger.info('⬆️ Upgrading database from v$oldVersion to v$newVersion');
    // Handle schema migrations here
  }

  /// Insert with CRDT metadata
  Future<int> insertWithCRDT({
    required String table,
    required Map<String, dynamic> values,
    required String deviceId,
    required String recordId,
  }) async {
    final db = await database;

    return await db.transaction((txn) async {
      // Insert main record
      await txn.insert(table, values, conflictAlgorithm: ConflictAlgorithm.replace);

      // Insert CRDT metadata
      await txn.insert('crdt_metadata', {
        'table_name': table,
        'record_id': recordId,
        'vector_clock': values['vector_clock'],
        'device_id': deviceId,
        'timestamp': DateTime.now().toIso8601String(),
        'operation': 'INSERT',
        'tombstone': 0,
      }, conflictAlgorithm: ConflictAlgorithm.replace);

      return 1;
    });
  }

  /// Query with conflict detection
  Future<List<Map<String, dynamic>>> queryWithConflicts(String table) async {
    final db = await database;

    // Get all versions from different devices
    final results = await db.rawQuery('''
      SELECT m.*, r.*
      FROM crdt_metadata m
      JOIN $table r ON m.record_id = r.id
      WHERE m.table_name = ?
      ORDER BY m.record_id, m.timestamp DESC
    ''', [table]);

    return results;
  }

  Future<void> close() async {
    final db = await database;
    await db.close();
  }
}
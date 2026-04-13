import 'package:latlong2/latlong.dart';
import '../database/database_helper.dart';
import '../utils/app_logger.dart';
import 'models/graph_node.dart';
import 'models/graph_edge.dart';
import 'route_calculator.dart';

class GraphManager {
  final DatabaseHelper _db = DatabaseHelper.instance;

  Map<String, GraphNode> _nodes = {};
  List<GraphEdge> _edges = [];
  RouteCalculator? _calculator;

  /// Initialize graph from database
  Future<void> initialize() async {
    try {
      AppLogger.info('🗺️ Initializing graph manager...');

      await _loadNodesFromDB();
      await _loadEdgesFromDB();

      // ✅ IF NO DATA, LOAD DEMO DATA
      if (_nodes.isEmpty || _edges.isEmpty) {
        AppLogger.warning('No graph data found, loading demo data...');
        await _loadDemoData();
      }

      _rebuildCalculator();

      AppLogger.info('✅ Graph loaded: ${_nodes.length} nodes, ${_edges.length} edges');

    } catch (e, stack) {
      AppLogger.error('Failed to initialize graph', e, stack);
      rethrow;
    }
  }

  /// Load nodes from database
  Future<void> _loadNodesFromDB() async {
    final database = await _db.database;
    final results = await database.query('nodes');

    _nodes = {};
    for (var row in results) {
      final node = GraphNode.fromMap(row);
      _nodes[node.id] = node;
    }
  }

  /// Load edges from database
  Future<void> _loadEdgesFromDB() async {
    final database = await _db.database;
    final results = await database.query('edges');

    _edges = results.map((row) => GraphEdge.fromMap(row)).toList();
  }

  /// ✅ LOAD DEMO DATA (Sylhet area) - FIXED VERSION
  Future<void> _loadDemoData() async {
    final demoGraph = {
      "nodes": [
        {"id": "N1", "name": "Central Command (Sylhet)", "type": "central_command", "lat": 24.8949, "lng": 91.8667},
        {"id": "N2", "name": "Osmani Airport", "type": "supply_drop", "lat": 24.9633, "lng": 91.8679},
        {"id": "N3", "name": "Sunamganj Camp", "type": "relief_camp", "lat": 25.0657, "lng": 91.3958},
        {"id": "N4", "name": "Companyganj Outpost", "type": "hospital", "lat": 24.6333, "lng": 91.9833},
        {"id": "N5", "name": "Kanaighat Point", "type": "waypoint", "lat": 25.0500, "lng": 92.2000},
        {"id": "N6", "name": "Habiganj Hospital", "type": "hospital", "lat": 24.3745, "lng": 91.4160},
      ],
      "edges": [
        {"id": "E1", "source": "N1", "target": "N2", "type": "road", "base_weight_mins": 20.0, "is_flooded": false},
        {"id": "E2", "source": "N1", "target": "N3", "type": "waterway", "base_weight_mins": 90.0, "is_flooded": false},
        {"id": "E3", "source": "N2", "target": "N4", "type": "road", "base_weight_mins": 45.0, "is_flooded": false},
        {"id": "E4", "source": "N3", "target": "N4", "type": "waterway", "base_weight_mins": 120.0, "is_flooded": false},
        {"id": "E5", "source": "N1", "target": "N5", "type": "road", "base_weight_mins": 60.0, "is_flooded": false},
        {"id": "E6", "source": "N5", "target": "N6", "type": "airway", "base_weight_mins": 15.0, "is_flooded": false},
        {"id": "E7", "source": "N4", "target": "N6", "type": "road", "base_weight_mins": 50.0, "is_flooded": false},
      ]
    };

    await importFromJson(demoGraph);

    // ✅ FORCE RELOAD nodes after import
    await _loadNodesFromDB();
    await _loadEdgesFromDB();

    AppLogger.info('📍 Demo nodes loaded: ${_nodes.keys.join(", ")}');
  }

  /// Rebuild route calculator
  void _rebuildCalculator() {
    _calculator = RouteCalculator(
      nodes: _nodes,
      edges: _edges,
    );
  }

  /// Update edge (e.g., mark as flooded) - M4.2
  Future<void> updateEdge(String edgeId, {
    bool? isFlooded,
    double? currentWeight,
    double? riskScore,
  }) async {
    try {
      final edgeIndex = _edges.indexWhere((e) => e.id == edgeId);
      if (edgeIndex == -1) {
        AppLogger.warning('Edge not found: $edgeId');
        return;
      }

      final edge = _edges[edgeIndex];
      final updatedEdge = edge.copyWith(
        isFlooded: isFlooded ?? edge.isFlooded,
        currentWeight: currentWeight ?? edge.currentWeight,
        riskScore: riskScore ?? edge.riskScore,
      );

      _edges[edgeIndex] = updatedEdge;

      // Update in database
      final database = await _db.database;
      await database.update(
        'edges',
        updatedEdge.toMap(),
        where: 'id = ?',
        whereArgs: [edgeId],
      );

      // Rebuild calculator for fast recalculation
      _rebuildCalculator();

      AppLogger.info('🔄 Edge updated: $edgeId (flooded: ${updatedEdge.isFlooded}, risk: ${updatedEdge.riskScore})');

    } catch (e, stack) {
      AppLogger.error('Failed to update edge', e, stack);
    }
  }

  /// Get route calculator
  RouteCalculator? get calculator => _calculator;

  /// Get all nodes
  Map<String, GraphNode> get nodes => _nodes;

  /// Get all edges
  List<GraphEdge> get edges => _edges;

  /// Get edges by type
  List<GraphEdge> getEdgesByType(EdgeType type) {
    return _edges.where((e) => e.edgeType == type).toList();
  }

  /// Get flooded edges
  List<GraphEdge> getFloodedEdges() {
    return _edges.where((e) => e.isFlooded).toList();
  }

  /// Import graph from JSON (for demo data)
  Future<void> importFromJson(Map<String, dynamic> json) async {
    try {
      AppLogger.info('📥 Importing graph from JSON...');

      final database = await _db.database;

      // Clear existing data
      await database.delete('nodes');
      await database.delete('edges');

      // Import nodes
      final nodesList = json['nodes'] as List;
      for (var nodeData in nodesList) {
        final node = GraphNode(
          id: nodeData['id'],
          name: nodeData['name'],
          type: NodeType.values.firstWhere(
                (e) => e.toString().split('.').last.toLowerCase() == nodeData['type'].toString().toLowerCase(),
            orElse: () => NodeType.WAYPOINT,
          ),
          position: LatLng(nodeData['lat'], nodeData['lng']),
        );

        await database.insert('nodes', node.toMap());
        _nodes[node.id] = node;
      }

      // Import edges
      final edgesList = json['edges'] as List;
      for (var edgeData in edgesList) {
        final edge = GraphEdge(
          id: edgeData['id'],
          sourceId: edgeData['source'],
          targetId: edgeData['target'],
          edgeType: _parseEdgeType(edgeData['type']),
          baseWeight: edgeData['base_weight_mins'].toDouble(),
          isFlooded: edgeData['is_flooded'] ?? false,
        );

        await database.insert('edges', edge.toMap());
        _edges.add(edge);
      }

      _rebuildCalculator();
      AppLogger.info('✅ Graph imported successfully');

    } catch (e, stack) {
      AppLogger.error('Failed to import graph', e, stack);
    }
  }

  EdgeType _parseEdgeType(String type) {
    switch (type.toLowerCase()) {
      case 'road':
        return EdgeType.ROAD;
      case 'river':
      case 'waterway':
        return EdgeType.WATERWAY;
      case 'airway':
        return EdgeType.AIRWAY;
      default:
        return EdgeType.ROAD;
    }
  }
}
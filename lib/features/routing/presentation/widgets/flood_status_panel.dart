import 'package:flutter/material.dart';
import '../../../../core/routing/models/graph_edge.dart';

class FloodStatusPanel extends StatelessWidget {
  final List<GraphEdge> edges;
  final bool chaosActive;

  const FloodStatusPanel({
    super.key,
    required this.edges,
    required this.chaosActive,
  });

  @override
  Widget build(BuildContext context) {
    final floodedEdges = edges.where((e) => e.isFlooded).toList();
    final riskyEdges = edges.where((e) => !e.isFlooded && e.riskScore > 0.5).toList();
    final safeEdges = edges.where((e) => !e.isFlooded && e.riskScore <= 0.5).toList();

    return Container(
      margin: const EdgeInsets.all(8),
      padding: const EdgeInsets.all(12),
      constraints: const BoxConstraints(
        maxWidth: 250,
        maxHeight: 400,
      ),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  chaosActive ? Icons.thunderstorm : Icons.water_drop,
                  color: chaosActive ? Colors.orange : Colors.blue,
                  size: 20,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Network Status',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                if (chaosActive)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning, size: 14, color: Colors.orange[700]),
                        const SizedBox(width: 4),
                        Text(
                          'CHAOS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Status chips
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _StatusChip(
                  icon: Icons.check_circle,
                  label: 'Safe',
                  count: safeEdges.length,
                  color: Colors.green,
                  percentage: edges.isEmpty ? 0 : (safeEdges.length / edges.length * 100).round(),
                ),
                _StatusChip(
                  icon: Icons.warning_amber,
                  label: 'Risk',
                  count: riskyEdges.length,
                  color: Colors.orange,
                  percentage: edges.isEmpty ? 0 : (riskyEdges.length / edges.length * 100).round(),
                ),
                _StatusChip(
                  icon: Icons.dangerous,
                  label: 'Flood',
                  count: floodedEdges.length,
                  color: Colors.red,
                  percentage: edges.isEmpty ? 0 : (floodedEdges.length / edges.length * 100).round(),
                ),
              ],
            ),

            // Flooded edges list
            if (floodedEdges.isNotEmpty) ...[
              const SizedBox(height: 12),
              const Divider(),
              const SizedBox(height: 8),
              Text(
                '🌊 Flooded Routes:',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                ),
              ),
              const SizedBox(height: 8),
              ...floodedEdges.map((edge) => _FloodedEdgeItem(edge: edge)),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final int count;
  final Color color;
  final int percentage;

  const _StatusChip({
    required this.icon,
    required this.label,
    required this.count,
    required this.color,
    required this.percentage,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Text(
            '$label: $count',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _getDarkerColor(color),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '($percentage%)',
            style: TextStyle(
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getDarkerColor(Color color) {
    return Color.fromRGBO(
      (color.red * 0.7).round(),
      (color.green * 0.7).round(),
      (color.blue * 0.7).round(),
      1.0,
    );
  }
}

class _FloodedEdgeItem extends StatelessWidget {
  final GraphEdge edge;

  const _FloodedEdgeItem({required this.edge});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.red,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${edge.sourceId} → ${edge.targetId}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              _getEdgeTypeLabel(edge.edgeType),
              style: TextStyle(
                fontSize: 10,
                color: Colors.red[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getEdgeTypeLabel(EdgeType type) {
    switch (type) {
      case EdgeType.ROAD:
        return 'ROAD';
      case EdgeType.WATERWAY:
        return 'RIVER';
      case EdgeType.AIRWAY:
        return 'AIR';
    }
  }
}
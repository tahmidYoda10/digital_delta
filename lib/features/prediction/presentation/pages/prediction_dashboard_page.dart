import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/prediction_bloc.dart';
import '../bloc/prediction_event.dart';
import '../bloc/prediction_state.dart';

class PredictionDashboardPage extends StatelessWidget {
  const PredictionDashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ML Predictions'),
      ),
      body: BlocConsumer<PredictionBloc, PredictionState>(
        listener: (context, state) {
          if (state is PredictionError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red,
              ),
            );
          }
        },
        builder: (context, state) {
          if (state is PredictionLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is PredictionReady) {
            return _buildReadyView(context, state.modelInfo);
          }

          if (state is PredictionSimulationRunning) {
            return _buildSimulationView(context, state.edgeCount);
          }

          if (state is PredictionResultsAvailable) {
            return _buildResultsView(context, state.predictions);
          }

          return const Center(child: Text('Initialize ML'));
        },
      ),
    );
  }

  Widget _buildReadyView(BuildContext context, Map<String, dynamic> modelInfo) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Model Info',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const Divider(),
                Text('Version: ${modelInfo['version']}'),
                Text('Accuracy: ${(modelInfo['metrics']['accuracy'] * 100).toStringAsFixed(1)}%'),
                Text('F1 Score: ${(modelInfo['metrics']['f1_score'] * 100).toStringAsFixed(1)}%'),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () {
            context.read<PredictionBloc>().add(
              PredictionStartSimulationRequested(['E1', 'E2', 'E3', 'E4', 'E5']),
            );
          },
          icon: const Icon(Icons.play_arrow),
          label: const Text('Start Rainfall Simulation'),
        ),
      ],
    );
  }

  Widget _buildSimulationView(BuildContext context, int edgeCount) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 24),
          Text('Simulating rainfall for $edgeCount edges...'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              context.read<PredictionBloc>().add(PredictionStopSimulationRequested());
            },
            child: const Text('Stop Simulation'),
          ),
        ],
      ),
    );
  }

  Widget _buildResultsView(BuildContext context, List predictions) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: predictions.length,
      itemBuilder: (context, index) {
        final prediction = predictions[index];
        return Card(
          child: ListTile(
            leading: Icon(
              Icons.warning,
              color: _getRiskColor(prediction.probability),
            ),
            title: Text('Edge: ${prediction.edgeId}'),
            subtitle: Text('Risk: ${prediction.getRiskLevel()}'),
            trailing: Text(
              '${(prediction.probability * 100).toStringAsFixed(0)}%',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _getRiskColor(prediction.probability),
              ),
            ),
          ),
        );
      },
    );
  }

  Color _getRiskColor(double probability) {
    if (probability < 0.3) return Colors.green;
    if (probability < 0.7) return Colors.orange;
    return Colors.red;
  }
}
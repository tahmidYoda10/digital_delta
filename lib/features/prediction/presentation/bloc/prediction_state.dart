import 'package:equatable/equatable.dart';
import '../../../../core/ml/models/prediction_result.dart';

abstract class PredictionState extends Equatable {
  const PredictionState();

  @override
  List<Object?> get props => [];
}

class PredictionInitial extends PredictionState {}

class PredictionLoading extends PredictionState {}

class PredictionReady extends PredictionState {
  final Map<String, dynamic> modelInfo;

  const PredictionReady(this.modelInfo);

  @override
  List<Object?> get props => [modelInfo];
}

class PredictionSimulationRunning extends PredictionState {
  final int edgeCount;

  const PredictionSimulationRunning(this.edgeCount);

  @override
  List<Object?> get props => [edgeCount];
}

class PredictionResultsAvailable extends PredictionState {
  final List<PredictionResult> predictions;
  final DateTime updatedAt;

  const PredictionResultsAvailable({
    required this.predictions,
    required this.updatedAt,
  });

  @override
  List<Object?> get props => [predictions, updatedAt];
}

class PredictionError extends PredictionState {
  final String message;

  const PredictionError(this.message);

  @override
  List<Object?> get props => [message];
}
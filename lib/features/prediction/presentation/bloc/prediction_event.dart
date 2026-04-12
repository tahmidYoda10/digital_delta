import 'package:equatable/equatable.dart';

abstract class PredictionEvent extends Equatable {
  const PredictionEvent();

  @override
  List<Object?> get props => [];
}

class PredictionInitializeRequested extends PredictionEvent {}

class PredictionStartSimulationRequested extends PredictionEvent {
  final List<String> edgeIds;

  const PredictionStartSimulationRequested(this.edgeIds);

  @override
  List<Object?> get props => [edgeIds];
}

class PredictionStopSimulationRequested extends PredictionEvent {}

class PredictionRunRequested extends PredictionEvent {}

class PredictionLoadModelRequested extends PredictionEvent {
  final Map<String, dynamic> modelData;

  const PredictionLoadModelRequested(this.modelData);

  @override
  List<Object?> get props => [modelData];
}
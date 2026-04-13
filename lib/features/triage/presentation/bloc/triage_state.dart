import 'package:equatable/equatable.dart';
import '../../domain/models/triage_decision.dart';

abstract class TriageState extends Equatable {
  const TriageState();

  @override
  List<Object?> get props => [];
}

class TriageInitial extends TriageState {}

class TriageMonitoring extends TriageState {
  final String deliveryId;
  final Map<String, dynamic> status;

  const TriageMonitoring({
    required this.deliveryId,
    required this.status,
  });

  @override
  List<Object?> get props => [deliveryId, status];
}

class TriageDecisionMade extends TriageState {
  final TriageDecision decision;
  final DateTime timestamp;

  const TriageDecisionMade({
    required this.decision,
    required this.timestamp,
  });

  @override
  List<Object?> get props => [decision, timestamp];
}

class TriageError extends TriageState {
  final String message;

  const TriageError(this.message);

  @override
  List<Object?> get props => [message];
}
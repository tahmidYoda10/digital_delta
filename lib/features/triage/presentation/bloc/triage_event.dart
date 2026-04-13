import 'package:equatable/equatable.dart';
import '../../../../core/delivery/models/delivery_model.dart';
import '../../../../core/routing/models/route.dart';
import '../../domain/models/triage_decision.dart';

abstract class TriageEvent extends Equatable {
  const TriageEvent();

  @override
  List<Object?> get props => [];
}

class TriageRegisterDelivery extends TriageEvent {
  final DeliveryModel delivery;
  final Route route;

  const TriageRegisterDelivery({
    required this.delivery,
    required this.route,
  });

  @override
  List<Object?> get props => [delivery, route];
}

class TriageUpdateRoute extends TriageEvent {
  final String deliveryId;
  final Route newRoute;
  final Route? oldRoute;

  const TriageUpdateRoute({
    required this.deliveryId,
    required this.newRoute,
    this.oldRoute,
  });

  @override
  List<Object?> get props => [deliveryId, newRoute, oldRoute];
}

class TriageCheckStatus extends TriageEvent {
  final String deliveryId;

  const TriageCheckStatus(this.deliveryId);

  @override
  List<Object?> get props => [deliveryId];
}

class TriageDecisionReceived extends TriageEvent {
  final TriageDecision decision;

  const TriageDecisionReceived(this.decision);

  @override
  List<Object?> get props => [decision];
}
import 'dart:async';
import '../utils/app_logger.dart';
import '../delivery/models/delivery_model.dart';
import '../delivery/models/cargo_item.dart';
import '../routing/models/route.dart';
import '../../features/triage/domain/models/triage_decision.dart';
import '../../features/triage/domain/usecases/evaluate_preemption_usecase.dart';
import '../crypto/audit_logger.dart';

/// M6 - Triage Engine: Autonomous cargo prioritization
class TriageEngine {
  final EvaluatePreemptionUseCase _evaluateUseCase = EvaluatePreemptionUseCase();
  final AuditLogger _auditLogger = AuditLogger();

  final StreamController<TriageDecision> _decisionController = StreamController.broadcast();

  // Active deliveries being monitored
  final Map<String, DeliveryModel> _activeDeliveries = {};
  final Map<String, Route> _activeRoutes = {};

  // Thresholds
  static const double slowdownThreshold = 0.30; // 30% (M6.2)
  static const double criticalSLABuffer = 0.20; // 20% remaining time is critical

  /// Stream of triage decisions
  Stream<TriageDecision> get decisions => _decisionController.stream;

  /// Register delivery for monitoring
  void registerDelivery(DeliveryModel delivery, Route route) {
    _activeDeliveries[delivery.id] = delivery;
    _activeRoutes[delivery.id] = route;

    AppLogger.info('🚚 Registered delivery ${delivery.id} with ${delivery.cargo.length} items');

    // Initial SLA check
    _checkSLAStatus(delivery, route);
  }

  /// Update route for delivery (called when route changes)
  Future<void> onRouteChanged({
    required String deliveryId,
    required Route newRoute,
    required Route? oldRoute,
  }) async {
    if (!_activeDeliveries.containsKey(deliveryId)) {
      AppLogger.warning('Delivery $deliveryId not registered');
      return;
    }

    final delivery = _activeDeliveries[deliveryId]!;
    _activeRoutes[deliveryId] = newRoute;

    // Calculate delay percentage
    double delayPercent = 0.0;
    if (oldRoute != null) {
      final oldTime = oldRoute.estimatedTime;
      final newTime = newRoute.estimatedTime;
      delayPercent = (newTime - oldTime) / oldTime;

      AppLogger.info('📊 Route changed: ${oldTime.toStringAsFixed(1)}min → ${newTime.toStringAsFixed(1)}min (${(delayPercent * 100).toStringAsFixed(0)}% change)');
    }

    // ✅ TRIGGER TRIAGE if delay > 30%
    if (delayPercent > slowdownThreshold) {
      await _triggerTriage(delivery, newRoute, delayPercent);
    }
  }

  /// Trigger triage evaluation
  Future<void> _triggerTriage(
      DeliveryModel delivery,
      Route route,
      double delayPercent,
      ) async {
    AppLogger.warning('⚖️ TRIAGE TRIGGERED: Delivery ${delivery.id} - Route delayed by ${(delayPercent * 100).toStringAsFixed(0)}%');

    // Evaluate decision
    final decision = _evaluateUseCase.evaluate(
      delivery: delivery,
      currentRoute: route,
      routeDelayPercent: delayPercent,
    );

    // Log to audit trail
    await _auditLogger.logAuthEvent(
      userId: delivery.driverId,
      eventType: AuthEventType.OTP_GENERATED, // Reuse enum (better: create TriageEventType)
      deviceId: delivery.deviceId,
      metadata: {
        'triage_action': decision.action.toString(),
        'reason': decision.reason,
        'delivery_id': delivery.id,
      },
    );

    // Broadcast decision
    _decisionController.add(decision);

    // Log decision
    AppLogger.info('✅ Triage decision: ${decision.action} - ${decision.reason}');
  }

  /// Check SLA status for all cargo
  void _checkSLAStatus(DeliveryModel delivery, Route route) {
    final now = DateTime.now();
    final eta = now.add(Duration(minutes: route.estimatedTime.round()));

    for (var cargo in delivery.cargo) {
      final remaining = cargo.slaDeadline.difference(now);
      final total = Duration(minutes: cargo.getSLAMinutes());
      final percentRemaining = remaining.inMinutes / total.inMinutes;

      if (eta.isAfter(cargo.slaDeadline)) {
        AppLogger.warning('🔴 SLA BREACH PREDICTED: ${cargo.name} (${cargo.priority}) - ETA: $eta, Deadline: ${cargo.slaDeadline}');
      } else if (percentRemaining < criticalSLABuffer) {
        AppLogger.warning('🟠 SLA AT RISK: ${cargo.name} - ${remaining.inMinutes} min remaining');
      } else {
        AppLogger.info('🟢 SLA OK: ${cargo.name} - ${remaining.inMinutes} min buffer');
      }
    }
  }

  /// Get delivery status
  Map<String, dynamic> getDeliveryStatus(String deliveryId) {
    final delivery = _activeDeliveries[deliveryId];
    final route = _activeRoutes[deliveryId];

    if (delivery == null || route == null) {
      return {'status': 'not_found'};
    }

    final now = DateTime.now();
    final eta = now.add(Duration(minutes: route.estimatedTime.round()));

    final cargoStatus = delivery.cargo.map((cargo) {
      final remaining = cargo.slaDeadline.difference(now);
      final willBreach = eta.isAfter(cargo.slaDeadline);

      return {
        'id': cargo.id,
        'name': cargo.name,
        'priority': cargo.priority.toString(),
        'sla_deadline': cargo.slaDeadline.toIso8601String(),
        'remaining_minutes': remaining.inMinutes,
        'will_breach': willBreach,
        'at_risk': cargo.isSLAAtRisk(),
      };
    }).toList();

    return {
      'delivery_id': deliveryId,
      'status': delivery.status.toString(),
      'eta': eta.toIso8601String(),
      'eta_minutes': route.estimatedTime,
      'cargo': cargoStatus,
      'highest_priority': delivery.getHighestPriority().toString(),
    };
  }

  /// Unregister delivery
  void unregisterDelivery(String deliveryId) {
    _activeDeliveries.remove(deliveryId);
    _activeRoutes.remove(deliveryId);
    AppLogger.info('✅ Delivery $deliveryId unregistered');
  }

  void dispose() {
    _decisionController.close();
  }
}
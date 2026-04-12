import '../../../../core/delivery/models/delivery_model.dart';
import '../../../../core/delivery/models/cargo_item.dart';
import '../../../../core/routing/models/route.dart';
import '../../../../core/utils/app_logger.dart';
import '../models/triage_decision.dart';

class EvaluatePreemptionUseCase {
  /// Evaluate if delivery needs preemption (M6.2 & M6.3)
  TriageDecision evaluate({
    required DeliveryModel delivery,
    required Route currentRoute,
    required double routeDelayPercent, // e.g., 0.3 = 30% slower
  }) {
    try {
      AppLogger.info('⚖️ Evaluating triage for delivery: ${delivery.id}');

      // Get highest priority cargo
      final highestPriority = delivery.getHighestPriority();

      // Calculate new ETA with delay
      final baseTime = currentRoute.estimatedTime;
      final delayedTime = baseTime * (1.0 + routeDelayPercent);
      final newETA = DateTime.now().add(Duration(minutes: delayedTime.round()));

      // Check for SLA breach prediction (M6.2)
      bool willBreachSLA = false;
      final criticalCargo = <CargoItem>[];

      for (var cargo in delivery.cargo) {
        if (newETA.isAfter(cargo.slaDeadline)) {
          willBreachSLA = true;
          if (cargo.priority == CargoPriority.P0_CRITICAL ||
              cargo.priority == CargoPriority.P1_HIGH) {
            criticalCargo.add(cargo);
          }
        }
      }

      // Decision logic (M6.3)
      if (willBreachSLA && criticalCargo.isNotEmpty) {
        // Check if we can drop low-priority cargo
        final lowPriorityCargo = delivery.cargo.where(
                (c) => c.priority == CargoPriority.P2_STANDARD ||
                c.priority == CargoPriority.P3_LOW
        ).toList();

        if (lowPriorityCargo.isNotEmpty) {
          return TriageDecision(
            deliveryId: delivery.id,
            action: TriageAction.PREEMPT,
            reason: 'SLA breach predicted for ${criticalCargo.length} critical items. Dropping ${lowPriorityCargo.length} low-priority items.',
            decidedAt: DateTime.now(),
            metadata: {
              'dropped_items': lowPriorityCargo.map((c) => c.id).toList(),
              'critical_items': criticalCargo.map((c) => c.id).toList(),
              'delay_percent': routeDelayPercent,
              'predicted_eta': newETA.toIso8601String(),
            },
          );
        } else {
          // All cargo is high priority, reroute
          return TriageDecision(
            deliveryId: delivery.id,
            action: TriageAction.REROUTE,
            reason: 'All cargo is high priority. Requesting faster route.',
            decidedAt: DateTime.now(),
            metadata: {
              'delay_percent': routeDelayPercent,
            },
          );
        }
      } else if (routeDelayPercent > 0.5) {
        // Significant delay but no SLA breach
        return TriageDecision(
          deliveryId: delivery.id,
          action: TriageAction.REROUTE,
          reason: 'Route delayed by ${(routeDelayPercent * 100).toStringAsFixed(0)}%. Seeking alternate route.',
          decidedAt: DateTime.now(),
        );
      } else {
        return TriageDecision(
          deliveryId: delivery.id,
          action: TriageAction.CONTINUE,
          reason: 'No SLA breach predicted. Continue current route.',
          decidedAt: DateTime.now(),
        );
      }

    } catch (e, stack) {
      AppLogger.error('Triage evaluation failed', e, stack);
      return TriageDecision(
        deliveryId: delivery.id,
        action: TriageAction.CONTINUE,
        reason: 'Evaluation error: ${e.toString()}',
        decidedAt: DateTime.now(),
      );
    }
  }
}
import 'package:flutter/foundation.dart';
import '../../habit/domain/entities/habit.dart';
import '../../habit/domain/repositories/habit_repository.dart';
import '../domain/models/daily_health_summary.dart';
import '../domain/models/habit_automation_rule.dart';
import '../domain/models/health_metric_type.dart';
import 'health_sync_local_storage.dart';

class HabitAutomationResult {
  final String habitId;
  final String habitTitle;
  final HealthMetricType metricType;
  final double currentValue;
  final double targetValue;
  final bool wasAutoCompleted;
  final double updatedProgress;

  const HabitAutomationResult({
    required this.habitId,
    required this.habitTitle,
    required this.metricType,
    required this.currentValue,
    required this.targetValue,
    required this.wasAutoCompleted,
    required this.updatedProgress,
  });
}

class HabitAutomationEngine {
  final HabitRepository _habitRepository;
  final HealthSyncLocalStorage _localStorage;

  HabitAutomationEngine({
    required HabitRepository habitRepository,
    HealthSyncLocalStorage? localStorage,
  })  : _habitRepository = habitRepository,
        _localStorage = localStorage ?? HealthSyncLocalStorage();

  /// Evaluates all active habits against the latest DailyHealthSummary.
  /// Updates habit progress and auto-completes habits when health targets are reached.
  Future<List<HabitAutomationResult>> evaluateAndSyncHabits({
    required DailyHealthSummary summary,
  }) async {
    final results = <HabitAutomationResult>[];

    try {
      final habits = await _habitRepository.getHabits();
      final List<HabitAutomationRule> rules = _localStorage.getHabitRules();

      for (final habit in habits) {
        // Find explicit rule or determine dynamic heuristic
        final explicitRule = rules
            .where((r) => r.habitId == habit.id && r.isEnabled)
            .firstOrNull;

        final metricType = explicitRule?.metricType ?? _detectMetricTypeForHabit(habit);
        if (metricType == null) continue;

        final target = explicitRule?.targetThreshold ?? habit.targetProgress;
        final currentHealthValue = _extractHealthValue(summary, metricType);

        if (currentHealthValue <= 0) continue;

        // Check if user manually uncompleted this habit today
        final overrideKey = 'manual_override_${habit.id}_${summary.date}';
        final hasManualOverride = _localStorage.getChangesToken(overrideKey) == 'uncompleted';
        if (hasManualOverride) {
          continue;
        }

        // Calculate progress
        final clampedProgress = target > 0 ? (currentHealthValue / target) * target : 1.0;
        final isGoalMet = currentHealthValue >= target;

        bool justCompleted = false;

        // Update progress if changed
        if (habit.currentProgress != currentHealthValue) {
          await _habitRepository.updateHabitProgress(
            habit.id,
            currentHealthValue > target ? target : currentHealthValue,
          );
        }

        // Auto-complete if goal met and not yet completed
        if (isGoalMet && !habit.isCompleted) {
          await _habitRepository.toggleHabitCompletion(habit.id);
          justCompleted = true;

          // Record audit log
          if (explicitRule != null) {
            final updatedRule = explicitRule.copyWith(lastTriggeredAt: DateTime.now());
            await _localStorage.saveHabitRule(updatedRule);
          }
        }

        results.add(
          HabitAutomationResult(
            habitId: habit.id,
            habitTitle: habit.title,
            metricType: metricType,
            currentValue: currentHealthValue,
            targetValue: target,
            wasAutoCompleted: justCompleted,
            updatedProgress: clampedProgress,
          ),
        );
      }
    } catch (e) {
      debugPrint('HabitAutomationEngine.evaluateAndSyncHabits error: $e');
    }

    return results;
  }

  /// Extracts the corresponding numerical value from the daily summary
  static double _extractHealthValue(DailyHealthSummary summary, HealthMetricType type) {
    switch (type) {
      case HealthMetricType.steps:
        return summary.steps.toDouble();
      case HealthMetricType.distance:
        return summary.distanceKm;
      case HealthMetricType.activeCalories:
        return summary.activeCalories;
      case HealthMetricType.totalCalories:
        return summary.totalCalories;
      case HealthMetricType.heartRate:
        return summary.avgHeartRate ?? 0.0;
      case HealthMetricType.restingHeartRate:
        return summary.restingHeartRate ?? 0.0;
      case HealthMetricType.sleep:
        // Returns minutes or hours depending on magnitude
        return summary.sleepDurationMinutes.toDouble();
      case HealthMetricType.workout:
        return summary.exerciseMinutes.toDouble();
      default:
        return 0.0;
    }
  }

  /// Heuristically identifies health metrics for standard habits if no explicit rule is configured
  static HealthMetricType? _detectMetricTypeForHabit(Habit habit) {
    final title = habit.title.toLowerCase();
    final unit = habit.unit.toLowerCase();

    if (title.contains('step') || unit.contains('step') || title.contains('walk')) {
      return HealthMetricType.steps;
    }
    if (title.contains('sleep') || unit.contains('hour') || title.contains('rest')) {
      return HealthMetricType.sleep;
    }
    if (title.contains('workout') ||
        title.contains('gym') ||
        title.contains('run') ||
        title.contains('exercise') ||
        title.contains('yoga') ||
        unit.contains('min')) {
      return HealthMetricType.workout;
    }
    if (title.contains('calorie') || title.contains('burn') || unit.contains('kcal')) {
      return HealthMetricType.activeCalories;
    }
    if (title.contains('distance') || unit.contains('km') || unit.contains('mile')) {
      return HealthMetricType.distance;
    }
    return null;
  }
}

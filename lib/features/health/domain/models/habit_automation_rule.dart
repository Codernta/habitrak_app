import 'package:equatable/equatable.dart';
import 'health_metric_type.dart';

class HabitAutomationRule extends Equatable {
  final String id;
  final String habitId;
  final HealthMetricType metricType;
  final double targetThreshold;
  final bool isEnabled;
  final bool autoCompleteHabit;
  final DateTime? lastTriggeredAt;

  const HabitAutomationRule({
    required this.id,
    required this.habitId,
    required this.metricType,
    required this.targetThreshold,
    this.isEnabled = true,
    this.autoCompleteHabit = true,
    this.lastTriggeredAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'habitId': habitId,
      'metricType': metricType.name,
      'targetThreshold': targetThreshold,
      'isEnabled': isEnabled,
      'autoCompleteHabit': autoCompleteHabit,
      'lastTriggeredAt': lastTriggeredAt?.toIso8601String(),
    };
  }

  factory HabitAutomationRule.fromMap(Map<dynamic, dynamic> map) {
    return HabitAutomationRule(
      id: map['id'] as String,
      habitId: map['habitId'] as String,
      metricType: HealthMetricType.values.byName(map['metricType'] as String),
      targetThreshold: (map['targetThreshold'] as num).toDouble(),
      isEnabled: map['isEnabled'] as bool? ?? true,
      autoCompleteHabit: map['autoCompleteHabit'] as bool? ?? true,
      lastTriggeredAt: map['lastTriggeredAt'] != null
          ? DateTime.parse(map['lastTriggeredAt'] as String)
          : null,
    );
  }

  HabitAutomationRule copyWith({
    String? id,
    String? habitId,
    HealthMetricType? metricType,
    double? targetThreshold,
    bool? isEnabled,
    bool? autoCompleteHabit,
    DateTime? lastTriggeredAt,
  }) {
    return HabitAutomationRule(
      id: id ?? this.id,
      habitId: habitId ?? this.habitId,
      metricType: metricType ?? this.metricType,
      targetThreshold: targetThreshold ?? this.targetThreshold,
      isEnabled: isEnabled ?? this.isEnabled,
      autoCompleteHabit: autoCompleteHabit ?? this.autoCompleteHabit,
      lastTriggeredAt: lastTriggeredAt ?? this.lastTriggeredAt,
    );
  }

  @override
  List<Object?> get props => [
        id,
        habitId,
        metricType,
        targetThreshold,
        isEnabled,
        autoCompleteHabit,
        lastTriggeredAt,
      ];
}

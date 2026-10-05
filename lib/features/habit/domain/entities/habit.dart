import 'package:equatable/equatable.dart';
import 'package:hive/hive.dart';

part 'habit.g.dart';

@HiveType(typeId: 1)
enum HabitCategory {
  @HiveField(0)
  mindfulness,
  @HiveField(1)
  health,
  @HiveField(2)
  growth
}

extension HabitCategoryExtension on HabitCategory {
  String get displayName {
    switch (this) {
      case HabitCategory.mindfulness:
        return 'Mindfulness';
      case HabitCategory.health:
        return 'Health';
      case HabitCategory.growth:
        return 'Growth';
    }
  }
}

@HiveType(typeId: 0)
class Habit extends Equatable {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String title;
  @HiveField(2)
  final HabitCategory category;
  @HiveField(3)
  final double targetProgress;
  @HiveField(4)
  final double currentProgress;
  @HiveField(5)
  final String unit;
  @HiveField(6)
  final bool isCompleted;
  @HiveField(7)
  final int streak;
  @HiveField(8)
  final String? completedAt;
  @HiveField(9)
  final String? scheduledTime;

  const Habit({
    required this.id,
    required this.title,
    required this.category,
    this.targetProgress = 1.0,
    this.currentProgress = 0.0,
    this.unit = '',
    this.isCompleted = false,
    this.streak = 0,
    this.completedAt,
    this.scheduledTime,
  });

  Habit copyWith({
    String? id,
    String? title,
    HabitCategory? category,
    double? targetProgress,
    double? currentProgress,
    String? unit,
    bool? isCompleted,
    int? streak,
    String? completedAt,
    String? scheduledTime,
  }) {
    return Habit(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      targetProgress: targetProgress ?? this.targetProgress,
      currentProgress: currentProgress ?? this.currentProgress,
      unit: unit ?? this.unit,
      isCompleted: isCompleted ?? this.isCompleted,
      streak: streak ?? this.streak,
      completedAt: completedAt ?? this.completedAt,
      scheduledTime: scheduledTime ?? this.scheduledTime,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        category,
        targetProgress,
        currentProgress,
        unit,
        isCompleted,
        streak,
        completedAt,
        scheduledTime,
      ];
}

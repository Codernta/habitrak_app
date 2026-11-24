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
  growth,
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
    bool clearCompletedAt = false,
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
      completedAt: clearCompletedAt ? null : (completedAt ?? this.completedAt),
      scheduledTime: scheduledTime ?? this.scheduledTime,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'category': category.name,
      'targetProgress': targetProgress,
      'currentProgress': currentProgress,
      'unit': unit,
      'isCompleted': isCompleted,
      'streak': streak,
      'completedAt': completedAt,
      'scheduledTime': scheduledTime,
    };
  }

  factory Habit.fromMap(Map<String, dynamic> map) {
    HabitCategory cat = HabitCategory.mindfulness;
    final catStr = map['category'] as String?;
    if (catStr != null) {
      cat = HabitCategory.values.firstWhere(
        (c) => c.name == catStr,
        orElse: () => HabitCategory.mindfulness,
      );
    }
    return Habit(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      category: cat,
      targetProgress: (map['targetProgress'] as num?)?.toDouble() ?? 1.0,
      currentProgress: (map['currentProgress'] as num?)?.toDouble() ?? 0.0,
      unit: map['unit'] as String? ?? '',
      isCompleted: map['isCompleted'] as bool? ?? false,
      streak: (map['streak'] as num?)?.toInt() ?? 0,
      completedAt: map['completedAt'] as String?,
      scheduledTime: map['scheduledTime'] as String?,
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

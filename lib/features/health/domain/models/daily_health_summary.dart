import 'package:equatable/equatable.dart';

class DailyHealthSummary extends Equatable {
  final String date; // YYYY-MM-DD
  final int steps;
  final double distanceMeters;
  final double activeCalories;
  final double totalCalories;
  final double? avgHeartRate;
  final double? minHeartRate;
  final double? maxHeartRate;
  final double? restingHeartRate;
  final int sleepDurationMinutes;
  final int deepSleepMinutes;
  final int remSleepMinutes;
  final int lightSleepMinutes;
  final int awakeMinutes;
  final int? sleepEfficiencyPercentage;
  final int exerciseMinutes;
  final int workoutCount;
  final DateTime lastSyncedAt;
  final bool isCloudSynced;

  const DailyHealthSummary({
    required this.date,
    this.steps = 0,
    this.distanceMeters = 0.0,
    this.activeCalories = 0.0,
    this.totalCalories = 0.0,
    this.avgHeartRate,
    this.minHeartRate,
    this.maxHeartRate,
    this.restingHeartRate,
    this.sleepDurationMinutes = 0,
    this.deepSleepMinutes = 0,
    this.remSleepMinutes = 0,
    this.lightSleepMinutes = 0,
    this.awakeMinutes = 0,
    this.sleepEfficiencyPercentage,
    this.exerciseMinutes = 0,
    this.workoutCount = 0,
    required this.lastSyncedAt,
    this.isCloudSynced = false,
  });

  double get distanceKm => (distanceMeters / 1000.0 * 10).round() / 10.0;

  double get sleepHours => (sleepDurationMinutes / 60.0 * 10).round() / 10.0;

  DailyHealthSummary copyWith({
    String? date,
    int? steps,
    double? distanceMeters,
    double? activeCalories,
    double? totalCalories,
    double? avgHeartRate,
    double? minHeartRate,
    double? maxHeartRate,
    double? restingHeartRate,
    int? sleepDurationMinutes,
    int? deepSleepMinutes,
    int? remSleepMinutes,
    int? lightSleepMinutes,
    int? awakeMinutes,
    int? sleepEfficiencyPercentage,
    int? exerciseMinutes,
    int? workoutCount,
    DateTime? lastSyncedAt,
    bool? isCloudSynced,
  }) {
    return DailyHealthSummary(
      date: date ?? this.date,
      steps: steps ?? this.steps,
      distanceMeters: distanceMeters ?? this.distanceMeters,
      activeCalories: activeCalories ?? this.activeCalories,
      totalCalories: totalCalories ?? this.totalCalories,
      avgHeartRate: avgHeartRate ?? this.avgHeartRate,
      minHeartRate: minHeartRate ?? this.minHeartRate,
      maxHeartRate: maxHeartRate ?? this.maxHeartRate,
      restingHeartRate: restingHeartRate ?? this.restingHeartRate,
      sleepDurationMinutes: sleepDurationMinutes ?? this.sleepDurationMinutes,
      deepSleepMinutes: deepSleepMinutes ?? this.deepSleepMinutes,
      remSleepMinutes: remSleepMinutes ?? this.remSleepMinutes,
      lightSleepMinutes: lightSleepMinutes ?? this.lightSleepMinutes,
      awakeMinutes: awakeMinutes ?? this.awakeMinutes,
      sleepEfficiencyPercentage:
          sleepEfficiencyPercentage ?? this.sleepEfficiencyPercentage,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
      workoutCount: workoutCount ?? this.workoutCount,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isCloudSynced: isCloudSynced ?? this.isCloudSynced,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'steps': steps,
      'distanceMeters': distanceMeters,
      'activeCalories': activeCalories,
      'totalCalories': totalCalories,
      'avgHeartRate': avgHeartRate,
      'minHeartRate': minHeartRate,
      'maxHeartRate': maxHeartRate,
      'restingHeartRate': restingHeartRate,
      'sleepDurationMinutes': sleepDurationMinutes,
      'deepSleepMinutes': deepSleepMinutes,
      'remSleepMinutes': remSleepMinutes,
      'lightSleepMinutes': lightSleepMinutes,
      'awakeMinutes': awakeMinutes,
      'sleepEfficiencyPercentage': sleepEfficiencyPercentage,
      'exerciseMinutes': exerciseMinutes,
      'workoutCount': workoutCount,
      'lastSyncedAt': lastSyncedAt.toIso8601String(),
      'isCloudSynced': isCloudSynced,
    };
  }

  factory DailyHealthSummary.fromMap(Map<dynamic, dynamic> map) {
    return DailyHealthSummary(
      date: map['date'] as String,
      steps: (map['steps'] as num?)?.toInt() ?? 0,
      distanceMeters: (map['distanceMeters'] as num?)?.toDouble() ?? 0.0,
      activeCalories: (map['activeCalories'] as num?)?.toDouble() ?? 0.0,
      totalCalories: (map['totalCalories'] as num?)?.toDouble() ?? 0.0,
      avgHeartRate: (map['avgHeartRate'] as num?)?.toDouble(),
      minHeartRate: (map['minHeartRate'] as num?)?.toDouble(),
      maxHeartRate: (map['maxHeartRate'] as num?)?.toDouble(),
      restingHeartRate: (map['restingHeartRate'] as num?)?.toDouble(),
      sleepDurationMinutes:
          (map['sleepDurationMinutes'] as num?)?.toInt() ?? 0,
      deepSleepMinutes: (map['deepSleepMinutes'] as num?)?.toInt() ?? 0,
      remSleepMinutes: (map['remSleepMinutes'] as num?)?.toInt() ?? 0,
      lightSleepMinutes: (map['lightSleepMinutes'] as num?)?.toInt() ?? 0,
      awakeMinutes: (map['awakeMinutes'] as num?)?.toInt() ?? 0,
      sleepEfficiencyPercentage:
          (map['sleepEfficiencyPercentage'] as num?)?.toInt(),
      exerciseMinutes: (map['exerciseMinutes'] as num?)?.toInt() ?? 0,
      workoutCount: (map['workoutCount'] as num?)?.toInt() ?? 0,
      lastSyncedAt: map['lastSyncedAt'] != null
          ? DateTime.parse(map['lastSyncedAt'] as String)
          : DateTime.now(),
      isCloudSynced: map['isCloudSynced'] as bool? ?? false,
    );
  }

  @override
  List<Object?> get props => [
        date,
        steps,
        distanceMeters,
        activeCalories,
        totalCalories,
        avgHeartRate,
        minHeartRate,
        maxHeartRate,
        restingHeartRate,
        sleepDurationMinutes,
        deepSleepMinutes,
        remSleepMinutes,
        lightSleepMinutes,
        awakeMinutes,
        sleepEfficiencyPercentage,
        exerciseMinutes,
        workoutCount,
        lastSyncedAt,
        isCloudSynced,
      ];
}

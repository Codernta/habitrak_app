import 'dart:math';
import '../domain/models/daily_health_summary.dart';
import '../domain/models/health_metric_type.dart';
import '../domain/models/normalized_health_record.dart';

class HealthAggregationService {
  /// Aggregates a list of deduplicated health records for a specific date into a DailyHealthSummary.
  DailyHealthSummary aggregateDailyRecords({
    required String date,
    required List<NormalizedHealthRecord> records,
    DailyHealthSummary? existingSummary,
  }) {
    if (records.isEmpty) {
      return existingSummary ??
          DailyHealthSummary(
            date: date,
            lastSyncedAt: DateTime.now(),
          );
    }

    int steps = 0;
    double distanceMeters = 0.0;
    double activeCalories = 0.0;
    double totalCalories = 0.0;

    final List<double> hrSamples = [];
    double? restingHr;

    int sleepMinutes = 0;
    int deepSleepMinutes = 0;
    int remSleepMinutes = 0;
    int lightSleepMinutes = 0;
    int awakeMinutes = 0;

    int exerciseMinutes = 0;
    int workoutCount = 0;

    for (final record in records) {
      switch (record.metricType) {
        case HealthMetricType.steps:
          steps += record.value.toInt();
          break;
        case HealthMetricType.distance:
          // Check unit: if km convert to meters
          if (record.unit.toLowerCase() == 'km') {
            distanceMeters += record.value * 1000.0;
          } else {
            distanceMeters += record.value;
          }
          break;
        case HealthMetricType.activeCalories:
          activeCalories += record.value;
          break;
        case HealthMetricType.totalCalories:
          totalCalories += record.value;
          break;
        case HealthMetricType.heartRate:
          hrSamples.add(record.value);
          break;
        case HealthMetricType.restingHeartRate:
          // Use latest or lowest recorded resting HR
          restingHr = restingHr != null ? min(restingHr, record.value) : record.value;
          break;
        case HealthMetricType.sleep:
          // Sleep duration in minutes from interval or value
          final durationMins = record.endTime.difference(record.startTime).inMinutes;
          final mins = durationMins > 0 ? durationMins : record.value.toInt();
          
          final sourceLower = record.sourceApp.toLowerCase();
          if (sourceLower.contains('deep') || record.unit.contains('deep')) {
            deepSleepMinutes += mins;
            sleepMinutes += mins;
          } else if (sourceLower.contains('rem') || record.unit.contains('rem')) {
            remSleepMinutes += mins;
            sleepMinutes += mins;
          } else if (sourceLower.contains('light') || record.unit.contains('light')) {
            lightSleepMinutes += mins;
            sleepMinutes += mins;
          } else if (sourceLower.contains('awake') || record.unit.contains('awake')) {
            awakeMinutes += mins;
          } else {
            // General asleep session
            sleepMinutes += mins;
          }
          break;
        case HealthMetricType.workout:
          workoutCount++;
          final workoutMins = record.endTime.difference(record.startTime).inMinutes;
          exerciseMinutes += workoutMins > 0 ? workoutMins : record.value.toInt();
          break;
        default:
          break;
      }
    }

    // Calculate HR stats
    double? avgHr;
    double? minHr;
    double? maxHr;
    if (hrSamples.isNotEmpty) {
      avgHr = (hrSamples.reduce((a, b) => a + b) / hrSamples.length * 10).round() / 10.0;
      minHr = hrSamples.reduce(min);
      maxHr = hrSamples.reduce(max);
    } else if (existingSummary != null) {
      avgHr = existingSummary.avgHeartRate;
      minHr = existingSummary.minHeartRate;
      maxHr = existingSummary.maxHeartRate;
    }

    if (restingHr == null && existingSummary != null) {
      restingHr = existingSummary.restingHeartRate;
    }

    // Calculate Sleep Efficiency
    int? sleepEfficiency;
    final totalInBed = sleepMinutes + awakeMinutes;
    if (totalInBed > 0 && sleepMinutes > 0) {
      sleepEfficiency = ((sleepMinutes / totalInBed) * 100).clamp(0, 100).round();
    } else if (existingSummary?.sleepEfficiencyPercentage != null) {
      sleepEfficiency = existingSummary!.sleepEfficiencyPercentage;
    }

    return DailyHealthSummary(
      date: date,
      steps: max(steps, existingSummary?.steps ?? 0),
      distanceMeters: max(distanceMeters, existingSummary?.distanceMeters ?? 0.0),
      activeCalories: max(activeCalories, existingSummary?.activeCalories ?? 0.0),
      totalCalories: max(totalCalories, existingSummary?.totalCalories ?? 0.0),
      avgHeartRate: avgHr,
      minHeartRate: minHr,
      maxHeartRate: maxHr,
      restingHeartRate: restingHr,
      sleepDurationMinutes: max(sleepMinutes, existingSummary?.sleepDurationMinutes ?? 0),
      deepSleepMinutes: max(deepSleepMinutes, existingSummary?.deepSleepMinutes ?? 0),
      remSleepMinutes: max(remSleepMinutes, existingSummary?.remSleepMinutes ?? 0),
      lightSleepMinutes: max(lightSleepMinutes, existingSummary?.lightSleepMinutes ?? 0),
      awakeMinutes: max(awakeMinutes, existingSummary?.awakeMinutes ?? 0),
      sleepEfficiencyPercentage: sleepEfficiency,
      exerciseMinutes: max(exerciseMinutes, existingSummary?.exerciseMinutes ?? 0),
      workoutCount: max(workoutCount, existingSummary?.workoutCount ?? 0),
      lastSyncedAt: DateTime.now(),
      isCloudSynced: false,
    );
  }
}

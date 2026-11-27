import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import '../domain/models/daily_health_summary.dart';
import '../domain/models/health_metric_type.dart';
import '../domain/models/normalized_health_record.dart';
import 'deduplication_engine.dart';
import 'health_aggregation_service.dart';
import 'health_sync_local_storage.dart';

class HealthDataRepository {
  final Health _health;
  final DeduplicationEngine _deduplicationEngine;
  final HealthAggregationService _aggregationService;
  final HealthSyncLocalStorage _localStorage;

  HealthDataRepository({
    Health? health,
    DeduplicationEngine? deduplicationEngine,
    HealthAggregationService? aggregationService,
    HealthSyncLocalStorage? localStorage,
  })  : _health = health ?? Health(),
        _deduplicationEngine = deduplicationEngine ?? DeduplicationEngine(),
        _aggregationService = aggregationService ?? HealthAggregationService(),
        _localStorage = localStorage ?? HealthSyncLocalStorage();

  /// Fetches raw health points for a date range, merges any direct BLE/IoT records,
  /// normalizes them, deduplicates, and aggregates into DailyHealthSummary.
  Future<DailyHealthSummary> syncDailyHealthData({
    required DateTime date,
    List<NormalizedHealthRecord> externalRecords = const [],
  }) async {
    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
    final dateKey = _formatDateKey(date);

    final existingSummary = _localStorage.getDailySummary(dateKey);

    try {
      final typesToFetch = [
        HealthDataType.STEPS,
        HealthDataType.HEART_RATE,
        HealthDataType.RESTING_HEART_RATE,
        HealthDataType.ACTIVE_ENERGY_BURNED,
        HealthDataType.TOTAL_CALORIES_BURNED,
        HealthDataType.DISTANCE_WALKING_RUNNING,
        HealthDataType.WORKOUT,
        HealthDataType.SLEEP_SESSION,
        HealthDataType.SLEEP_ASLEEP,
        HealthDataType.SLEEP_DEEP,
        HealthDataType.SLEEP_LIGHT,
        HealthDataType.SLEEP_REM,
        HealthDataType.SLEEP_AWAKE,
      ];

      final normalizedRecords = <NormalizedHealthRecord>[
        ...externalRecords.where((r) => r.recordingDate == dateKey),
      ];

      try {
        // Retrieve points from HealthKit or Health Connect
        final points = await _health.getHealthDataFromTypes(
          types: typesToFetch,
          startTime: startOfDay,
          endTime: endOfDay,
        );

        for (final point in points) {
          final metricType = _mapHealthDataTypeToMetricType(point.type);
          if (metricType == null) continue;

          double numVal = 0.0;
          final rawVal = point.value;
          if (rawVal is NumericHealthValue) {
            numVal = rawVal.numericValue.toDouble();
          } else if (rawVal is WorkoutHealthValue) {
            numVal = point.dateTo.difference(point.dateFrom).inMinutes.toDouble();
          }

          final sourceApp = point.sourceName.isNotEmpty ? point.sourceName : 'Health';
          final recordId = DeduplicationEngine.generateRecordId(
            sourceApp: sourceApp,
            metricType: metricType,
            startTime: point.dateFrom,
            endTime: point.dateTo,
            value: numVal,
          );

          normalizedRecords.add(
            NormalizedHealthRecord(
              id: recordId,
              metricType: metricType,
              value: numVal,
              unit: point.unit.name,
              startTime: point.dateFrom,
              endTime: point.dateTo,
              sourceApp: sourceApp,
              sourceDevice: point.sourceId,
              platform: Platform.isIOS ? 'ios' : 'android',
              recordingDate: dateKey,
              syncedAt: DateTime.now(),
            ),
          );
        }
      } catch (e) {
        debugPrint('HealthDataRepository OS health query skipped/failed: $e');
      }

      // Deduplicate overlapping records from multiple devices/companion apps
      final deduplicated = _deduplicationEngine.deduplicate(normalizedRecords);

      // Aggregate into DailyHealthSummary
      final summary = _aggregationService.aggregateDailyRecords(
        date: dateKey,
        records: deduplicated,
        existingSummary: existingSummary,
      );

      // Persist in local storage
      await _localStorage.saveDailySummary(summary);
      await _localStorage.saveLastSyncTimestamp(DateTime.now());

      return summary;
    } catch (e) {
      debugPrint('HealthDataRepository.syncDailyHealthData error: $e');
      return existingSummary ??
          DailyHealthSummary(
            date: dateKey,
            lastSyncedAt: DateTime.now(),
          );
    }
  }

  static HealthMetricType? _mapHealthDataTypeToMetricType(HealthDataType type) {
    switch (type) {
      case HealthDataType.STEPS:
        return HealthMetricType.steps;
      case HealthDataType.HEART_RATE:
        return HealthMetricType.heartRate;
      case HealthDataType.RESTING_HEART_RATE:
        return HealthMetricType.restingHeartRate;
      case HealthDataType.ACTIVE_ENERGY_BURNED:
        return HealthMetricType.activeCalories;
      case HealthDataType.TOTAL_CALORIES_BURNED:
        return HealthMetricType.totalCalories;
      case HealthDataType.DISTANCE_WALKING_RUNNING:
        return HealthMetricType.distance;
      case HealthDataType.SLEEP_SESSION:
      case HealthDataType.SLEEP_ASLEEP:
      case HealthDataType.SLEEP_DEEP:
      case HealthDataType.SLEEP_LIGHT:
      case HealthDataType.SLEEP_REM:
      case HealthDataType.SLEEP_AWAKE:
        return HealthMetricType.sleep;
      case HealthDataType.WORKOUT:
        return HealthMetricType.workout;
      default:
        return null;
    }
  }

  static String _formatDateKey(DateTime dt) {
    return '${dt.year.toString().padLeft(4, '0')}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }
}

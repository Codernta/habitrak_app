import 'dart:convert';
import 'package:crypto/crypto.dart';
import '../domain/models/health_metric_type.dart';
import '../domain/models/normalized_health_record.dart';

class DeduplicationEngine {
  /// Generates a deterministic unique ID for a health sample
  static String generateRecordId({
    required String sourceApp,
    required HealthMetricType metricType,
    required DateTime startTime,
    required DateTime endTime,
    required double value,
  }) {
    final payload =
        '${sourceApp}_${metricType.name}_${startTime.millisecondsSinceEpoch}_${endTime.millisecondsSinceEpoch}_$value';
    return sha256.convert(utf8.encode(payload)).toString();
  }

  /// Deduplicates a list of normalized health records.
  /// 1. Exact ID match deduplication
  /// 2. Overlapping interval resolution: for cumulative metrics (steps, calories, distance),
  ///    if multiple sources report the same or overlapping time window, prioritize hardware/wearable sources
  ///    over secondary aggregator apps to avoid double-counting.
  List<NormalizedHealthRecord> deduplicate(List<NormalizedHealthRecord> records) {
    if (records.isEmpty) return [];

    // 1. Group records by metric type and recording date
    final Map<String, List<NormalizedHealthRecord>> grouped = {};
    for (final record in records) {
      final key = '${record.metricType.name}_${record.recordingDate}';
      grouped.putIfAbsent(key, () => []).add(record);
    }

    final List<NormalizedHealthRecord> deduplicatedResults = [];

    for (final entry in grouped.entries) {
      final groupRecords = entry.value;

      // Deduplicate exact hashes first
      final Map<String, NormalizedHealthRecord> uniqueById = {};
      for (final r in groupRecords) {
        uniqueById[r.id] = r;
      }
      final uniqueList = uniqueById.values.toList();

      // Sort by start time, then priority
      uniqueList.sort((a, b) {
        final cmp = a.startTime.compareTo(b.startTime);
        if (cmp != 0) return cmp;
        return _getSourcePriority(b.sourceApp).compareTo(_getSourcePriority(a.sourceApp));
      });

      // Filter out overlapping intervals for cumulative metrics (like steps, sleep, workouts)
      final List<NormalizedHealthRecord> nonOverlapping = [];
      for (final current in uniqueList) {
        if (nonOverlapping.isEmpty) {
          nonOverlapping.add(current);
          continue;
        }

        final previous = nonOverlapping.last;
        final hasOverlap = current.startTime.isBefore(previous.endTime);

        if (hasOverlap) {
          // If intervals overlap, pick the one from higher-priority source or with more detailed value
          final prevPriority = _getSourcePriority(previous.sourceApp);
          final currPriority = _getSourcePriority(current.sourceApp);

          if (currPriority > prevPriority) {
            // Replace previous with higher-priority source
            nonOverlapping.removeLast();
            nonOverlapping.add(current);
          } else if (currPriority == prevPriority) {
            // Same priority: if identical timestamps and values, ignore current (duplicate)
            if (current.startTime == previous.startTime &&
                current.endTime == previous.endTime) {
              continue;
            }
            // If current extends beyond previous, we can either adjust or keep if distinct
            if (current.endTime.isAfter(previous.endTime)) {
              nonOverlapping.add(current);
            }
          }
          // currPriority < prevPriority: ignore lower priority overlapping record
        } else {
          nonOverlapping.add(current);
        }
      }

      deduplicatedResults.addAll(nonOverlapping);
    }

    return deduplicatedResults;
  }

  /// Assigns priority based on source app credibility (native wearable hardware > companion apps > unknown)
  static int _getSourcePriority(String sourceApp) {
    final lower = sourceApp.toLowerCase();
    if (lower.contains('apple') || lower.contains('watch') || lower.contains('healthkit')) {
      return 100;
    }
    if (lower.contains('samsung') || lower.contains('health connect') || lower.contains('pixel')) {
      return 100;
    }
    if (lower.contains('garmin') || lower.contains('fitbit') || lower.contains('oura') || lower.contains('whoop')) {
      return 90;
    }
    if (lower.contains('strava') || lower.contains('myfitnesspal') || lower.contains('nike')) {
      return 50;
    }
    return 10;
  }
}

import 'package:equatable/equatable.dart';
import 'health_metric_type.dart';

class NormalizedHealthRecord extends Equatable {
  final String id;
  final HealthMetricType metricType;
  final double value;
  final String unit;
  final DateTime startTime;
  final DateTime endTime;
  final String sourceApp;
  final String? sourceDevice;
  final String platform; // 'ios' or 'android'
  final String recordingDate; // YYYY-MM-DD
  final DateTime syncedAt;

  const NormalizedHealthRecord({
    required this.id,
    required this.metricType,
    required this.value,
    required this.unit,
    required this.startTime,
    required this.endTime,
    required this.sourceApp,
    this.sourceDevice,
    required this.platform,
    required this.recordingDate,
    required this.syncedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'metricType': metricType.name,
      'value': value,
      'unit': unit,
      'startTime': startTime.toIso8601String(),
      'endTime': endTime.toIso8601String(),
      'sourceApp': sourceApp,
      'sourceDevice': sourceDevice,
      'platform': platform,
      'recordingDate': recordingDate,
      'syncedAt': syncedAt.toIso8601String(),
    };
  }

  factory NormalizedHealthRecord.fromMap(Map<dynamic, dynamic> map) {
    return NormalizedHealthRecord(
      id: map['id'] as String,
      metricType: HealthMetricType.values.byName(map['metricType'] as String),
      value: (map['value'] as num).toDouble(),
      unit: map['unit'] as String,
      startTime: DateTime.parse(map['startTime'] as String),
      endTime: DateTime.parse(map['endTime'] as String),
      sourceApp: map['sourceApp'] as String,
      sourceDevice: map['sourceDevice'] as String?,
      platform: map['platform'] as String,
      recordingDate: map['recordingDate'] as String,
      syncedAt: DateTime.parse(map['syncedAt'] as String),
    );
  }

  @override
  List<Object?> get props => [
        id,
        metricType,
        value,
        unit,
        startTime,
        endTime,
        sourceApp,
        sourceDevice,
        platform,
        recordingDate,
        syncedAt,
      ];
}

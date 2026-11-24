enum HealthMetricType {
  steps,
  heartRate,
  restingHeartRate,
  activeCalories,
  totalCalories,
  distance,
  sleep,
  workout,
  respiratoryRate,
  oxygenSaturation,
}

extension HealthMetricTypeExtension on HealthMetricType {
  String get displayName {
    switch (this) {
      case HealthMetricType.steps:
        return 'Steps';
      case HealthMetricType.heartRate:
        return 'Heart Rate';
      case HealthMetricType.restingHeartRate:
        return 'Resting Heart Rate';
      case HealthMetricType.activeCalories:
        return 'Active Calories';
      case HealthMetricType.totalCalories:
        return 'Total Calories';
      case HealthMetricType.distance:
        return 'Distance';
      case HealthMetricType.sleep:
        return 'Sleep Duration';
      case HealthMetricType.workout:
        return 'Workout Duration';
      case HealthMetricType.respiratoryRate:
        return 'Respiratory Rate';
      case HealthMetricType.oxygenSaturation:
        return 'Oxygen Saturation';
    }
  }

  String get defaultUnit {
    switch (this) {
      case HealthMetricType.steps:
        return 'steps';
      case HealthMetricType.heartRate:
      case HealthMetricType.restingHeartRate:
        return 'bpm';
      case HealthMetricType.activeCalories:
      case HealthMetricType.totalCalories:
        return 'kcal';
      case HealthMetricType.distance:
        return 'km';
      case HealthMetricType.sleep:
      case HealthMetricType.workout:
        return 'mins';
      case HealthMetricType.respiratoryRate:
        return 'brpm';
      case HealthMetricType.oxygenSaturation:
        return '%';
    }
  }
}

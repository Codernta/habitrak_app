import 'package:hive/hive.dart';
import '../../../../core/storage/hive_registrar.dart';

class ActivityRepository {
  final Box<Map> _box = Hive.box<Map>(HiveRegistrar.activityLogsBoxName);

  List<Map<String, dynamic>> getActivityLogs() {
    return _box.values.map((v) => Map<String, dynamic>.from(v)).toList();
  }

  Future<void> logWalkSession({
    required int durationMinutes,
    required double distanceKm,
    required int caloriesBurned,
  }) async {
    final id = 'walk_${DateTime.now().millisecondsSinceEpoch}';
    final entry = {
      'id': id,
      'type': 'walk',
      'durationMinutes': durationMinutes,
      'durationSeconds': durationMinutes * 60,
      'distanceKm': distanceKm,
      'calories': caloriesBurned,
      'date': DateTime.now().toIso8601String(),
    };
    await _box.put(id, entry);
  }

  Future<void> logYogaSession({
    required int durationMinutes,
    required int posesCompleted,
  }) async {
    final id = 'yoga_${DateTime.now().millisecondsSinceEpoch}';
    final entry = {
      'id': id,
      'type': 'yoga',
      'durationMinutes': durationMinutes,
      'posesCompleted': posesCompleted,
      'date': DateTime.now().toIso8601String(),
    };
    await _box.put(id, entry);
  }

  int getTotalMindfulMinutes() {
    int total = 0;
    for (var v in _box.values) {
      final map = Map<String, dynamic>.from(v);
      if (map['type'] == 'walk') {
        final mins =
            map['durationMinutes'] as int? ??
            ((map['durationSeconds'] as int? ?? 0) / 60).round();
        total += mins;
      } else if (map['type'] == 'yoga') {
        total += map['durationMinutes'] as int? ?? 0;
      }
    }
    // Base initial default minutes so profile starts nicely
    return total > 0 ? total + 480 : 480;
  }
}

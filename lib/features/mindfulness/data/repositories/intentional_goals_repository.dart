import 'package:hive/hive.dart';
import '../../../../core/storage/hive_registrar.dart';

class IntentionalGoalsRepository {
  final Box<Map> _box = Hive.box<Map>(HiveRegistrar.mindfulnessGoalsBoxName);

  final List<Map<String, dynamic>> _initialGoals = [
    {'id': 'goal_1', 'title': 'Morning breathwork (5 min)', 'completed': true},
    {'id': 'goal_2', 'title': 'Read 10 pages for growth', 'completed': false},
    {'id': 'goal_3', 'title': 'Evening tech detox', 'completed': false},
  ];

  Future<void> ensureInitialized() async {
    if (_box.isEmpty) {
      for (var goal in _initialGoals) {
        await _box.put(goal['id'], goal);
      }
    }
  }

  List<Map<String, dynamic>> getGoals() {
    if (_box.isEmpty) {
      return List<Map<String, dynamic>>.from(_initialGoals);
    }
    return _box.values.map((v) => Map<String, dynamic>.from(v)).toList();
  }

  Future<void> toggleGoal(String id) async {
    final goal = _box.get(id);
    if (goal != null) {
      final updated = Map<String, dynamic>.from(goal);
      updated['completed'] = !(updated['completed'] == true);
      await _box.put(id, updated);
    }
  }

  Future<Map<String, dynamic>> addGoal(String title) async {
    final id = 'goal_${DateTime.now().millisecondsSinceEpoch}';
    final newGoal = {
      'id': id,
      'title': title,
      'completed': false,
    };
    await _box.put(id, newGoal);
    return newGoal;
  }

  Future<void> deleteGoal(String id) async {
    await _box.delete(id);
  }
}

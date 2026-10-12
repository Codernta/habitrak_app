import 'package:hive/hive.dart';
import '../../../../core/security/secure_data_manager.dart';
import '../../../../core/storage/hive_registrar.dart';

class IntentionalGoalsRepository {
  final Box<Map> _box = Hive.box<Map>(HiveRegistrar.mindfulnessGoalsBoxName);

  static const String _keyMetaSyncDate = '__meta_last_goals_date';

  final List<Map<String, dynamic>> _initialGoals = [
    {'id': 'goal_1', 'title': 'Morning breathwork (5 min)', 'completed': true},
    {'id': 'goal_2', 'title': 'Read 10 pages for growth', 'completed': false},
    {'id': 'goal_3', 'title': 'Evening tech detox', 'completed': false},
  ];

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> ensureInitialized() async {
    if (_box.isEmpty) {
      for (var goal in _initialGoals) {
        await _box.put(goal['id'], goal);
      }
      await _box.put(_keyMetaSyncDate, {'date': _todayKey()});
    }
  }

  Future<void> syncDailyGoals() async {
    final today = _todayKey();
    final meta = _box.get(_keyMetaSyncDate);
    final lastDate = meta?['date'] as String?;

    if (lastDate != null && lastDate != today) {
      // New day: reset completion status on intentional daily goals
      final keys = _box.keys.where((k) => k != _keyMetaSyncDate).toList();
      for (final key in keys) {
        final goal = _box.get(key);
        if (goal != null) {
          final updated = Map<String, dynamic>.from(goal);
          updated['completed'] = false;
          await _box.put(key, updated);
        }
      }
      await _box.put(_keyMetaSyncDate, {'date': today});
    } else if (lastDate == null) {
      await _box.put(_keyMetaSyncDate, {'date': today});
    }
  }

  List<Map<String, dynamic>> getGoals() {
    if (_box.isEmpty) {
      return List<Map<String, dynamic>>.from(_initialGoals);
    }
    // Filter out meta key
    return _box.keys
        .where((k) => k != _keyMetaSyncDate)
        .map((k) => Map<String, dynamic>.from(_box.get(k)!))
        .toList();
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
    final sanitizedTitle = SecureDataManager().sanitizeText(
      title,
      maxLength: 100,
    );
    final safeTitle = sanitizedTitle.isNotEmpty
        ? sanitizedTitle
        : 'Mindful Intention';

    final id = 'goal_${DateTime.now().millisecondsSinceEpoch}';
    final newGoal = {'id': id, 'title': safeTitle, 'completed': false};
    await _box.put(id, newGoal);
    return newGoal;
  }

  Future<void> deleteGoal(String id) async {
    await _box.delete(id);
  }
}

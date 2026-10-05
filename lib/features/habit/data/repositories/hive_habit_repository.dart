import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/storage/hive_registrar.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';

class HiveHabitRepository implements HabitRepository {
  final Box<Habit> _box = Hive.box<Habit>(HiveRegistrar.habitsBoxName);

  final List<Habit> _defaultHabits = [
    const Habit(
      id: '1',
      title: 'Morning Meditation',
      category: HabitCategory.mindfulness,
      targetProgress: 1.0,
      currentProgress: 1.0,
      isCompleted: true,
      completedAt: '7:15 AM',
      scheduledTime: '7:15 AM',
    ),
    const Habit(
      id: '2',
      title: 'Drink 2L Water',
      category: HabitCategory.health,
      targetProgress: 2.0,
      currentProgress: 1.2,
      unit: 'L',
      isCompleted: false,
    ),
    const Habit(
      id: '3',
      title: 'Read for 20 mins',
      category: HabitCategory.growth,
      targetProgress: 20.0,
      currentProgress: 0.0,
      unit: 'mins',
      streak: 5,
    ),
    const Habit(
      id: '4',
      title: 'No Screen Time',
      category: HabitCategory.mindfulness,
      targetProgress: 1.0,
      currentProgress: 0.0,
      isCompleted: false,
      scheduledTime: '9:00 PM',
    ),
  ];

  @override
  Future<List<Habit>> getHabits() async {
    if (_box.isEmpty) {
      await _box.addAll(_defaultHabits);
      await _seedInitialHistory();
    }
    return _box.values.toList();
  }

  @override
  Future<void> toggleHabitCompletion(String habitId) async {
    final habit = _getHabitById(habitId);
    if (habit != null) {
      final newCompleted = !habit.isCompleted;
      
      double newProgress = newCompleted ? habit.targetProgress : 0.0;
      if (habit.unit == 'L') {
        newProgress = newCompleted ? habit.targetProgress : 1.2;
      } else if (habit.unit == 'mins') {
        newProgress = newCompleted ? habit.targetProgress : 0.0;
      }

      int newStreak = habit.streak;
      if (newCompleted && habit.streak == 0) {
        newStreak = 1;
      } else if (newCompleted) {
        newStreak = habit.streak + 1;
      } else if (!newCompleted && habit.streak > 0) {
        newStreak = habit.streak - 1;
      }

      String? completedTime = newCompleted 
          ? '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}'
          : null;

      final updated = habit.copyWith(
        isCompleted: newCompleted,
        currentProgress: newProgress,
        streak: newStreak,
        completedAt: completedTime,
      );

      await _updateHabitInBox(updated);
      await _recordDailyCompletion();
    }
  }

  @override
  Future<void> updateHabitProgress(String habitId, double progress) async {
    final habit = _getHabitById(habitId);
    if (habit != null) {
      final double cappedProgress = progress.clamp(0.0, habit.targetProgress);
      final bool newCompleted = cappedProgress >= habit.targetProgress;

      int newStreak = habit.streak;
      if (newCompleted && !habit.isCompleted) {
        newStreak = habit.streak + 1;
      } else if (!newCompleted && habit.isCompleted) {
        newStreak = (habit.streak - 1).clamp(0, 999);
      }

      String? completedTime = newCompleted && !habit.isCompleted
          ? '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')} ${DateTime.now().hour >= 12 ? 'PM' : 'AM'}'
          : habit.completedAt;

      final updated = habit.copyWith(
        currentProgress: cappedProgress,
        isCompleted: newCompleted,
        streak: newStreak,
        completedAt: newCompleted ? completedTime : null,
      );

      await _updateHabitInBox(updated);
      await _recordDailyCompletion();
    }
  }

  @override
  Future<void> addHabit(Habit habit) async {
    await _box.add(habit);
    await _recordDailyCompletion();
  }

  @override
  Future<void> resetHabits() async {
    await _box.clear();
    await _box.addAll(_defaultHabits);
    await _seedInitialHistory();
  }

  Habit? _getHabitById(String id) {
    try {
      return _box.values.firstWhere((h) => h.id == id);
    } catch (e) {
      return null;
    }
  }

  Future<void> _updateHabitInBox(Habit updatedHabit) async {
    final keys = _box.keys.toList();
    for (var key in keys) {
      final habit = _box.get(key);
      if (habit != null && habit.id == updatedHabit.id) {
        await _box.put(key, updatedHabit);
        break;
      }
    }
  }

  String _formatDateKey(DateTime dt) {
    return '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
  }

  Future<void> _recordDailyCompletion() async {
    if (Hive.isBoxOpen(HiveRegistrar.habitHistoryBoxName)) {
      final historyBox = Hive.box<Map>(HiveRegistrar.habitHistoryBoxName);
      final todayKey = _formatDateKey(DateTime.now());
      final allHabits = _box.values.toList();
      final completed = allHabits.where((h) => h.isCompleted).length;
      await historyBox.put(todayKey, {
        'date': todayKey,
        'completedCount': completed,
        'totalHabits': allHabits.length,
        'completedHabitIds': allHabits.where((h) => h.isCompleted).map((h) => h.id).toList(),
      });
    }
  }

  Future<void> _seedInitialHistory() async {
    if (Hive.isBoxOpen(HiveRegistrar.habitHistoryBoxName)) {
      final historyBox = Hive.box<Map>(HiveRegistrar.habitHistoryBoxName);
      if (historyBox.isEmpty) {
        final now = DateTime.now();
        // Seed past 35 days with realistic active streak history
        for (int i = 35; i >= 1; i--) {
          final dt = now.subtract(Duration(days: i));
          final key = _formatDateKey(dt);
          // Realistic variation: weekends and weekdays
          final int completed = (i % 7 == 0 || i % 7 == 6) ? 3 : 4;
          await historyBox.put(key, {
            'date': key,
            'completedCount': completed,
            'totalHabits': 4,
            'completedHabitIds': ['1', '2', '3', '4'].sublist(0, completed),
          });
        }
      }
    }
  }
}

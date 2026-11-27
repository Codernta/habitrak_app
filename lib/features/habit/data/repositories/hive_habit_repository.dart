import 'package:hive_flutter/hive_flutter.dart';
import '../../../../core/security/secure_data_manager.dart';
import '../../../../core/storage/hive_registrar.dart';
import '../../domain/entities/habit.dart';
import '../../domain/repositories/habit_repository.dart';
import '../../services/firebase_habit_sync_service.dart';
import '../../../../core/services/analytics_service.dart';

class HiveHabitRepository implements HabitRepository {
  final Box<Habit> _box = Hive.box<Habit>(HiveRegistrar.habitsBoxName);
  final FirebaseHabitSyncService _cloudSyncService;

  HiveHabitRepository({FirebaseHabitSyncService? cloudSyncService})
      : _cloudSyncService = cloudSyncService ?? FirebaseHabitSyncService();

  static const String _keyLastActiveDate = 'last_active_date';

  final List<Habit> _defaultHabits = [
    const Habit(
      id: '1',
      title: 'Morning Meditation',
      category: HabitCategory.mindfulness,
      targetProgress: 1.0,
      currentProgress: 0.0,
      isCompleted: false,
      scheduledTime: '7:15 AM',
      streak: 0,
    ),
    const Habit(
      id: '2',
      title: 'Drink 2L Water',
      category: HabitCategory.health,
      targetProgress: 2.0,
      currentProgress: 0.0,
      unit: 'L',
      isCompleted: false,
      streak: 0,
    ),
    const Habit(
      id: '3',
      title: 'Read for 20 mins',
      category: HabitCategory.growth,
      targetProgress: 20.0,
      currentProgress: 0.0,
      unit: 'mins',
      isCompleted: false,
      streak: 0,
    ),
    const Habit(
      id: '4',
      title: 'No Screen Time',
      category: HabitCategory.mindfulness,
      targetProgress: 1.0,
      currentProgress: 0.0,
      isCompleted: false,
      scheduledTime: '9:00 PM',
      streak: 0,
    ),
  ];

  @override
  Future<List<Habit>> getHabits() async {
    if (_box.isEmpty) {
      // First try to restore any cloud-synced habits for this user
      final cloudHabits = await _cloudSyncService.fetchHabitsFromCloud();
      if (cloudHabits.isNotEmpty) {
        await _box.addAll(cloudHabits);
      } else {
        await _box.addAll(_defaultHabits);
        await _cloudSyncService.syncHabitsToCloud(_defaultHabits);
      }
      final settingsBox = _getSettingsBox();
      await settingsBox.put(_keyLastActiveDate, _formatDateKey(DateTime.now()));
    }

    // Automatically perform everyday sync and daily rollover
    await syncDailyHabits();
    return _box.values.toList();
  }

  @override
  Future<void> syncDailyHabits() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayKey = _formatDateKey(today);

    final settingsBox = _getSettingsBox();
    final lastActiveDateStr = settingsBox.get(_keyLastActiveDate) as String?;

    if (lastActiveDateStr == null) {
      // First run: establish today as the active date
      await settingsBox.put(_keyLastActiveDate, todayKey);
      await _recordDailyCompletion();
      return;
    }

    if (lastActiveDateStr == todayKey) {
      // Already on today, ensure today is recorded
      await _recordDailyCompletion();
      return;
    }

    // A day or multiple days have passed since the last session!
    final parts = lastActiveDateStr.split('-').map(int.parse).toList();
    final lastActiveDate = DateTime(parts[0], parts[1], parts[2]);
    final daysElapsed = today.difference(lastActiveDate).inDays;

    if (daysElapsed > 0) {
      final historyBox = _getHistoryBox();

      // 1. Snapshot previous active day's completion in history if missing
      if (!historyBox.containsKey(lastActiveDateStr)) {
        final currentHabits = _box.values.toList();
        final completed = currentHabits.where((h) => h.isCompleted).toList();
        await historyBox.put(lastActiveDateStr, {
          'date': lastActiveDateStr,
          'completedCount': completed.length,
          'totalHabits': currentHabits.length,
          'completedHabitIds': completed.map((h) => h.id).toList(),
        });
      }

      // 2. Mark any skipped days in between as 0 completed
      for (int i = 1; i < daysElapsed; i++) {
        final skippedDt = lastActiveDate.add(Duration(days: i));
        final skippedKey = _formatDateKey(skippedDt);
        if (!historyBox.containsKey(skippedKey)) {
          await historyBox.put(skippedKey, {
            'date': skippedKey,
            'completedCount': 0,
            'totalHabits': _box.length > 0 ? _box.length : 4,
            'completedHabitIds': <String>[],
          });
        }
      }

      // 3. Evaluate streaks and reset habits for the new day
      final keys = _box.keys.toList();
      for (var key in keys) {
        final habit = _box.get(key);
        if (habit == null) continue;

        int newStreak = habit.streak;
        if (daysElapsed == 1) {
          // If the habit was completed yesterday, maintain its streak!
          // If it was NOT completed yesterday, the streak resets to 0.
          if (!habit.isCompleted) {
            newStreak = 0;
          }
        } else {
          // More than 1 day skipped: streak broken
          newStreak = 0;
        }

        // Daily reset: uncompleted, 0 progress, no completion timestamp
        final resetHabit = habit.copyWith(
          isCompleted: false,
          currentProgress: 0.0,
          clearCompletedAt: true,
          streak: newStreak,
        );

        await _box.put(key, resetHabit);
      }

      // 4. Update last active date to today
      await settingsBox.put(_keyLastActiveDate, todayKey);

      // 5. Record today's fresh day snapshot
      await _recordDailyCompletion();
    }
  }

  @override
  Future<List<Habit>> getHabitsForDate(DateTime date) async {
    await syncDailyHabits();

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);

    if (target.isAtSameMomentAs(today)) {
      return _box.values.toList();
    }

    final currentHabits = _box.values.toList();

    if (target.isAfter(today)) {
      // Future date: habits shown as planned, 0% completed
      return currentHabits
          .map(
            (h) => h.copyWith(
              isCompleted: false,
              currentProgress: 0.0,
              clearCompletedAt: true,
            ),
          )
          .toList();
    }

    // Past date: fetch historical record
    final targetKey = _formatDateKey(target);
    final historyBox = _getHistoryBox();
    final record = historyBox.get(targetKey);

    if (record != null) {
      final completedIds =
          (record['completedHabitIds'] as List?)?.cast<String>() ?? [];
      return currentHabits.map((h) {
        final wasCompleted = completedIds.contains(h.id);
        return h.copyWith(
          isCompleted: wasCompleted,
          currentProgress: wasCompleted ? h.targetProgress : 0.0,
          completedAt: wasCompleted ? (h.scheduledTime ?? 'Completed') : null,
          clearCompletedAt: !wasCompleted,
        );
      }).toList();
    }

    // No record found for past date
    return currentHabits
        .map(
          (h) => h.copyWith(
            isCompleted: false,
            currentProgress: 0.0,
            clearCompletedAt: true,
          ),
        )
        .toList();
  }

  @override
  Future<double> getCompletionPercentageForDate(DateTime date) async {
    final habits = await getHabitsForDate(date);
    if (habits.isEmpty) return 0.0;
    final completed = habits.where((h) => h.isCompleted).length;
    return (completed / habits.length) * 100.0;
  }

  @override
  Future<void> toggleHabitCompletion(String habitId) async {
    final habit = _getHabitById(habitId);
    if (habit != null) {
      final newCompleted = !habit.isCompleted;
      final double newProgress = newCompleted ? habit.targetProgress : 0.0;

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
      _cloudSyncService.syncHabitToCloud(updated);

      if (newCompleted) {
        AnalyticsService().logHabitCompleted(
          habitId: updated.id,
          title: updated.title,
          category: updated.category.name,
          streak: updated.streak,
          targetProgress: updated.targetProgress,
          unit: updated.unit,
        );
      } else {
        AnalyticsService().logHabitUncompleted(
          habitId: updated.id,
          title: updated.title,
          streak: updated.streak,
        );
      }
    }
  }

  @override
  Future<void> updateHabitProgress(String habitId, double progress) async {
    final habit = _getHabitById(habitId);
    if (habit != null) {
      final sanitizedProgress = SecureDataManager().sanitizeNumeric(
        progress,
        min: 0.0,
        max: habit.targetProgress,
      );
      final bool newCompleted = sanitizedProgress >= habit.targetProgress;

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
        currentProgress: sanitizedProgress,
        isCompleted: newCompleted,
        streak: newStreak,
        completedAt: newCompleted ? completedTime : null,
      );

      await _updateHabitInBox(updated);
      await _recordDailyCompletion();
      _cloudSyncService.syncHabitToCloud(updated);

      AnalyticsService().logHabitProgressUpdated(
        habitId: updated.id,
        title: updated.title,
        progress: sanitizedProgress,
        targetProgress: updated.targetProgress,
        isCompleted: newCompleted,
      );
    }
  }

  @override
  Future<void> addHabit(Habit habit) async {
    final secureManager = SecureDataManager();
    final sanitizedTitle = secureManager.sanitizeText(
      habit.title,
      maxLength: 80,
    );
    final sanitizedUnit = secureManager.sanitizeText(habit.unit, maxLength: 10);
    final sanitizedTarget = secureManager.sanitizeNumeric(
      habit.targetProgress,
      min: 0.1,
    );

    final safeHabit = habit.copyWith(
      title: sanitizedTitle.isNotEmpty ? sanitizedTitle : 'New Intention',
      unit: sanitizedUnit,
      targetProgress: sanitizedTarget,
    );

    await _box.add(safeHabit);
    await _recordDailyCompletion();
    _cloudSyncService.syncHabitToCloud(safeHabit);

    AnalyticsService().logHabitCreated(
      habitId: safeHabit.id,
      title: safeHabit.title,
      category: safeHabit.category.name,
      targetProgress: safeHabit.targetProgress,
      unit: safeHabit.unit,
    );
  }

  @override
  Future<void> resetHabits() async {
    await _box.clear();
    await _box.addAll(_defaultHabits);
    final settingsBox = _getSettingsBox();
    await settingsBox.put(_keyLastActiveDate, _formatDateKey(DateTime.now()));
    await _recordDailyCompletion();
    await _cloudSyncService.syncHabitsToCloud(_defaultHabits);
  }

  Box<dynamic> _getSettingsBox() {
    return Hive.box<dynamic>(HiveRegistrar.settingsBoxName);
  }

  Box<Map> _getHistoryBox() {
    return Hive.box<Map>(HiveRegistrar.habitHistoryBoxName);
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
      final historyBox = _getHistoryBox();
      final todayKey = _formatDateKey(DateTime.now());
      final allHabits = _box.values.toList();
      final completed = allHabits.where((h) => h.isCompleted).length;
      final record = {
        'date': todayKey,
        'completedCount': completed,
        'totalHabits': allHabits.length,
        'completedHabitIds': allHabits
            .where((h) => h.isCompleted)
            .map((h) => h.id)
            .toList(),
      };
      await historyBox.put(todayKey, record);

      // Asynchronously sync daily history & stats to Firestore
      _cloudSyncService.syncDailyCompletionHistory(todayKey, record);

      // Compute total completed habits and current max streak
      final maxStreak = allHabits.fold<int>(
        0,
        (max, h) => h.streak > max ? h.streak : max,
      );
      _cloudSyncService.syncUserStats(
        currentStreak: maxStreak,
        totalCompletedHabits: completed,
      );

      if (maxStreak > 0 && maxStreak % 7 == 0) {
        AnalyticsService().logStreakMilestone(
          streakDays: maxStreak,
          totalCompletedHabits: completed,
        );
      }
    }
  }
}

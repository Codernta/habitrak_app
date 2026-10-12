import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:habitrak/core/storage/hive_registrar.dart';
import 'package:habitrak/features/habit/data/repositories/hive_habit_repository.dart';
import 'package:habitrak/features/habit/domain/entities/habit.dart';
import 'package:habitrak/features/mindfulness/data/repositories/intentional_goals_repository.dart';
import 'package:habitrak/features/mindfulness/data/repositories/reflections_repository.dart';
import 'package:habitrak/core/storage/settings_repository.dart';

void main() {
  late Directory tempDir;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('habitrak_test_');
    Hive.init(tempDir.path);

    if (!Hive.isAdapterRegistered(0)) {
      Hive.registerAdapter(HabitAdapter());
    }
    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(HabitCategoryAdapter());
    }

    await Hive.openBox<Habit>(HiveRegistrar.habitsBoxName);
    await Hive.openBox<dynamic>(HiveRegistrar.settingsBoxName);
    await Hive.openBox<Map>(HiveRegistrar.reflectionsBoxName);
    await Hive.openBox<Map>(HiveRegistrar.mindfulnessGoalsBoxName);
    await Hive.openBox<Map>(HiveRegistrar.habitHistoryBoxName);
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('Everyday Data Update & Rollover Tests', () {
    test(
      'Daily rollover resets habits and preserves completed streaks',
      () async {
        final habitsBox = Hive.box<Habit>(HiveRegistrar.habitsBoxName);
        final settingsBox = Hive.box<dynamic>(HiveRegistrar.settingsBoxName);
        final historyBox = Hive.box<Map>(HiveRegistrar.habitHistoryBoxName);

        // Setup habits as if yesterday
        const yesterdayCompletedHabit = Habit(
          id: '1',
          title: 'Morning Meditation',
          category: HabitCategory.mindfulness,
          targetProgress: 1.0,
          currentProgress: 1.0,
          isCompleted: true,
          streak: 5,
          completedAt: '7:30 AM',
        );

        const yesterdayUncompletedHabit = Habit(
          id: '2',
          title: 'Drink 2L Water',
          category: HabitCategory.health,
          targetProgress: 2.0,
          currentProgress: 0.5,
          isCompleted: false,
          streak: 3,
        );

        await habitsBox.put('1', yesterdayCompletedHabit);
        await habitsBox.put('2', yesterdayUncompletedHabit);

        // Simulate last active date as yesterday
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayKey =
            '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
        await settingsBox.put('last_active_date', yesterdayKey);

        final repository = HiveHabitRepository();
        await repository.syncDailyHabits();

        // Check that yesterday was archived in history
        final yesterdayRecord = historyBox.get(yesterdayKey);
        expect(yesterdayRecord, isNotNull);
        expect(yesterdayRecord!['completedCount'], 1);
        expect(yesterdayRecord['completedHabitIds'], contains('1'));

        // Check that today's habits were reset cleanly
        final todayHabits = await repository.getHabits();
        final habit1 = todayHabits.firstWhere((h) => h.id == '1');
        final habit2 = todayHabits.firstWhere((h) => h.id == '2');

        // Completed habit carried its streak over into today
        expect(habit1.isCompleted, isFalse);
        expect(habit1.currentProgress, 0.0);
        expect(habit1.completedAt, isNull);
        expect(habit1.streak, 5);

        // Uncompleted habit had its streak broken (reset to 0)
        expect(habit2.isCompleted, isFalse);
        expect(habit2.currentProgress, 0.0);
        expect(habit2.streak, 0);
      },
    );

    test('Multi-day lapse breaks all streaks and records missed days', () async {
      final habitsBox = Hive.box<Habit>(HiveRegistrar.habitsBoxName);
      final settingsBox = Hive.box<dynamic>(HiveRegistrar.settingsBoxName);
      final historyBox = Hive.box<Map>(HiveRegistrar.habitHistoryBoxName);

      const habit = Habit(
        id: '1',
        title: 'Morning Meditation',
        category: HabitCategory.mindfulness,
        targetProgress: 1.0,
        currentProgress: 1.0,
        isCompleted: true,
        streak: 10,
      );
      await habitsBox.put('1', habit);

      // Simulate user opening app 3 days later
      final threeDaysAgo = DateTime.now().subtract(const Duration(days: 3));
      final threeDaysAgoKey =
          '${threeDaysAgo.year}-${threeDaysAgo.month.toString().padLeft(2, '0')}-${threeDaysAgo.day.toString().padLeft(2, '0')}';
      await settingsBox.put('last_active_date', threeDaysAgoKey);

      final repository = HiveHabitRepository();
      await repository.syncDailyHabits();

      // Habits should have streak reset to 0
      final todayHabits = await repository.getHabits();
      expect(todayHabits.first.streak, 0);
      expect(todayHabits.first.isCompleted, isFalse);

      // Intervening days recorded in history
      final oneDayAgo = DateTime.now().subtract(const Duration(days: 1));
      final oneDayAgoKey =
          '${oneDayAgo.year}-${oneDayAgo.month.toString().padLeft(2, '0')}-${oneDayAgo.day.toString().padLeft(2, '0')}';
      expect(historyBox.get(oneDayAgoKey), isNotNull);
      expect(historyBox.get(oneDayAgoKey)!['completedCount'], 0);
    });

    test(
      'getHabitsForDate returns historical and planned status accurately',
      () async {
        final repository = HiveHabitRepository();
        final historyBox = Hive.box<Map>(HiveRegistrar.habitHistoryBoxName);

        // Populate current habits
        await repository.getHabits();

        // Put a past record
        final pastDate = DateTime(2026, 10, 10);
        await historyBox.put('2026-10-10', {
          'date': '2026-10-10',
          'completedCount': 2,
          'totalHabits': 4,
          'completedHabitIds': ['1', '2'],
        });

        final pastHabits = await repository.getHabitsForDate(pastDate);
        final h1 = pastHabits.firstWhere((h) => h.id == '1');
        final h3 = pastHabits.firstWhere((h) => h.id == '3');

        expect(h1.isCompleted, isTrue);
        expect(h3.isCompleted, isFalse);

        final pastPercentage = await repository.getCompletionPercentageForDate(
          pastDate,
        );
        expect(pastPercentage, 50.0);

        // Future date
        final futureDate = DateTime.now().add(const Duration(days: 3));
        final futureHabits = await repository.getHabitsForDate(futureDate);
        expect(futureHabits.every((h) => !h.isCompleted), isTrue);
      },
    );

    test('Intentional daily goals reset completion on new day', () async {
      final goalsRepo = IntentionalGoalsRepository();
      await goalsRepo.ensureInitialized();

      final goalsBox = Hive.box<Map>(HiveRegistrar.mindfulnessGoalsBoxName);
      await goalsRepo.toggleGoal('goal_1'); // toggle

      // Simulate yesterday as last sync date
      final yesterday = DateTime.now().subtract(const Duration(days: 1));
      final yesterdayKey =
          '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
      await goalsBox.put('__meta_last_goals_date', {'date': yesterdayKey});

      await goalsRepo.syncDailyGoals();

      final freshGoals = goalsRepo.getGoals();
      expect(freshGoals.every((g) => g['completed'] == false), isTrue);
    });

    test('ReflectionsRepository calculates dynamic relative dates', () async {
      final repo = ReflectionsRepository();
      await repo.ensureInitialized();

      final now = DateTime.now();
      await repo.addReflection('Fresh entry today');

      final reflections = repo.getReflections();
      final todayEntry = reflections.firstWhere(
        (r) => r['text'] == 'Fresh entry today',
      );
      expect(todayEntry['date'], 'Today');

      // Check formatting for an entry created 1 day ago
      final yesterdayEntry = {
        'id': 'test_yest',
        'text': 'Yesterday peaceful entry',
        'createdAt': now.subtract(const Duration(days: 1)).toIso8601String(),
      };
      await Hive.box<Map>(
        HiveRegistrar.reflectionsBoxName,
      ).put('test_yest', yesterdayEntry);

      final updatedList = repo.getReflections();
      final retrievedYesterday = updatedList.firstWhere(
        (r) => r['id'] == 'test_yest',
      );
      expect(retrievedYesterday['date'], 'Yesterday');
    });

    test(
      'SettingsRepository rolls over daily screen time on date change',
      () async {
        final settingsRepo = SettingsRepository();
        final settingsBox = Hive.box(HiveRegistrar.settingsBoxName);

        await settingsRepo.setDailyScreenTimeMinutes(120);

        // Simulate yesterday as recorded screen time date
        final yesterday = DateTime.now().subtract(const Duration(days: 1));
        final yesterdayKey =
            '${yesterday.year}-${yesterday.month.toString().padLeft(2, '0')}-${yesterday.day.toString().padLeft(2, '0')}';
        await settingsBox.put('screen_time_date', yesterdayKey);

        // Accessing screen time today rolls over and initializes fresh
        final todayScreenTime = settingsRepo.getDailyScreenTimeMinutes();
        expect(todayScreenTime, 25);
        expect(settingsBox.get('screen_time_$yesterdayKey'), 120);
      },
    );
  });
}

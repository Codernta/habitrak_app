import 'package:hive_flutter/hive_flutter.dart';
import '../../features/habit/domain/entities/habit.dart';

class HiveRegistrar {
  static const String habitsBoxName = 'habits';
  static const String settingsBoxName = 'settings';
  static const String reflectionsBoxName = 'reflections';
  static const String mindfulnessGoalsBoxName = 'mindfulness_goals';
  static const String activityLogsBoxName = 'activity_logs';
  static const String habitHistoryBoxName = 'habit_history';
  static const String profileBoxName = 'user_profile';
  static const String mindfulPuzzleBoxName = 'mindful_puzzle';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(HabitCategoryAdapter());

    // Open boxes
    await Hive.openBox<Habit>(habitsBoxName);
    await Hive.openBox<dynamic>(settingsBoxName);
    await Hive.openBox<Map>(reflectionsBoxName);
    await Hive.openBox<Map>(mindfulnessGoalsBoxName);
    await Hive.openBox<Map>(activityLogsBoxName);
    await Hive.openBox<Map>(habitHistoryBoxName);
    await Hive.openBox<dynamic>(profileBoxName);
    await Hive.openBox<dynamic>(mindfulPuzzleBoxName);
  }
}

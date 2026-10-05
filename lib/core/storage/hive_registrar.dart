import 'package:hive_flutter/hive_flutter.dart';
import '../../features/habit/domain/entities/habit.dart';

class HiveRegistrar {
  static const String habitsBoxName = 'habits';
  static const String settingsBoxName = 'settings';

  static Future<void> init() async {
    await Hive.initFlutter();
    
    // Register adapters
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(HabitCategoryAdapter());

    // Open boxes
    await Hive.openBox<Habit>(habitsBoxName);
    await Hive.openBox<dynamic>(settingsBoxName);
  }
}

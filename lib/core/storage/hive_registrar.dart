import 'package:hive_flutter/hive_flutter.dart';
import '../security/secure_data_manager.dart';
import '../../features/habit/domain/entities/habit.dart';

class HiveRegistrar {
  static const String habitsBoxName = 'habits';
  static const String settingsBoxName = 'settings';
  static const String reflectionsBoxName = 'reflections';
  static const String mindfulnessGoalsBoxName = 'mindfulness_goals';
  static const String activityLogsBoxName = 'activity_logs';
  static const String habitHistoryBoxName = 'habit_history';
  static const String profileBoxName = 'user_profile';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(HabitAdapter());
    Hive.registerAdapter(HabitCategoryAdapter());

    // Initialize AES-256 secure encryption key vault
    final secureManager = SecureDataManager();
    await secureManager.initializeKeyVault();
    final cipher = secureManager.getCipher();

    // Open boxes safely with AES-256 encryption support
    await _openSafeBox<Habit>(habitsBoxName, cipher: cipher);
    await _openSafeBox<dynamic>(settingsBoxName, cipher: cipher);
    await _openSafeBox<Map>(reflectionsBoxName, cipher: cipher);
    await _openSafeBox<Map>(mindfulnessGoalsBoxName, cipher: cipher);
    await _openSafeBox<Map>(activityLogsBoxName, cipher: cipher);
    await _openSafeBox<Map>(habitHistoryBoxName, cipher: cipher);
    await _openSafeBox<dynamic>(profileBoxName, cipher: cipher);
  }

  static Future<Box<T>> _openSafeBox<T>(
    String name, {
    HiveCipher? cipher,
  }) async {
    try {
      return await Hive.openBox<T>(name, encryptionCipher: cipher);
    } catch (_) {
      // Fallback gracefully if box was previously created unencrypted
      return await Hive.openBox<T>(name);
    }
  }
}

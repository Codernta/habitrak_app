import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'hive_registrar.dart';

class SettingsRepository {
  final Box _box = Hive.box(HiveRegistrar.settingsBoxName);

  static const String _keyThemeMode = 'theme_mode';
  static const String _keyRemindersEnabled = 'reminders_enabled';
  static const String _keyFocusMode = 'focus_mode';
  static const String _keyDndSchedule = 'dnd_schedule';
  static const String _keyScreenTimeLimit = 'screen_time_limit';
  static const String _keyDailyScreenTime = 'daily_screen_time';
  static const String _keyScreenTimeDate = 'screen_time_date';

  String _formatToday() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  ThemeMode getThemeMode() {
    final isDark = _box.get(_keyThemeMode, defaultValue: true) as bool;
    return isDark ? ThemeMode.dark : ThemeMode.light;
  }

  Future<void> setThemeMode(bool isDark) async {
    await _box.put(_keyThemeMode, isDark);
  }

  bool getRemindersEnabled() {
    return _box.get(_keyRemindersEnabled, defaultValue: true) as bool;
  }

  Future<void> setRemindersEnabled(bool enabled) async {
    await _box.put(_keyRemindersEnabled, enabled);
  }

  bool getFocusMode() {
    return _box.get(_keyFocusMode, defaultValue: true) as bool;
  }

  Future<void> setFocusMode(bool enabled) async {
    await _box.put(_keyFocusMode, enabled);
  }

  bool getDndSchedule() {
    return _box.get(_keyDndSchedule, defaultValue: false) as bool;
  }

  Future<void> setDndSchedule(bool enabled) async {
    await _box.put(_keyDndSchedule, enabled);
  }

  int getScreenTimeLimitMinutes() {
    return _box.get(_keyScreenTimeLimit, defaultValue: 180) as int;
  }

  Future<void> setScreenTimeLimitMinutes(int minutes) async {
    await _box.put(_keyScreenTimeLimit, minutes.clamp(15, 720));
  }

  int getDailyScreenTimeMinutes() {
    final today = _formatToday();
    final recordedDate = _box.get(_keyScreenTimeDate) as String?;

    if (recordedDate == null) {
      _box.put(_keyScreenTimeDate, today);
      return _box.get(_keyDailyScreenTime, defaultValue: 45) as int;
    }

    if (recordedDate != today) {
      // New day: roll over and start fresh today
      _box.put(
        'screen_time_$recordedDate',
        _box.get(_keyDailyScreenTime, defaultValue: 45),
      );
      _box.put(_keyScreenTimeDate, today);
      _box.put(_keyDailyScreenTime, 25); // Fresh starting value for today
      return 25;
    }

    return _box.get(_keyDailyScreenTime, defaultValue: 45) as int;
  }

  Future<void> setDailyScreenTimeMinutes(int minutes) async {
    final today = _formatToday();
    await _box.put(_keyScreenTimeDate, today);
    await _box.put(_keyDailyScreenTime, minutes.clamp(0, 1440));
  }

  Future<void> addScreenTimeMinutes(int delta) async {
    final current = getDailyScreenTimeMinutes();
    await setDailyScreenTimeMinutes(current + delta);
  }

  // Getters for convenience
  bool get isFocusModeEnabled => getFocusMode();
  bool get isDndScheduleEnabled => getDndSchedule();
  int get dailyScreenTimeMinutes => getDailyScreenTimeMinutes();
  int get screenTimeLimitMinutes => getScreenTimeLimitMinutes();

  Future<void> setFocusModeEnabled(bool enabled) => setFocusMode(enabled);
  Future<void> setDndScheduleEnabled(bool enabled) => setDndSchedule(enabled);
}

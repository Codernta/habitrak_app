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
    await _box.put(_keyScreenTimeLimit, minutes);
  }

  int getDailyScreenTimeMinutes() {
    return _box.get(_keyDailyScreenTime, defaultValue: 135) as int;
  }

  Future<void> setDailyScreenTimeMinutes(int minutes) async {
    await _box.put(_keyDailyScreenTime, minutes);
  }

  // Getters for convenience
  bool get isFocusModeEnabled => getFocusMode();
  bool get isDndScheduleEnabled => getDndSchedule();
  int get dailyScreenTimeMinutes => getDailyScreenTimeMinutes();
  int get screenTimeLimitMinutes => getScreenTimeLimitMinutes();

  Future<void> setFocusModeEnabled(bool enabled) => setFocusMode(enabled);
  Future<void> setDndScheduleEnabled(bool enabled) => setDndSchedule(enabled);
}

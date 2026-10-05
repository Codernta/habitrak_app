import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'hive_registrar.dart';

class SettingsRepository {
  final Box _box = Hive.box(HiveRegistrar.settingsBoxName);

  static const String _keyThemeMode = 'theme_mode';
  static const String _keyRemindersEnabled = 'reminders_enabled';

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
}

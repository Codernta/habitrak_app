import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../storage/settings_repository.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  final SettingsRepository settingsRepository;

  ThemeCubit({required this.settingsRepository})
    : super(settingsRepository.getThemeMode());

  void toggleTheme(bool isDark) async {
    await settingsRepository.setThemeMode(isDark);
    emit(isDark ? ThemeMode.dark : ThemeMode.light);
  }
}

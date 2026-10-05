import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/storage/hive_registrar.dart';
import 'core/storage/settings_repository.dart';
import 'features/habit/data/repositories/hive_habit_repository.dart';
import 'features/habit/presentation/bloc/habit_bloc.dart';
import 'features/mindfulness/data/repositories/reflections_repository.dart';
import 'features/mindfulness/data/repositories/intentional_goals_repository.dart';
import 'features/activity/data/repositories/activity_repository.dart';
import 'features/profile/data/repositories/profile_repository.dart';
import 'features/splash/presentation/pages/splash_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await HiveRegistrar.init();

  // Setup dependencies
  final habitRepository = HiveHabitRepository();
  final settingsRepository = SettingsRepository();
  final reflectionsRepository = ReflectionsRepository();
  final goalsRepository = IntentionalGoalsRepository();
  final activityRepository = ActivityRepository();
  final profileRepository = ProfileRepository();

  await reflectionsRepository.ensureInitialized();
  await goalsRepository.ensureInitialized();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<HiveHabitRepository>.value(value: habitRepository),
        RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
        RepositoryProvider<ReflectionsRepository>.value(
          value: reflectionsRepository,
        ),
        RepositoryProvider<IntentionalGoalsRepository>.value(
          value: goalsRepository,
        ),
        RepositoryProvider<ActivityRepository>.value(value: activityRepository),
        RepositoryProvider<ProfileRepository>.value(value: profileRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(
            create: (context) =>
                ThemeCubit(settingsRepository: settingsRepository),
          ),
          BlocProvider<HabitBloc>(
            create: (context) =>
                HabitBloc(repository: habitRepository)..add(LoadHabitsEvent()),
          ),
        ],
        child: const HabitrakApp(),
      ),
    ),
  );
}

class HabitrakApp extends StatelessWidget {
  const HabitrakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp(
          title: 'Habitrak',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          themeAnimationDuration: const Duration(milliseconds: 400),
          themeAnimationCurve: Curves.easeInOutCubic,
          home: const SplashPage(),
        );
      },
    );
  }
}

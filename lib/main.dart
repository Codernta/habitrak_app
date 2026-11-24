import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:haptic_flow/haptic_flow.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_cubit.dart';
import 'core/storage/hive_registrar.dart';
import 'core/storage/settings_repository.dart';
import 'core/services/notification_service.dart';
import 'core/services/connectivity_service.dart';
import 'core/widgets/river_flow_background.dart';
import 'core/widgets/offline_global_indicator.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/habit/data/repositories/hive_habit_repository.dart';
import 'features/habit/presentation/bloc/habit_bloc.dart';
import 'features/health/presentation/bloc/wearable_sync_bloc.dart';
import 'features/health/presentation/bloc/wearable_sync_event.dart';
import 'features/health/services/firebase_health_sync_service.dart';
import 'features/health/services/habit_automation_engine.dart';
import 'features/health/services/health_ai_service.dart';
import 'features/health/services/health_data_repository.dart';
import 'features/health/services/health_permission_service.dart';
import 'features/health/services/health_sync_local_storage.dart';
import 'core/services/background_sync_service.dart';
import 'features/mindfulness/data/repositories/reflections_repository.dart';
import 'features/mindfulness/data/repositories/intentional_goals_repository.dart';
import 'features/mindfulness/data/repositories/soulfulness_repository.dart';
import 'features/activity/data/repositories/activity_repository.dart';
import 'features/profile/data/repositories/profile_repository.dart';
import 'features/music/services/soulful_music_service.dart';
import 'features/health_news/data/repositories/health_news_repository.dart';
import 'features/splash/presentation/pages/splash_page.dart';
import 'firebase_options.dart';

final GlobalKey<NavigatorState> appNavigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with the configured project options
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Hive
  await HiveRegistrar.init();

  // Initialize Local Notifications
  final notificationService = NotificationService();
  await notificationService.initialize();
  await notificationService.requestPermissions();

  // Setup dependencies
  final habitRepository = HiveHabitRepository();
  final settingsRepository = SettingsRepository();
  HapticFlow.enabled = settingsRepository.getHapticsEnabled();
  final reflectionsRepository = ReflectionsRepository();
  final goalsRepository = IntentionalGoalsRepository();
  final soulfulnessRepository = SoulfulnessRepository();
  final activityRepository = ActivityRepository();
  final profileRepository = ProfileRepository();
  final connectivityService = ConnectivityService()..initialize();
  final musicService = SoulfulMusicService();
  final authRepository = AuthRepository();
  final healthNewsRepository = HealthNewsRepository();

  // Initialize Wearable Health & AI Services
  final healthLocalStorage = HealthSyncLocalStorage();
  await healthLocalStorage.init();
  final healthPermissionService = HealthPermissionService();
  final healthDataRepository = HealthDataRepository(localStorage: healthLocalStorage);
  final firebaseHealthSyncService = FirebaseHealthSyncService(localStorage: healthLocalStorage);
  final habitAutomationEngine = HabitAutomationEngine(
    habitRepository: habitRepository,
    localStorage: healthLocalStorage,
  );
  final healthAiService = HybridHealthAIService(
    offlineService: OfflineRuleBasedAIService(localStorage: healthLocalStorage),
  );

  // Initialize Android background sync
  await BackgroundSyncService.initialize();

  await reflectionsRepository.ensureInitialized();
  await goalsRepository.ensureInitialized();
  await soulfulnessRepository.ensureInitialized();

  runApp(
    MultiRepositoryProvider(
      providers: [
        RepositoryProvider<HiveHabitRepository>.value(value: habitRepository),
        RepositoryProvider<SettingsRepository>.value(value: settingsRepository),
        RepositoryProvider<ReflectionsRepository>.value(value: reflectionsRepository),
        RepositoryProvider<IntentionalGoalsRepository>.value(value: goalsRepository),
        RepositoryProvider<SoulfulnessRepository>.value(value: soulfulnessRepository),
        RepositoryProvider<ActivityRepository>.value(value: activityRepository),
        RepositoryProvider<ProfileRepository>.value(value: profileRepository),
        RepositoryProvider<ConnectivityService>.value(value: connectivityService),
        RepositoryProvider<SoulfulMusicService>.value(value: musicService),
        RepositoryProvider<AuthRepository>.value(value: authRepository),
        RepositoryProvider<HealthNewsRepository>.value(value: healthNewsRepository),
        RepositoryProvider<HealthPermissionService>.value(value: healthPermissionService),
        RepositoryProvider<HealthSyncLocalStorage>.value(value: healthLocalStorage),
        RepositoryProvider<HealthDataRepository>.value(value: healthDataRepository),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<ThemeCubit>(
            create: (context) => ThemeCubit(settingsRepository: settingsRepository),
          ),
          BlocProvider<AuthCubit>(
            create: (context) => AuthCubit(authRepository: authRepository),
          ),
          BlocProvider<HabitBloc>(
            create: (context) => HabitBloc(repository: habitRepository)..add(LoadHabitsEvent()),
          ),
          BlocProvider<WearableSyncBloc>(
            create: (context) => WearableSyncBloc(
              permissionService: healthPermissionService,
              healthRepository: healthDataRepository,
              localStorage: healthLocalStorage,
              cloudSyncService: firebaseHealthSyncService,
              habitAutomationEngine: habitAutomationEngine,
              aiService: healthAiService,
            )..add(InitializeWearablesEvent()),
          ),
        ],
        child: const HabitrakApp(),
      ),
    ),
  );
}

class HabitrakApp extends StatelessWidget {
  final ThemeMode? initialThemeMode;
  const HabitrakApp({super.key, this.initialThemeMode});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp(
          navigatorKey: appNavigatorKey,
          title: 'Habitrak',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          themeAnimationDuration: const Duration(milliseconds: 400),
          themeAnimationCurve: Curves.easeInOutCubic,
          builder: (context, child) {
            return HapticFeedbackBoundary(
              enabled: HapticFlow.enabled,
              child: RiverFlowBackground(
                child: OfflineGlobalIndicator(child: child ?? const SizedBox()),
              ),
            );
          },
          home: const SplashPage(),
        );
      },
    );
  }
}

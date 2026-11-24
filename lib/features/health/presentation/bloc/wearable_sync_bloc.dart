import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/models/ai_health_insight.dart';
import '../../domain/models/daily_health_summary.dart';
import '../../domain/models/device_connection_metadata.dart';
import '../../services/firebase_health_sync_service.dart';
import '../../services/habit_automation_engine.dart';
import '../../services/health_ai_service.dart';
import '../../services/health_data_repository.dart';
import '../../services/health_permission_service.dart';
import '../../services/health_sync_local_storage.dart';
import 'wearable_sync_event.dart';
import 'wearable_sync_state.dart';

class WearableSyncBloc extends Bloc<WearableSyncEvent, WearableSyncState> {
  final HealthPermissionService permissionService;
  final HealthDataRepository healthRepository;
  final HealthSyncLocalStorage localStorage;
  final FirebaseHealthSyncService cloudSyncService;
  final HabitAutomationEngine habitAutomationEngine;
  final HealthAIService aiService;

  WearableSyncBloc({
    required this.permissionService,
    required this.healthRepository,
    required this.localStorage,
    required this.cloudSyncService,
    required this.habitAutomationEngine,
    required this.aiService,
  }) : super(WearableSyncInitial()) {
    on<InitializeWearablesEvent>(_onInitialize);
    on<RequestHealthPermissionsEvent>(_onRequestPermissions);
    on<TriggerManualSyncEvent>(_onTriggerManualSync);
    on<TriggerHabitAutomationEvent>(_onTriggerHabitAutomation);
    on<GenerateAIReportEvent>(_onGenerateAIReportEvent);
  }

  static String _todayDateKey() {
    final now = DateTime.now();
    return '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  Future<void> _onInitialize(
    InitializeWearablesEvent event,
    Emitter<WearableSyncState> emit,
  ) async {
    emit(WearableSyncLoading());
    try {
      await localStorage.init();

      final platformStatus = await permissionService.checkPlatformStatus();
      final hasPerms = await permissionService.hasPermissions();

      final todayKey = _todayDateKey();
      final cachedSummary = localStorage.getDailySummary(todayKey) ??
          DailyHealthSummary(
            date: todayKey,
            lastSyncedAt: DateTime.now(),
          );

      final recentHistory = localStorage.getRecentSummaries(days: 7);
      final connectedDevices = localStorage.getConnectedDevices();
      final insights = localStorage.getInsights();

      // If no devices registered yet, register standard device connection
      if (connectedDevices.isEmpty && hasPerms) {
        final initialDevice = DeviceConnectionMetadata(
          deviceId: 'primary_${Platform.isIOS ? 'healthkit' : 'health_connect'}',
          provider: Platform.isIOS ? 'apple_healthkit' : 'android_health_connect',
          deviceModel: Platform.isIOS ? 'Apple HealthKit' : 'Android Health Connect',
          connectionStatus: 'connected',
          lastSyncTimestamp: DateTime.now(),
          platform: Platform.isIOS ? 'ios' : 'android',
        );
        await localStorage.saveConnectedDevice(initialDevice);
        connectedDevices.add(initialDevice);
      }

      emit(
        WearableSyncSuccess(
          platformStatus: platformStatus,
          hasPermissions: hasPerms,
          currentSummary: cachedSummary,
          recentHistory: recentHistory,
          connectedDevices: connectedDevices,
          latestInsight: insights.firstOrNull,
          lastSyncedAt: localStorage.getLastSyncTimestamp(),
        ),
      );

      // Auto-trigger sync if permissions are granted
      if (hasPerms) {
        add(const TriggerManualSyncEvent());
      }
    } catch (e) {
      debugPrint('WearableSyncBloc._onInitialize error: $e');
      emit(WearableSyncError('Failed to initialize wearables: $e'));
    }
  }

  Future<void> _onRequestPermissions(
    RequestHealthPermissionsEvent event,
    Emitter<WearableSyncState> emit,
  ) async {
    try {
      final result = await permissionService.requestPermissions();
      if (state is WearableSyncSuccess) {
        final current = state as WearableSyncSuccess;
        emit(
          current.copyWith(
            hasPermissions: result.isGranted,
          ),
        );
      }
      if (result.isGranted) {
        add(const TriggerManualSyncEvent());
      }
    } catch (e) {
      debugPrint('WearableSyncBloc._onRequestPermissions error: $e');
    }
  }

  Future<void> _onTriggerManualSync(
    TriggerManualSyncEvent event,
    Emitter<WearableSyncState> emit,
  ) async {
    if (state is! WearableSyncSuccess) return;
    final current = state as WearableSyncSuccess;

    emit(current.copyWith(isSyncing: true));

    try {
      final targetDate = event.date ?? DateTime.now();
      final updatedSummary = await healthRepository.syncDailyHealthData(
        date: targetDate,
      );

      // 1. Evaluate Deterministic Habit Automation
      final autoResults = await habitAutomationEngine.evaluateAndSyncHabits(
        summary: updatedSummary,
      );

      // 2. Upload to Cloud Firestore (idempotent merge)
      await cloudSyncService.syncDailySummaryToCloud(updatedSummary);

      // 3. Update device metadata
      final devices = localStorage.getConnectedDevices();
      for (final dev in devices) {
        final updatedDev = dev.copyWith(lastSyncTimestamp: DateTime.now());
        await localStorage.saveConnectedDevice(updatedDev);
        await cloudSyncService.registerDeviceMetadata(updatedDev);
      }

      final recent = localStorage.getRecentSummaries(days: 7);

      // 4. Generate AI Health Insight / Morning Briefing
      AIHealthInsight? aiInsight;
      try {
        aiInsight = await aiService.generateMorningBriefing(
          today: updatedSummary,
          recentHistory: recent,
        );
      } catch (_) {}

      emit(
        current.copyWith(
          currentSummary: updatedSummary,
          recentHistory: recent,
          connectedDevices: localStorage.getConnectedDevices(),
          latestInsight: aiInsight ?? current.latestInsight,
          lastAutomationResults: autoResults,
          isSyncing: false,
          lastSyncedAt: DateTime.now(),
        ),
      );
    } catch (e) {
      debugPrint('WearableSyncBloc._onTriggerManualSync error: $e');
      emit(current.copyWith(isSyncing: false));
    }
  }

  Future<void> _onTriggerHabitAutomation(
    TriggerHabitAutomationEvent event,
    Emitter<WearableSyncState> emit,
  ) async {
    if (state is! WearableSyncSuccess) return;
    final current = state as WearableSyncSuccess;

    final results = await habitAutomationEngine.evaluateAndSyncHabits(
      summary: current.currentSummary,
    );

    emit(current.copyWith(lastAutomationResults: results));
  }

  Future<void> _onGenerateAIReportEvent(
    GenerateAIReportEvent event,
    Emitter<WearableSyncState> emit,
  ) async {
    if (state is! WearableSyncSuccess) return;
    final current = state as WearableSyncSuccess;

    final insight = await aiService.generateMorningBriefing(
      today: current.currentSummary,
      recentHistory: current.recentHistory,
    );

    emit(current.copyWith(latestInsight: insight));
  }
}

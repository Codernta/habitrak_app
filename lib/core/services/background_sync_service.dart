import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:workmanager/workmanager.dart';
import '../../features/health/services/health_data_repository.dart';
import '../../features/health/services/health_sync_local_storage.dart';
import '../storage/hive_registrar.dart';

const String healthSyncTaskKey = 'com.app.habitrak.health_sync_task';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    debugPrint('BackgroundSyncService: Executing background task $task');
    try {
      if (task == healthSyncTaskKey) {
        await HiveRegistrar.init();
        final localStorage = HealthSyncLocalStorage();
        await localStorage.init();

        final repo = HealthDataRepository(localStorage: localStorage);
        await repo.syncDailyHealthData(date: DateTime.now());
      }
      return Future.value(true);
    } catch (e) {
      debugPrint('BackgroundSyncService: Background task failed: $e');
      return Future.value(false);
    }
  });
}

class BackgroundSyncService {
  static Future<void> initialize() async {
    if (Platform.isAndroid) {
      try {
        await Workmanager().initialize(
          callbackDispatcher,
        );

        // Register periodic sync every 6 hours with network/battery constraints
        await Workmanager().registerPeriodicTask(
          'health_periodic_sync',
          healthSyncTaskKey,
          frequency: const Duration(hours: 6),
          constraints: Constraints(
            networkType: NetworkType.connected,
            requiresBatteryNotLow: true,
          ),
          existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
        );
      } catch (e) {
        debugPrint('BackgroundSyncService: Android Workmanager init error: $e');
      }
    }
  }
}

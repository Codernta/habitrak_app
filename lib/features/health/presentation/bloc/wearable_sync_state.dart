import 'package:equatable/equatable.dart';
import '../../domain/models/ai_health_insight.dart';
import '../../domain/models/daily_health_summary.dart';
import '../../domain/models/device_connection_metadata.dart';
import '../../services/ble_wearable_service.dart';
import '../../services/habit_automation_engine.dart';
import '../../services/health_permission_service.dart';

abstract class WearableSyncState extends Equatable {
  const WearableSyncState();

  @override
  List<Object?> get props => [];
}

class WearableSyncInitial extends WearableSyncState {}

class WearableSyncLoading extends WearableSyncState {}

class WearableSyncSuccess extends WearableSyncState {
  final HealthPlatformStatus platformStatus;
  final bool hasPermissions;
  final DailyHealthSummary currentSummary;
  final List<DailyHealthSummary> recentHistory;
  final List<DeviceConnectionMetadata> connectedDevices;
  final AIHealthInsight? latestInsight;
  final List<HabitAutomationResult> lastAutomationResults;
  final bool isSyncing;
  final DateTime? lastSyncedAt;
  final bool isBleScanning;
  final List<BleDiscoveredDevice> bleDiscoveredDevices;
  final Map<String, BleTelemetrySnapshot> bleTelemetry;
  final String? bleStatusMessage;

  const WearableSyncSuccess({
    required this.platformStatus,
    required this.hasPermissions,
    required this.currentSummary,
    this.recentHistory = const [],
    this.connectedDevices = const [],
    this.latestInsight,
    this.lastAutomationResults = const [],
    this.isSyncing = false,
    this.lastSyncedAt,
    this.isBleScanning = false,
    this.bleDiscoveredDevices = const [],
    this.bleTelemetry = const {},
    this.bleStatusMessage,
  });

  WearableSyncSuccess copyWith({
    HealthPlatformStatus? platformStatus,
    bool? hasPermissions,
    DailyHealthSummary? currentSummary,
    List<DailyHealthSummary>? recentHistory,
    List<DeviceConnectionMetadata>? connectedDevices,
    AIHealthInsight? latestInsight,
    List<HabitAutomationResult>? lastAutomationResults,
    bool? isSyncing,
    DateTime? lastSyncedAt,
    bool? isBleScanning,
    List<BleDiscoveredDevice>? bleDiscoveredDevices,
    Map<String, BleTelemetrySnapshot>? bleTelemetry,
    String? bleStatusMessage,
    bool clearBleStatusMessage = false,
  }) {
    return WearableSyncSuccess(
      platformStatus: platformStatus ?? this.platformStatus,
      hasPermissions: hasPermissions ?? this.hasPermissions,
      currentSummary: currentSummary ?? this.currentSummary,
      recentHistory: recentHistory ?? this.recentHistory,
      connectedDevices: connectedDevices ?? this.connectedDevices,
      latestInsight: latestInsight ?? this.latestInsight,
      lastAutomationResults:
          lastAutomationResults ?? this.lastAutomationResults,
      isSyncing: isSyncing ?? this.isSyncing,
      lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
      isBleScanning: isBleScanning ?? this.isBleScanning,
      bleDiscoveredDevices: bleDiscoveredDevices ?? this.bleDiscoveredDevices,
      bleTelemetry: bleTelemetry ?? this.bleTelemetry,
      bleStatusMessage: clearBleStatusMessage
          ? null
          : (bleStatusMessage ?? this.bleStatusMessage),
    );
  }

  @override
  List<Object?> get props => [
        platformStatus,
        hasPermissions,
        currentSummary,
        recentHistory,
        connectedDevices,
        latestInsight,
        lastAutomationResults,
        isSyncing,
        lastSyncedAt,
        isBleScanning,
        bleDiscoveredDevices,
        bleTelemetry,
        bleStatusMessage,
      ];
}

class WearableSyncError extends WearableSyncState {
  final String message;
  const WearableSyncError(this.message);

  @override
  List<Object?> get props => [message];
}

import 'package:equatable/equatable.dart';
import '../../services/ble_wearable_service.dart';

abstract class WearableSyncEvent extends Equatable {
  const WearableSyncEvent();

  @override
  List<Object?> get props => [];
}

class InitializeWearablesEvent extends WearableSyncEvent {}

class RequestHealthPermissionsEvent extends WearableSyncEvent {}

class TriggerManualSyncEvent extends WearableSyncEvent {
  final DateTime? date;
  const TriggerManualSyncEvent({this.date});

  @override
  List<Object?> get props => [date];
}

class TriggerHabitAutomationEvent extends WearableSyncEvent {}

class GenerateAIReportEvent extends WearableSyncEvent {}

class StartBleScanEvent extends WearableSyncEvent {}

class StopBleScanEvent extends WearableSyncEvent {}

class ConnectBleDeviceEvent extends WearableSyncEvent {
  final BleDiscoveredDevice device;
  const ConnectBleDeviceEvent(this.device);

  @override
  List<Object?> get props => [device.id];
}

class DisconnectBleDeviceEvent extends WearableSyncEvent {
  final String deviceId;
  const DisconnectBleDeviceEvent(this.deviceId);

  @override
  List<Object?> get props => [deviceId];
}

class BleScanUpdatedEvent extends WearableSyncEvent {
  final List<BleDiscoveredDevice> devices;
  final bool? isScanning;
  const BleScanUpdatedEvent({required this.devices, this.isScanning});

  @override
  List<Object?> get props => [devices, isScanning];
}

class BleTelemetryUpdatedEvent extends WearableSyncEvent {
  final Map<String, BleTelemetrySnapshot> telemetry;
  const BleTelemetryUpdatedEvent(this.telemetry);

  @override
  List<Object?> get props => [telemetry];
}

import 'package:equatable/equatable.dart';

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

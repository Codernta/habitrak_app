import 'package:equatable/equatable.dart';

class DeviceConnectionMetadata extends Equatable {
  final String deviceId;
  final String provider; // 'apple_healthkit', 'android_health_connect', 'garmin', etc.
  final String deviceModel;
  final String connectionStatus; // 'connected', 'disconnected', 'syncing'
  final DateTime lastSyncTimestamp;
  final List<String> grantedPermissions;
  final String platform;

  const DeviceConnectionMetadata({
    required this.deviceId,
    required this.provider,
    required this.deviceModel,
    this.connectionStatus = 'connected',
    required this.lastSyncTimestamp,
    this.grantedPermissions = const [],
    required this.platform,
  });

  Map<String, dynamic> toMap() {
    return {
      'deviceId': deviceId,
      'provider': provider,
      'deviceModel': deviceModel,
      'connectionStatus': connectionStatus,
      'lastSyncTimestamp': lastSyncTimestamp.toIso8601String(),
      'grantedPermissions': grantedPermissions,
      'platform': platform,
    };
  }

  factory DeviceConnectionMetadata.fromMap(Map<dynamic, dynamic> map) {
    return DeviceConnectionMetadata(
      deviceId: map['deviceId'] as String,
      provider: map['provider'] as String,
      deviceModel: map['deviceModel'] as String,
      connectionStatus: map['connectionStatus'] as String? ?? 'connected',
      lastSyncTimestamp: DateTime.parse(map['lastSyncTimestamp'] as String),
      grantedPermissions: (map['grantedPermissions'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      platform: map['platform'] as String,
    );
  }

  DeviceConnectionMetadata copyWith({
    String? deviceId,
    String? provider,
    String? deviceModel,
    String? connectionStatus,
    DateTime? lastSyncTimestamp,
    List<String>? grantedPermissions,
    String? platform,
  }) {
    return DeviceConnectionMetadata(
      deviceId: deviceId ?? this.deviceId,
      provider: provider ?? this.provider,
      deviceModel: deviceModel ?? this.deviceModel,
      connectionStatus: connectionStatus ?? this.connectionStatus,
      lastSyncTimestamp: lastSyncTimestamp ?? this.lastSyncTimestamp,
      grantedPermissions: grantedPermissions ?? this.grantedPermissions,
      platform: platform ?? this.platform,
    );
  }

  @override
  List<Object?> get props => [
        deviceId,
        provider,
        deviceModel,
        connectionStatus,
        lastSyncTimestamp,
        grantedPermissions,
        platform,
      ];
}

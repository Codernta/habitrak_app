import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:health/health.dart';

enum HealthPlatformStatus {
  available,
  updateRequired,
  unavailable,
}

enum HealthPermissionState {
  notRequested,
  granted,
  partiallyGranted,
  denied,
  unsupported,
}

class HealthPermissionResult {
  final HealthPermissionState state;
  final List<HealthDataType> grantedTypes;
  final List<HealthDataType> deniedTypes;
  final String? message;

  const HealthPermissionResult({
    required this.state,
    this.grantedTypes = const [],
    this.deniedTypes = const [],
    this.message,
  });

  bool get isGranted => state == HealthPermissionState.granted;
}

class HealthPermissionService {
  final Health _health;
  final bool? _isAndroidOverride;
  final bool? _isIOSOverride;

  HealthPermissionService({
    Health? health,
    bool? isAndroidOverride,
    bool? isIOSOverride,
  })  : _health = health ?? Health(),
        _isAndroidOverride = isAndroidOverride,
        _isIOSOverride = isIOSOverride;

  bool get _isAndroid => _isAndroidOverride ?? Platform.isAndroid;
  bool get _isIOS => _isIOSOverride ?? Platform.isIOS;

  /// Default core data types Habitrak tracks from smart wearables
  static const List<HealthDataType> defaultHealthTypes = [
    HealthDataType.STEPS,
    HealthDataType.HEART_RATE,
    HealthDataType.RESTING_HEART_RATE,
    HealthDataType.ACTIVE_ENERGY_BURNED,
    HealthDataType.DISTANCE_WALKING_RUNNING,
    HealthDataType.WORKOUT,
    HealthDataType.SLEEP_SESSION,
    HealthDataType.SLEEP_ASLEEP,
    HealthDataType.SLEEP_DEEP,
    HealthDataType.SLEEP_LIGHT,
    HealthDataType.SLEEP_REM,
  ];

  /// Checks if the underlying OS health platform (HealthKit or Health Connect) is available.
  Future<HealthPlatformStatus> checkPlatformStatus() async {
    try {
      if (_isAndroid) {
        final status = await _health.getHealthConnectSdkStatus();
        switch (status) {
          case HealthConnectSdkStatus.sdkAvailable:
            return HealthPlatformStatus.available;
          case HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired:
            return HealthPlatformStatus.updateRequired;
          default:
            return HealthPlatformStatus.unavailable;
        }
      } else if (_isIOS) {
        // HealthKit is standard on all modern iOS devices
        return HealthPlatformStatus.available;
      }
      return HealthPlatformStatus.unavailable;
    } catch (e) {
      debugPrint('HealthPermissionService.checkPlatformStatus error: $e');
      return HealthPlatformStatus.unavailable;
    }
  }

  /// Prompts Google Play Store installation of Health Connect (Android 9–13)
  Future<void> installHealthConnect() async {
    if (_isAndroid) {
      try {
        await _health.installHealthConnect();
      } catch (e) {
        debugPrint('HealthPermissionService.installHealthConnect error: $e');
      }
    }
  }

  /// Checks whether Habitrak currently has authorization for the specified types.
  Future<bool> hasPermissions({List<HealthDataType>? types}) async {
    try {
      final targetTypes = types ?? defaultHealthTypes;
      final permissions = List<HealthDataAccess>.filled(
        targetTypes.length,
        HealthDataAccess.READ,
      );
      final hasPerm = await _health.hasPermissions(
        targetTypes,
        permissions: permissions,
      );
      return hasPerm ?? false;
    } catch (e) {
      debugPrint('HealthPermissionService.hasPermissions error: $e');
      return false;
    }
  }

  /// Requests permission to read specified wearable health data types.
  Future<HealthPermissionResult> requestPermissions({
    List<HealthDataType>? types,
    bool requestWriteForMindfulness = false,
  }) async {
    try {
      final platformStatus = await checkPlatformStatus();
      if (platformStatus == HealthPlatformStatus.unavailable) {
        return const HealthPermissionResult(
          state: HealthPermissionState.unsupported,
          message: 'Health platform is not available on this device.',
        );
      } else if (platformStatus == HealthPlatformStatus.updateRequired) {
        return const HealthPermissionResult(
          state: HealthPermissionState.unsupported,
          message: 'Health Connect requires an update from the Play Store.',
        );
      }

      final targetTypes = types ?? defaultHealthTypes;
      final permissions = targetTypes.map((type) {
        if (requestWriteForMindfulness &&
            (type == HealthDataType.MINDFULNESS || type == HealthDataType.WORKOUT)) {
          return HealthDataAccess.READ_WRITE;
        }
        return HealthDataAccess.READ;
      }).toList();

      final authorized = await _health.requestAuthorization(
        targetTypes,
        permissions: permissions,
      );

      if (authorized) {
        return HealthPermissionResult(
          state: HealthPermissionState.granted,
          grantedTypes: targetTypes,
          message: 'Health permissions granted successfully.',
        );
      } else {
        // Re-check what might have been partially granted
        final hasAny = await hasPermissions(types: targetTypes);
        return HealthPermissionResult(
          state: hasAny
              ? HealthPermissionState.partiallyGranted
              : HealthPermissionState.denied,
          message: hasAny
              ? 'Partial health permissions granted.'
              : 'Health permissions were declined.',
        );
      }
    } catch (e) {
      debugPrint('HealthPermissionService.requestPermissions error: $e');
      return HealthPermissionResult(
        state: HealthPermissionState.denied,
        message: 'Failed to request permissions: $e',
      );
    }
  }

  /// Request authorization for background health data queries (Android 14+ / iOS)
  Future<bool> requestBackgroundAuthorization() async {
    try {
      if (_isAndroid) {
        final available = await _health.isHealthDataInBackgroundAvailable();
        if (available) {
          return await _health.requestHealthDataInBackgroundAuthorization();
        }
      }
      return true;
    } catch (e) {
      debugPrint('HealthPermissionService.requestBackgroundAuthorization error: $e');
      return false;
    }
  }
}

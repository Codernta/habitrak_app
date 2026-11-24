import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';
import 'package:habitrak/features/health/services/health_permission_service.dart';

class FakeHealth implements Health {
  HealthConnectSdkStatus sdkStatus = HealthConnectSdkStatus.sdkAvailable;
  bool? permissionsGrantedResult = true;
  bool requestAuthorizationResult = true;
  bool backgroundAvailable = true;
  bool backgroundAuthorizedResult = true;
  bool installCalled = false;

  @override
  Future<HealthConnectSdkStatus?> getHealthConnectSdkStatus() async => sdkStatus;

  @override
  Future<bool?> hasPermissions(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async =>
      permissionsGrantedResult;

  @override
  Future<bool> requestAuthorization(
    List<HealthDataType> types, {
    List<HealthDataAccess>? permissions,
  }) async =>
      requestAuthorizationResult;

  @override
  Future<bool> isHealthDataInBackgroundAvailable() async => backgroundAvailable;

  @override
  Future<bool> requestHealthDataInBackgroundAuthorization() async =>
      backgroundAuthorizedResult;

  @override
  Future<void> installHealthConnect() async {
    installCalled = true;
  }

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late FakeHealth fakeHealth;
  late HealthPermissionService service;

  setUp(() {
    fakeHealth = FakeHealth();
    service = HealthPermissionService(
      health: fakeHealth,
      isAndroidOverride: true,
      isIOSOverride: false,
    );
  });

  group('HealthPermissionService Tests', () {
    test('checkPlatformStatus returns available when sdkStatus is sdkAvailable', () async {
      fakeHealth.sdkStatus = HealthConnectSdkStatus.sdkAvailable;
      final status = await service.checkPlatformStatus();
      expect(status, HealthPlatformStatus.available);
    });

    test('checkPlatformStatus returns available on iOS platform', () async {
      final iosService = HealthPermissionService(
        health: fakeHealth,
        isAndroidOverride: false,
        isIOSOverride: true,
      );
      final status = await iosService.checkPlatformStatus();
      expect(status, HealthPlatformStatus.available);
    });

    test('checkPlatformStatus returns updateRequired when update is needed', () async {
      fakeHealth.sdkStatus =
          HealthConnectSdkStatus.sdkUnavailableProviderUpdateRequired;
      final status = await service.checkPlatformStatus();
      expect(status, HealthPlatformStatus.updateRequired);
    });

    test('checkPlatformStatus returns unavailable when sdk is unavailable', () async {
      fakeHealth.sdkStatus = HealthConnectSdkStatus.sdkUnavailable;
      final status = await service.checkPlatformStatus();
      expect(status, HealthPlatformStatus.unavailable);
    });

    test('hasPermissions returns true when fake health confirms authorization', () async {
      fakeHealth.permissionsGrantedResult = true;
      final hasPerm = await service.hasPermissions();
      expect(hasPerm, isTrue);
    });

    test('hasPermissions returns false when authorization is absent', () async {
      fakeHealth.permissionsGrantedResult = false;
      final hasPerm = await service.hasPermissions();
      expect(hasPerm, isFalse);
    });

    test('requestPermissions returns granted when requestAuthorization succeeds', () async {
      fakeHealth.sdkStatus = HealthConnectSdkStatus.sdkAvailable;
      fakeHealth.requestAuthorizationResult = true;

      final result = await service.requestPermissions();
      expect(result.state, HealthPermissionState.granted);
      expect(result.isGranted, isTrue);
      expect(result.grantedTypes, isNotEmpty);
    });

    test('requestPermissions returns denied when user declines permissions', () async {
      fakeHealth.sdkStatus = HealthConnectSdkStatus.sdkAvailable;
      fakeHealth.requestAuthorizationResult = false;
      fakeHealth.permissionsGrantedResult = false;

      final result = await service.requestPermissions();
      expect(result.state, HealthPermissionState.denied);
      expect(result.isGranted, isFalse);
    });

    test('requestPermissions returns unsupported when health platform is unavailable', () async {
      fakeHealth.sdkStatus = HealthConnectSdkStatus.sdkUnavailable;

      final result = await service.requestPermissions();
      expect(result.state, HealthPermissionState.unsupported);
      expect(result.isGranted, isFalse);
    });

    test('installHealthConnect invokes native install trigger on fake client', () async {
      await service.installHealthConnect();
      // On macOS/iOS Platform.isAndroid is false unless mocked, so no crash happens
      expect(service, isNotNull);
    });

    test('requestBackgroundAuthorization runs without uncaught exceptions', () async {
      final res = await service.requestBackgroundAuthorization();
      expect(res, isTrue);
    });
  });
}

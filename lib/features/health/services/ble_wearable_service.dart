import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import '../domain/models/device_connection_metadata.dart';
import '../domain/models/health_metric_type.dart';
import '../domain/models/normalized_health_record.dart';

/// Standard Bluetooth SIG GATT Service & Characteristic UUIDs (16-bit short forms)
class BleGattUuids {
  static const String heartRateService = '180d';
  static const String heartRateMeasurement = '2a37';

  static const String batteryService = '180f';
  static const String batteryLevel = '2a19';

  static const String deviceInfoService = '180a';
  static const String manufacturerName = '2a29';
  static const String modelNumber = '2a24';

  static const String rscService = '1814'; // Running Speed and Cadence
  static const String rscMeasurement = '2a53';

  static const String pulseOximeterService = '1822';
  static const String plxSpotCheck = '2a5e';
  static const String plxContinuous = '2a5f';
}

class BleDiscoveredDevice {
  final String id;
  final String name;
  final int rssi;
  final List<String> serviceUuids;
  final BluetoothDevice device;

  const BleDiscoveredDevice({
    required this.id,
    required this.name,
    required this.rssi,
    required this.serviceUuids,
    required this.device,
  });

  bool get isHealthWearable {
    const healthServices = {
      BleGattUuids.heartRateService,
      BleGattUuids.rscService,
      BleGattUuids.pulseOximeterService,
      '1816', // Cycling Speed & Cadence
      '1809', // Health Thermometer
      '181a', // Environmental Sensing
    };
    return serviceUuids.any((u) => healthServices.contains(u.toLowerCase()));
  }
}

class BleTelemetrySnapshot {
  final String deviceId;
  final String deviceName;
  final int? heartRateBpm;
  final double? hrvRmssdMs;
  final int? spo2Percent;
  final int? cadenceSpm;
  final int? batteryPercent;
  final DateTime updatedAt;

  const BleTelemetrySnapshot({
    required this.deviceId,
    required this.deviceName,
    this.heartRateBpm,
    this.hrvRmssdMs,
    this.spo2Percent,
    this.cadenceSpm,
    this.batteryPercent,
    required this.updatedAt,
  });

  BleTelemetrySnapshot copyWith({
    int? heartRateBpm,
    double? hrvRmssdMs,
    int? spo2Percent,
    int? cadenceSpm,
    int? batteryPercent,
    DateTime? updatedAt,
  }) {
    return BleTelemetrySnapshot(
      deviceId: deviceId,
      deviceName: deviceName,
      heartRateBpm: heartRateBpm ?? this.heartRateBpm,
      hrvRmssdMs: hrvRmssdMs ?? this.hrvRmssdMs,
      spo2Percent: spo2Percent ?? this.spo2Percent,
      cadenceSpm: cadenceSpm ?? this.cadenceSpm,
      batteryPercent: batteryPercent ?? this.batteryPercent,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

/// Manages direct Bluetooth Low Energy (BLE) & IoT wearable connections,
/// GATT service discovery, and real-time physiological telemetry parsing.
class BleWearableService {
  final Map<String, BluetoothDevice> _connectedDevices = {};
  final Map<String, BleTelemetrySnapshot> _telemetryByDevice = {};
  final Map<String, List<StreamSubscription<dynamic>>> _deviceSubscriptions = {};
  final List<NormalizedHealthRecord> _bufferedRecords = [];

  final StreamController<List<BleDiscoveredDevice>> _scanResultsController =
      StreamController<List<BleDiscoveredDevice>>.broadcast();
  final StreamController<Map<String, BleTelemetrySnapshot>> _telemetryController =
      StreamController<Map<String, BleTelemetrySnapshot>>.broadcast();
  final StreamController<bool> _scanningController =
      StreamController<bool>.broadcast();

  StreamSubscription<List<ScanResult>>? _scanSub;
  StreamSubscription<bool>? _isScanningSub;

  Stream<BluetoothAdapterState> get adapterStateStream =>
      FlutterBluePlus.adapterState;
  Stream<List<BleDiscoveredDevice>> get scanResultsStream =>
      _scanResultsController.stream;
  Stream<Map<String, BleTelemetrySnapshot>> get telemetryStream =>
      _telemetryController.stream;
  Stream<bool> get isScanningStream => _scanningController.stream;

  Map<String, BleTelemetrySnapshot> get currentTelemetry =>
      Map.unmodifiable(_telemetryByDevice);
  List<BluetoothDevice> get connectedDevices =>
      _connectedDevices.values.toList();

  /// Requests OS Bluetooth & BLE scan/connect permissions.
  Future<bool> requestBlePermissions() async {
    try {
      if (Platform.isAndroid) {
        final statuses = await [
          Permission.bluetoothScan,
          Permission.bluetoothConnect,
          Permission.locationWhenInUse,
        ].request();

        final scanOk = statuses[Permission.bluetoothScan]?.isGranted ?? false;
        final connectOk =
            statuses[Permission.bluetoothConnect]?.isGranted ?? false;
        // On Android < 12, bluetoothScan/Connect may be unavailable and location is used
        final legacyOk =
            statuses[Permission.locationWhenInUse]?.isGranted ?? false;
        return (scanOk && connectOk) || legacyOk;
      }
      // On iOS/macOS, CoreBluetooth handles permission prompts on adapter/scan access.
      final adapterState = await FlutterBluePlus.adapterState.first;
      return adapterState != BluetoothAdapterState.unauthorized;
    } catch (e) {
      debugPrint('BleWearableService.requestBlePermissions error: $e');
      return false;
    }
  }

  /// Starts scanning for nearby BLE health & IoT peripherals.
  Future<void> startScan({
    Duration timeout = const Duration(seconds: 12),
  }) async {
    final granted = await requestBlePermissions();
    if (!granted) {
      throw Exception('Bluetooth permissions were denied.');
    }

    final adapterState = await FlutterBluePlus.adapterState.first;
    if (adapterState != BluetoothAdapterState.on) {
      if (Platform.isAndroid) {
        await FlutterBluePlus.turnOn();
      } else {
        throw Exception('Please turn on Bluetooth to scan for IoT wearables.');
      }
    }

    await _scanSub?.cancel();
    await _isScanningSub?.cancel();

    _isScanningSub = FlutterBluePlus.isScanning.listen((scanning) {
      _scanningController.add(scanning);
    });

    final seen = <String, BleDiscoveredDevice>{};
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      for (final r in results) {
        final advName = r.advertisementData.advName.trim();
        final platName = r.device.platformName.trim();
        final name = advName.isNotEmpty
            ? advName
            : (platName.isNotEmpty ? platName : '');
        final uuids = r.advertisementData.serviceUuids
            .map((g) => g.str128.toLowerCase())
            .toList();

        // Filter out unnamed generic beacons unless they advertise health GATT services
        final candidate = BleDiscoveredDevice(
          id: r.device.remoteId.str,
          name: name.isNotEmpty ? name : 'BLE Sensor (${r.device.remoteId.str.substring(0, math.min(5, r.device.remoteId.str.length))})',
          rssi: r.rssi,
          serviceUuids: r.advertisementData.serviceUuids
              .map((g) => g.toString().toLowerCase())
              .toList(),
          device: r.device,
        );

        if (name.isNotEmpty || candidate.isHealthWearable || uuids.isNotEmpty) {
          seen[candidate.id] = candidate;
        }
      }

      final sorted = seen.values.toList()
        ..sort((a, b) {
          if (a.isHealthWearable != b.isHealthWearable) {
            return a.isHealthWearable ? -1 : 1;
          }
          return b.rssi.compareTo(a.rssi);
        });
      _scanResultsController.add(sorted);
    });

    await FlutterBluePlus.startScan(timeout: timeout);
  }

  Future<void> stopScan() async {
    try {
      await FlutterBluePlus.stopScan();
    } catch (e) {
      debugPrint('BleWearableService.stopScan error: $e');
    }
  }

  /// Connects to a BLE peripheral, discovers GATT services, reads device metadata,
  /// and subscribes to physiological telemetry characteristics.
  Future<DeviceConnectionMetadata> connectDevice(BluetoothDevice device) async {
    final deviceId = device.remoteId.str;
    await stopScan();

    await device.connect(timeout: const Duration(seconds: 15));
    _connectedDevices[deviceId] = device;

    final subs = <StreamSubscription<dynamic>>[];
    subs.add(
      device.connectionState.listen((state) {
        if (state == BluetoothConnectionState.disconnected) {
          _handleRemoteDisconnect(deviceId);
        }
      }),
    );

    final services = await device.discoverServices();
    String deviceName = device.platformName.isNotEmpty
        ? device.platformName
        : 'BLE Wearable';
    String? manufacturer;
    String? modelNumber;
    int? batteryPercent;
    final discoveredCapabilities = <String>[];

    for (final service in services) {
      final svcUuid = service.uuid.toString().toLowerCase();

      if (_matchesUuid(svcUuid, BleGattUuids.deviceInfoService)) {
        for (final c in service.characteristics) {
          final charUuid = c.uuid.toString().toLowerCase();
          if (_matchesUuid(charUuid, BleGattUuids.manufacturerName) &&
              c.properties.read) {
            final bytes = await _safeRead(c);
            if (bytes.isNotEmpty) {
              manufacturer = String.fromCharCodes(bytes).trim();
            }
          } else if (_matchesUuid(charUuid, BleGattUuids.modelNumber) &&
              c.properties.read) {
            final bytes = await _safeRead(c);
            if (bytes.isNotEmpty) {
              modelNumber = String.fromCharCodes(bytes).trim();
            }
          }
        }
      } else if (_matchesUuid(svcUuid, BleGattUuids.batteryService)) {
        for (final c in service.characteristics) {
          if (_matchesUuid(c.uuid.toString(), BleGattUuids.batteryLevel)) {
            if (c.properties.read) {
              final bytes = await _safeRead(c);
              if (bytes.isNotEmpty) {
                batteryPercent = bytes[0].clamp(0, 100);
              }
            }
            if (c.properties.notify) {
              await _safeNotify(c);
              subs.add(
                c.lastValueStream.listen((bytes) {
                  if (bytes.isNotEmpty) {
                    _updateTelemetry(
                      deviceId,
                      deviceName,
                      batteryPercent: bytes[0].clamp(0, 100),
                    );
                  }
                }),
              );
            }
          }
        }
      } else if (_matchesUuid(svcUuid, BleGattUuids.heartRateService)) {
        discoveredCapabilities.add('heart_rate');
        for (final c in service.characteristics) {
          if (_matchesUuid(
                  c.uuid.toString(), BleGattUuids.heartRateMeasurement) &&
              c.properties.notify) {
            await _safeNotify(c);
            subs.add(
              c.lastValueStream.listen((bytes) {
                _parseHeartRateMeasurement(deviceId, deviceName, bytes);
              }),
            );
          }
        }
      } else if (_matchesUuid(svcUuid, BleGattUuids.pulseOximeterService)) {
        discoveredCapabilities.add('spo2');
        for (final c in service.characteristics) {
          final charUuid = c.uuid.toString().toLowerCase();
          if ((_matchesUuid(charUuid, BleGattUuids.plxSpotCheck) ||
                  _matchesUuid(charUuid, BleGattUuids.plxContinuous)) &&
              (c.properties.notify || c.properties.indicate)) {
            await _safeNotify(c);
            subs.add(
              c.lastValueStream.listen((bytes) {
                _parsePulseOximeter(deviceId, deviceName, bytes);
              }),
            );
          }
        }
      } else if (_matchesUuid(svcUuid, BleGattUuids.rscService)) {
        discoveredCapabilities.add('running_cadence');
        for (final c in service.characteristics) {
          if (_matchesUuid(c.uuid.toString(), BleGattUuids.rscMeasurement) &&
              c.properties.notify) {
            await _safeNotify(c);
            subs.add(
              c.lastValueStream.listen((bytes) {
                _parseRscMeasurement(deviceId, deviceName, bytes);
              }),
            );
          }
        }
      }
    }

    _deviceSubscriptions[deviceId] = subs;

    final fullModel = [
      if (manufacturer != null && manufacturer.isNotEmpty) manufacturer,
      if (modelNumber != null && modelNumber.isNotEmpty) modelNumber,
    ].join(' ');
    final resolvedModel =
        fullModel.isNotEmpty ? fullModel : deviceName;

    _updateTelemetry(
      deviceId,
      resolvedModel,
      batteryPercent: batteryPercent,
    );

    return DeviceConnectionMetadata(
      deviceId: deviceId,
      provider: 'ble_iot',
      deviceModel: resolvedModel,
      connectionStatus: 'connected',
      lastSyncTimestamp: DateTime.now(),
      grantedPermissions: discoveredCapabilities,
      platform: Platform.isIOS ? 'ios' : 'android',
    );
  }

  Future<void> disconnectDevice(String deviceId) async {
    final subs = _deviceSubscriptions.remove(deviceId) ?? [];
    for (final s in subs) {
      await s.cancel();
    }
    final device = _connectedDevices.remove(deviceId);
    if (device != null) {
      try {
        await device.disconnect();
      } catch (e) {
        debugPrint('BleWearableService.disconnectDevice error: $e');
      }
    }
    _telemetryByDevice.remove(deviceId);
    _telemetryController.add(Map.unmodifiable(_telemetryByDevice));
  }

  void _handleRemoteDisconnect(String deviceId) {
    final subs = _deviceSubscriptions.remove(deviceId) ?? [];
    for (final s in subs) {
      s.cancel();
    }
    _connectedDevices.remove(deviceId);
    _telemetryByDevice.remove(deviceId);
    _telemetryController.add(Map.unmodifiable(_telemetryByDevice));
  }

  /// Drains buffered physiological records captured from BLE GATT notifications.
  List<NormalizedHealthRecord> drainBufferedRecords() {
    if (_bufferedRecords.isEmpty) return const [];
    final copy = List<NormalizedHealthRecord>.from(_bufferedRecords);
    _bufferedRecords.clear();
    return copy;
  }

  /// Parses Bluetooth SIG Heart Rate Measurement (0x2A37) payload.
  void _parseHeartRateMeasurement(
    String deviceId,
    String deviceName,
    List<int> bytes,
  ) {
    if (bytes.length < 2) return;
    final flags = bytes[0];
    final isUint16 = (flags & 0x01) != 0;
    final hasEnergyExpended = (flags & 0x08) != 0;
    final hasRrIntervals = (flags & 0x10) != 0;

    int offset = 1;
    final int bpm;
    if (isUint16) {
      if (bytes.length < 3) return;
      bpm = bytes[1] | (bytes[2] << 8);
      offset = 3;
    } else {
      bpm = bytes[1];
      offset = 2;
    }

    if (hasEnergyExpended) {
      offset += 2;
    }

    double? rmssdMs;
    if (hasRrIntervals && offset + 1 < bytes.length) {
      final rrIntervalsMs = <double>[];
      while (offset + 1 < bytes.length) {
        final rawRr = bytes[offset] | (bytes[offset + 1] << 8);
        // Resolution is 1/1024 seconds -> convert to milliseconds
        rrIntervalsMs.add((rawRr / 1024.0) * 1000.0);
        offset += 2;
      }
      if (rrIntervalsMs.length >= 2) {
        double sumSqDiff = 0;
        for (int i = 1; i < rrIntervalsMs.length; i++) {
          final diff = rrIntervalsMs[i] - rrIntervalsMs[i - 1];
          sumSqDiff += diff * diff;
        }
        rmssdMs = math.sqrt(sumSqDiff / (rrIntervalsMs.length - 1));
      }
    }

    if (bpm > 25 && bpm < 240) {
      _updateTelemetry(
        deviceId,
        deviceName,
        heartRateBpm: bpm,
        hrvRmssdMs: rmssdMs,
      );
      _recordMetric(
        deviceId: deviceId,
        deviceName: deviceName,
        type: HealthMetricType.heartRate,
        value: bpm.toDouble(),
      );
    }
  }

  /// Parses Bluetooth SIG Pulse Oximeter (0x2A5E / 0x2A5F) IEEE-11073 SFLOAT SpO2.
  void _parsePulseOximeter(
    String deviceId,
    String deviceName,
    List<int> bytes,
  ) {
    if (bytes.length < 3) return;
    final rawSfloat = bytes[1] | (bytes[2] << 8);
    final spo2 = _decodeSfloat(rawSfloat);
    if (spo2 >= 70 && spo2 <= 100) {
      final rounded = spo2.round();
      _updateTelemetry(deviceId, deviceName, spo2Percent: rounded);
      _recordMetric(
        deviceId: deviceId,
        deviceName: deviceName,
        type: HealthMetricType.oxygenSaturation,
        value: spo2,
      );
    }
  }

  /// Parses Bluetooth SIG Running Speed & Cadence (0x2A53) payload.
  void _parseRscMeasurement(
    String deviceId,
    String deviceName,
    List<int> bytes,
  ) {
    if (bytes.length < 4) return;
    // bytes[0]: flags, bytes[1..2]: instant speed (uint16, 1/256 m/s), bytes[3]: instant cadence (uint8, rpm/spm)
    final cadence = bytes[3];
    _updateTelemetry(deviceId, deviceName, cadenceSpm: cadence);
  }

  double _decodeSfloat(int raw) {
    int mantissa = raw & 0x0FFF;
    if ((mantissa & 0x0800) != 0) mantissa -= 0x1000;
    int exponent = (raw >> 12) & 0x0F;
    if ((exponent & 0x08) != 0) exponent -= 0x10;
    return mantissa * math.pow(10, exponent).toDouble();
  }

  void _recordMetric({
    required String deviceId,
    required String deviceName,
    required HealthMetricType type,
    required double value,
  }) {
    final now = DateTime.now();
    final dateKey =
        '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    _bufferedRecords.add(
      NormalizedHealthRecord(
        id: 'ble_${deviceId}_${type.name}_${now.millisecondsSinceEpoch}',
        metricType: type,
        value: value,
        unit: type.defaultUnit,
        startTime: now,
        endTime: now,
        sourceApp: 'ble_iot',
        sourceDevice: deviceName,
        platform: Platform.isIOS ? 'ios' : 'android',
        recordingDate: dateKey,
        syncedAt: now,
      ),
    );
  }

  void _updateTelemetry(
    String deviceId,
    String deviceName, {
    int? heartRateBpm,
    double? hrvRmssdMs,
    int? spo2Percent,
    int? cadenceSpm,
    int? batteryPercent,
  }) {
    final existing = _telemetryByDevice[deviceId] ??
        BleTelemetrySnapshot(
          deviceId: deviceId,
          deviceName: deviceName,
          updatedAt: DateTime.now(),
        );
    _telemetryByDevice[deviceId] = existing.copyWith(
      heartRateBpm: heartRateBpm,
      hrvRmssdMs: hrvRmssdMs,
      spo2Percent: spo2Percent,
      cadenceSpm: cadenceSpm,
      batteryPercent: batteryPercent,
      updatedAt: DateTime.now(),
    );
    _telemetryController.add(Map.unmodifiable(_telemetryByDevice));
  }

  Future<List<int>> _safeRead(BluetoothCharacteristic c) async {
    try {
      return await c.read();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _safeNotify(BluetoothCharacteristic c) async {
    try {
      await c.setNotifyValue(true);
    } catch (e) {
      debugPrint('BleWearableService._safeNotify error: $e');
    }
  }

  bool _matchesUuid(String fullOrShort, String shortHex) {
    final lower = fullOrShort.toLowerCase();
    final target = shortHex.toLowerCase();
    return lower == target ||
        lower.startsWith('0000$target-') ||
        lower.contains(target);
  }

  Future<void> dispose() async {
    await _scanSub?.cancel();
    await _isScanningSub?.cancel();
    for (final deviceId in _connectedDevices.keys.toList()) {
      await disconnectDevice(deviceId);
    }
    await _scanResultsController.close();
    await _telemetryController.close();
    await _scanningController.close();
  }
}

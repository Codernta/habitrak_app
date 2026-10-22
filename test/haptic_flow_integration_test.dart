import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:haptic_flow/haptic_flow.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habitrak/core/storage/hive_registrar.dart';
import 'package:habitrak/core/storage/settings_repository.dart';
import 'package:habitrak/core/widgets/tactile_studio_sheet.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockHapticDriver mockDriver;
  late Directory tempDir;

  setUp(() async {
    mockDriver = MockHapticDriver();
    HapticFlow.driver = mockDriver;
    HapticFlow.enabled = true;

    tempDir = await Directory.systemTemp.createTemp('haptic_test_');
    Hive.init(tempDir.path);
    await Hive.openBox(HiveRegistrar.settingsBoxName);
  });

  tearDown(() async {
    HapticFlow.stop();
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('HapticFlow Core & Choreography Tests', () {
    test('MockHapticDriver records basic pulses correctly', () async {
      await HapticFlow.light();
      await HapticFlow.medium();
      await HapticFlow.heavy();
      await HapticFlow.selection();

      expect(mockDriver.recordedTypes, [
        HapticStepType.light,
        HapticStepType.medium,
        HapticStepType.heavy,
        HapticStepType.selection,
      ]);
    });

    test('Plays HapticPresets.successSnap and records steps', () async {
      await HapticFlow.play(HapticPresets.successSnap);

      expect(mockDriver.recordedTypes, [
        HapticStepType.light,
        HapticStepType.medium,
      ]);
    });

    test('Plays HapticPresets.warningBuzz', () async {
      await HapticFlow.play(HapticPresets.warningBuzz);

      expect(mockDriver.recordedTypes, [
        HapticStepType.medium,
        HapticStepType.medium,
      ]);
    });

    test('Plays shorthand pattern string correctly', () async {
      final sequence = HapticSequence.fromPattern(
        '.-=*',
        tickDuration: const Duration(milliseconds: 5),
        pauseDuration: const Duration(milliseconds: 5),
      );

      await HapticFlow.play(sequence);

      expect(mockDriver.recordedTypes, [
        HapticStepType.light,
        HapticStepType.medium,
        HapticStepType.heavy,
        HapticStepType.selection,
      ]);
    });

    test('Sequence builder scales playback speed and concatenates', () async {
      final s1 = HapticSequence.builder('S1')
          .light(duration: const Duration(milliseconds: 10))
          .build();
      final s2 = HapticSequence.builder('S2')
          .heavy(duration: const Duration(milliseconds: 10))
          .build();

      final combined = s1 + s2;
      expect(combined.length, 2);

      await HapticFlow.play(combined);
      expect(mockDriver.recordedTypes, [
        HapticStepType.light,
        HapticStepType.heavy,
      ]);
    });

    test('Global HapticFlow.enabled master toggle disables playback', () async {
      HapticFlow.enabled = false;
      await HapticFlow.heavy();
      await HapticFlow.play(HapticPresets.successSnap);

      expect(mockDriver.recordedTypes, isEmpty);

      HapticFlow.enabled = true;
      await HapticFlow.selection();
      expect(mockDriver.recordedTypes, [HapticStepType.selection]);
    });
  });

  group('SettingsRepository Haptics Integration Tests', () {
    test('defaults to true and updates HapticFlow.enabled', () async {
      final repo = SettingsRepository();
      expect(repo.getHapticsEnabled(), isTrue);
      expect(HapticFlow.enabled, isTrue);

      await repo.setHapticsEnabled(false);
      expect(repo.getHapticsEnabled(), isFalse);
      expect(HapticFlow.enabled, isFalse);

      await repo.setHapticsEnabled(true);
      expect(repo.getHapticsEnabled(), isTrue);
      expect(HapticFlow.enabled, isTrue);
    });
  });

  group('Haptic Tactile Widgets Tests', () {
    testWidgets('HapticGestureDetector fires haptic steps on gestures', (
      tester,
    ) async {
      int tapCount = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: HapticGestureDetector(
                onTap: () => tapCount++,
                child: Container(
                  width: 100,
                  height: 100,
                  color: Colors.blue,
                  child: const Center(child: Text('Touch Target')),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Touch Target'));
      await tester.pumpAndSettle();
      expect(tapCount, 1);
      expect(mockDriver.recordedTypes, [HapticStepType.light]);
    });

    testWidgets('TactileStudioSheet renders presets and controls', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: TactileStudioSheet(),
          ),
        ),
      );

      expect(find.text('Tactile Sensation Studio'), findsOneWidget);
      expect(find.text('Success Snap'), findsOneWidget);
      expect(find.text('Mechanical Dial'), findsOneWidget);
      expect(find.text('Heartbeat'), findsOneWidget);
      expect(find.text('Sparkle'), findsOneWidget);

      final successSnapFinder = find.text('Success Snap');
      await tester.ensureVisible(successSnapFinder);
      await tester.pumpAndSettle();
      await tester.tap(successSnapFinder);
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pumpAndSettle();

      expect(mockDriver.recordedTypes, [
        HapticStepType.selection, // PressableScale tactile micro-interaction
        HapticStepType.light,     // Success Snap preparatory tick
        HapticStepType.medium,    // Success Snap confirmation snap
      ]);
    });
  });
}

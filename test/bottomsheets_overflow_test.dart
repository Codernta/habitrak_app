import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive/hive.dart';
import 'package:habitrak/core/storage/hive_registrar.dart';
import 'package:habitrak/core/theme/app_theme.dart';
import 'package:habitrak/core/widgets/offline_status_sheet.dart';
import 'package:habitrak/core/widgets/tactile_studio_sheet.dart';
import 'package:habitrak/features/music/presentation/widgets/music_search_sheet.dart';
import 'package:habitrak/features/health/presentation/widgets/wearables_hub_modal.dart';
import 'package:habitrak/features/mindfulness/presentation/widgets/breathwork_modal.dart';
import 'package:habitrak/features/mindfulness/presentation/widgets/meditation_timer_modal.dart';
import 'package:habitrak/features/mindfulness/presentation/widgets/thought_release_modal.dart';
import 'package:habitrak/features/mindfulness/data/repositories/soulfulness_repository.dart';
import 'package:habitrak/features/health/presentation/bloc/wearable_sync_bloc.dart';
import 'package:habitrak/features/health/presentation/bloc/wearable_sync_event.dart';
import 'package:habitrak/features/health/presentation/bloc/wearable_sync_state.dart';
import 'package:habitrak/features/health/domain/models/daily_health_summary.dart';
import 'package:habitrak/features/health/domain/models/ai_health_insight.dart';
import 'package:habitrak/features/health/domain/models/device_connection_metadata.dart';
import 'package:habitrak/features/health/services/health_permission_service.dart';

class MockWearableSyncBloc extends Bloc<WearableSyncEvent, WearableSyncState>
    implements WearableSyncBloc {
  MockWearableSyncBloc(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Directory tempDir;
  late SoulfulnessRepository soulRepo;

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('habitrak_overflow_test_');
    Hive.init(tempDir.path);
    await Hive.openBox<dynamic>(HiveRegistrar.soulfulnessBoxName);
    soulRepo = SoulfulnessRepository();
  });

  tearDown(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  Widget buildTestableContainer({
    required Widget child,
    Size size = const Size(320, 568), // iPhone SE 1st gen narrow dimensions
    EdgeInsets viewInsets = EdgeInsets.zero,
    double textScaleFactor = 1.0,
    WearableSyncBloc? bloc,
  }) {
    return MediaQuery(
      data: MediaQueryData(
        size: size,
        viewInsets: viewInsets,
        textScaler: TextScaler.linear(textScaleFactor),
      ),
      child: RepositoryProvider<SoulfulnessRepository>.value(
        value: soulRepo,
        child: bloc != null
            ? BlocProvider<WearableSyncBloc>.value(
                value: bloc,
                child: MaterialApp(
                  theme: AppTheme.darkTheme,
                  home: Scaffold(body: child),
                ),
              )
            : MaterialApp(
                theme: AppTheme.darkTheme,
                home: Scaffold(body: child),
              ),
      ),
    );
  }

  group('Bottomsheet Overflow Regression Tests (Small Viewport 320x568)', () {
    testWidgets('OfflineStatusSheet renders without overflow on 320x568 with large text',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableContainer(
          child: const OfflineStatusSheet(),
          textScaleFactor: 1.25,
        ),
      );
      await tester.pump();

      expect(find.byType(OfflineStatusSheet), findsOneWidget);
      expect(find.text('Mindful Offline Mode'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MusicSearchSheet renders without overflow with keyboard insets',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableContainer(
          child: MusicSearchSheet(onTrackSelected: (_) {}),
          viewInsets: const EdgeInsets.only(bottom: 280),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(MusicSearchSheet), findsOneWidget);
      expect(find.text('Soulful Music Library'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('WearablesHubModal renders without overflow on narrow device',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      final summary = DailyHealthSummary(
        date: '2026-11-21',
        steps: 9200,
        sleepDurationMinutes: 480,
        sleepEfficiencyPercentage: 92,
        restingHeartRate: 60,
        exerciseMinutes: 40,
        lastSyncedAt: DateTime.now(),
      );

      final insight = AIHealthInsight(
        id: 'ins_1',
        date: '2026-11-21',
        title: 'Morning Briefing',
        summary: 'Excellent recovery and readiness today.',
        observations: ['Sleep efficiency was optimal at 92%.'],
        recommendations: ['Complete physical goals early in the afternoon.'],
        category: 'morning_briefing',
        createdAt: DateTime.now(),
      );

      final device = DeviceConnectionMetadata(
        deviceId: 'apple_watch_ultra',
        provider: 'apple_healthkit',
        deviceModel: 'Apple Watch Ultra 2 Titanium Edition',
        lastSyncTimestamp: DateTime.now(),
        platform: 'ios',
      );

      final state = WearableSyncSuccess(
        platformStatus: HealthPlatformStatus.available,
        hasPermissions: true,
        currentSummary: summary,
        connectedDevices: [device],
        latestInsight: insight,
        lastSyncedAt: DateTime.now(),
      );

      final mockBloc = MockWearableSyncBloc(state);

      await tester.pumpWidget(
        buildTestableContainer(
          child: const WearablesHubModal(),
          bloc: mockBloc,
        ),
      );
      await tester.pump();

      expect(find.byType(WearablesHubModal), findsOneWidget);
      expect(find.text('Wearables & Health AI'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('BreathworkModal renders without overflow on 320x568',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableContainer(child: const BreathworkModal()),
      );
      await tester.pump();

      expect(find.byType(BreathworkModal), findsOneWidget);
      expect(find.text('Pranayama Pacer'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('MeditationTimerModal renders without overflow on 320x568',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableContainer(
          child: const MeditationTimerModal(initialMinutes: 5),
        ),
      );
      await tester.pump();

      expect(find.byType(MeditationTimerModal), findsOneWidget);
      expect(find.text('Meditation Sanctuary'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ThoughtReleaseModal renders without overflow with keyboard up',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableContainer(
          child: const ThoughtReleaseModal(),
          viewInsets: const EdgeInsets.only(bottom: 280),
        ),
      );
      await tester.pump();

      expect(find.byType(ThoughtReleaseModal), findsOneWidget);
      expect(find.text('Release to the River'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('TactileStudioSheet renders without overflow on narrow device',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(320, 568));
      addTearDown(() async => await tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildTestableContainer(
          child: const TactileStudioSheet(),
          viewInsets: const EdgeInsets.only(bottom: 250),
        ),
      );
      await tester.pump();

      expect(find.byType(TactileStudioSheet), findsOneWidget);
      expect(find.text('Tactile Sensation Studio'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}

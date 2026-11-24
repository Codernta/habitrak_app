import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitrak/core/theme/app_theme.dart';
import 'package:habitrak/features/health/domain/models/ai_health_insight.dart';
import 'package:habitrak/features/health/domain/models/daily_health_summary.dart';
import 'package:habitrak/features/health/domain/models/device_connection_metadata.dart';
import 'package:habitrak/features/health/presentation/bloc/wearable_sync_bloc.dart';
import 'package:habitrak/features/health/presentation/bloc/wearable_sync_event.dart';
import 'package:habitrak/features/health/presentation/bloc/wearable_sync_state.dart';
import 'package:habitrak/features/health/presentation/widgets/wearables_hub_modal.dart';
import 'package:habitrak/features/health/services/health_permission_service.dart';

class MockWearableSyncBloc extends Bloc<WearableSyncEvent, WearableSyncState>
    implements WearableSyncBloc {
  MockWearableSyncBloc(super.initialState);

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  testWidgets('WearablesHubModal renders health metrics, AI briefing, and habit rules',
      (WidgetTester tester) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() async => await tester.binding.setSurfaceSize(null));
    final summary = DailyHealthSummary(
      date: '2026-11-21',
      steps: 8420,
      sleepDurationMinutes: 450, // 7.5 hours
      sleepEfficiencyPercentage: 88,
      restingHeartRate: 58,
      exerciseMinutes: 45,
      lastSyncedAt: DateTime.now(),
    );

    final insight = AIHealthInsight(
      id: 'insight_1',
      date: '2026-11-21',
      title: 'AI Morning Health Briefing',
      summary: 'Optimal sleep rhythm logged. Readiness score is peak.',
      observations: ['7.5 hours of sleep logged with 88% efficiency.'],
      recommendations: ['Tackle your most demanding habit early.'],
      category: 'morning_briefing',
      createdAt: DateTime.now(),
    );

    final device = DeviceConnectionMetadata(
      deviceId: 'device_apple_watch',
      provider: 'apple_healthkit',
      deviceModel: 'Apple Watch Ultra',
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

    final bloc = MockWearableSyncBloc(state);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.lightTheme,
        home: Scaffold(
          body: BlocProvider<WearableSyncBloc>.value(
            value: bloc,
            child: const WearablesHubModal(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify header and sections
    expect(find.text('Wearables & Health AI'), findsOneWidget);
    expect(find.text('Connected & Authorized'), findsOneWidget);
    expect(find.text('AI Morning Health Briefing'), findsOneWidget);
    expect(find.text('Optimal sleep rhythm logged. Readiness score is peak.'), findsOneWidget);
    expect(find.text('Live Habit Automation'), findsOneWidget);
    expect(find.text('8420 steps'), findsOneWidget);
    expect(find.text('7.5 hrs'), findsOneWidget);
    expect(find.text('45 mins'), findsOneWidget);

    // Scroll down to see ecosystem & devices card
    await tester.drag(find.byType(ListView), const Offset(0, -600));
    await tester.pumpAndSettle();

    expect(find.text('Ecosystem & Wearable Devices'), findsOneWidget);
  });
}

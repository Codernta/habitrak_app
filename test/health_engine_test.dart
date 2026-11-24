import 'package:flutter_test/flutter_test.dart';
import 'package:habitrak/features/habit/domain/entities/habit.dart';
import 'package:habitrak/features/habit/domain/repositories/habit_repository.dart';
import 'package:habitrak/features/health/domain/models/daily_health_summary.dart';
import 'package:habitrak/features/health/domain/models/health_metric_type.dart';
import 'package:habitrak/features/health/domain/models/normalized_health_record.dart';
import 'package:habitrak/features/health/domain/models/habit_automation_rule.dart';
import 'package:habitrak/features/health/domain/models/ai_health_insight.dart';
import 'package:habitrak/features/health/services/deduplication_engine.dart';
import 'package:habitrak/features/health/services/health_aggregation_service.dart';
import 'package:habitrak/features/health/services/habit_automation_engine.dart';
import 'package:habitrak/features/health/services/health_ai_service.dart';
import 'package:habitrak/features/health/services/health_sync_local_storage.dart';

class MockHabitRepository implements HabitRepository {
  List<Habit> habits = [];

  @override
  Future<List<Habit>> getHabits() async => habits;

  @override
  Future<List<Habit>> getHabitsForDate(DateTime date) async => habits;

  @override
  Future<void> addHabit(Habit habit) async {
    habits.add(habit);
  }

  @override
  Future<void> toggleHabitCompletion(String id) async {
    final idx = habits.indexWhere((h) => h.id == id);
    if (idx >= 0) {
      final h = habits[idx];
      habits[idx] = h.copyWith(isCompleted: !h.isCompleted);
    }
  }

  @override
  Future<void> updateHabitProgress(String id, double progress) async {
    final idx = habits.indexWhere((h) => h.id == id);
    if (idx >= 0) {
      final h = habits[idx];
      habits[idx] = h.copyWith(currentProgress: progress);
    }
  }

  Future<void> deleteHabit(String id) async {
    habits.removeWhere((h) => h.id == id);
  }

  @override
  Future<void> resetHabits() async {}

  Future<void> syncDailyRollover() async {}

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

class FakeLocalStorage implements HealthSyncLocalStorage {
  final Map<String, dynamic> state = {};
  final List<HabitAutomationRule> rules = [];

  @override
  String? getChangesToken(String platform) => state['changes_token_$platform'] as String?;

  @override
  Future<void> saveChangesToken(String platform, String token) async {
    state['changes_token_$platform'] = token;
  }

  @override
  List<HabitAutomationRule> getHabitRules() => rules;

  @override
  Future<void> saveHabitRule(HabitAutomationRule rule) async {
    rules.add(rule);
  }

  @override
  Future<void> saveInsight(AIHealthInsight insight) async {}

  @override
  List<AIHealthInsight> getInsights() => [];

  @override
  noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  group('DeduplicationEngine Tests', () {
    late DeduplicationEngine engine;

    setUp(() {
      engine = DeduplicationEngine();
    });

    test('deduplicates exact hash identical records', () {
      final now = DateTime(2026, 11, 21, 10, 0);
      final r1 = NormalizedHealthRecord(
        id: 'hash_1',
        metricType: HealthMetricType.steps,
        value: 500,
        unit: 'count',
        startTime: now,
        endTime: now.add(const Duration(minutes: 10)),
        sourceApp: 'Apple Watch',
        platform: 'ios',
        recordingDate: '2026-11-21',
        syncedAt: now,
      );
      final r2 = NormalizedHealthRecord(
        id: 'hash_1',
        metricType: HealthMetricType.steps,
        value: 500,
        unit: 'count',
        startTime: now,
        endTime: now.add(const Duration(minutes: 10)),
        sourceApp: 'Apple Watch',
        platform: 'ios',
        recordingDate: '2026-11-21',
        syncedAt: now,
      );

      final deduplicated = engine.deduplicate([r1, r2]);
      expect(deduplicated.length, equals(1));
    });

    test('prioritizes hardware watch over secondary aggregator in overlapping intervals', () {
      final start = DateTime(2026, 11, 21, 8, 0);
      final end = DateTime(2026, 11, 21, 8, 30);

      final watchRecord = NormalizedHealthRecord(
        id: 'watch_rec',
        metricType: HealthMetricType.steps,
        value: 3000,
        unit: 'count',
        startTime: start,
        endTime: end,
        sourceApp: 'Apple Watch HealthKit',
        platform: 'ios',
        recordingDate: '2026-11-21',
        syncedAt: DateTime.now(),
      );

      final stravaRecord = NormalizedHealthRecord(
        id: 'strava_rec',
        metricType: HealthMetricType.steps,
        value: 2950,
        unit: 'count',
        startTime: start,
        endTime: end,
        sourceApp: 'Strava Companion App',
        platform: 'ios',
        recordingDate: '2026-11-21',
        syncedAt: DateTime.now(),
      );

      final result = engine.deduplicate([stravaRecord, watchRecord]);
      expect(result.length, equals(1));
      expect(result.first.sourceApp, contains('Apple Watch'));
    });
  });

  group('HealthAggregationService Tests', () {
    late HealthAggregationService aggregationService;

    setUp(() {
      aggregationService = HealthAggregationService();
    });

    test('aggregates daily steps, distance, and calories accurately', () {
      final now = DateTime(2026, 11, 21, 9, 0);
      final records = [
        NormalizedHealthRecord(
          id: 'step_1',
          metricType: HealthMetricType.steps,
          value: 4000,
          unit: 'count',
          startTime: now,
          endTime: now.add(const Duration(hours: 1)),
          sourceApp: 'HealthKit',
          platform: 'ios',
          recordingDate: '2026-11-21',
          syncedAt: now,
        ),
        NormalizedHealthRecord(
          id: 'step_2',
          metricType: HealthMetricType.steps,
          value: 3500,
          unit: 'count',
          startTime: now.add(const Duration(hours: 2)),
          endTime: now.add(const Duration(hours: 3)),
          sourceApp: 'HealthKit',
          platform: 'ios',
          recordingDate: '2026-11-21',
          syncedAt: now,
        ),
        NormalizedHealthRecord(
          id: 'dist_1',
          metricType: HealthMetricType.distance,
          value: 5.5,
          unit: 'km',
          startTime: now,
          endTime: now.add(const Duration(hours: 3)),
          sourceApp: 'HealthKit',
          platform: 'ios',
          recordingDate: '2026-11-21',
          syncedAt: now,
        ),
        NormalizedHealthRecord(
          id: 'cal_1',
          metricType: HealthMetricType.activeCalories,
          value: 420.0,
          unit: 'kcal',
          startTime: now,
          endTime: now.add(const Duration(hours: 1)),
          sourceApp: 'HealthKit',
          platform: 'ios',
          recordingDate: '2026-11-21',
          syncedAt: now,
        ),
      ];

      final summary = aggregationService.aggregateDailyRecords(
        date: '2026-11-21',
        records: records,
      );

      expect(summary.steps, equals(7500));
      expect(summary.distanceMeters, equals(5500.0));
      expect(summary.distanceKm, equals(5.5));
      expect(summary.activeCalories, equals(420.0));
    });

    test('calculates sleep efficiency and heart rate statistics', () {
      final now = DateTime(2026, 11, 21, 0, 0);
      final records = [
        NormalizedHealthRecord(
          id: 'hr_1',
          metricType: HealthMetricType.heartRate,
          value: 60.0,
          unit: 'bpm',
          startTime: now,
          endTime: now,
          sourceApp: 'HealthKit',
          platform: 'ios',
          recordingDate: '2026-11-21',
          syncedAt: now,
        ),
        NormalizedHealthRecord(
          id: 'hr_2',
          metricType: HealthMetricType.heartRate,
          value: 80.0,
          unit: 'bpm',
          startTime: now.add(const Duration(minutes: 30)),
          endTime: now.add(const Duration(minutes: 30)),
          sourceApp: 'HealthKit',
          platform: 'ios',
          recordingDate: '2026-11-21',
          syncedAt: now,
        ),
        NormalizedHealthRecord(
          id: 'rhr_1',
          metricType: HealthMetricType.restingHeartRate,
          value: 54.0,
          unit: 'bpm',
          startTime: now,
          endTime: now,
          sourceApp: 'HealthKit',
          platform: 'ios',
          recordingDate: '2026-11-21',
          syncedAt: now,
        ),
        NormalizedHealthRecord(
          id: 'sleep_deep',
          metricType: HealthMetricType.sleep,
          value: 120,
          unit: 'deep',
          startTime: now,
          endTime: now.add(const Duration(minutes: 120)),
          sourceApp: 'Apple Watch Deep Sleep',
          platform: 'ios',
          recordingDate: '2026-11-21',
          syncedAt: now,
        ),
        NormalizedHealthRecord(
          id: 'sleep_light',
          metricType: HealthMetricType.sleep,
          value: 240,
          unit: 'light',
          startTime: now.add(const Duration(minutes: 120)),
          endTime: now.add(const Duration(minutes: 360)),
          sourceApp: 'Apple Watch Light Sleep',
          platform: 'ios',
          recordingDate: '2026-11-21',
          syncedAt: now,
        ),
        NormalizedHealthRecord(
          id: 'sleep_awake',
          metricType: HealthMetricType.sleep,
          value: 40,
          unit: 'awake',
          startTime: now.add(const Duration(minutes: 360)),
          endTime: now.add(const Duration(minutes: 400)),
          sourceApp: 'Apple Watch Awake',
          platform: 'ios',
          recordingDate: '2026-11-21',
          syncedAt: now,
        ),
      ];

      final summary = aggregationService.aggregateDailyRecords(
        date: '2026-11-21',
        records: records,
      );

      expect(summary.avgHeartRate, equals(70.0));
      expect(summary.minHeartRate, equals(60.0));
      expect(summary.maxHeartRate, equals(80.0));
      expect(summary.restingHeartRate, equals(54.0));
      expect(summary.sleepDurationMinutes, equals(360)); // 120 + 240
      expect(summary.awakeMinutes, equals(40));
      // Efficiency = 360 / (360 + 40) = 90%
      expect(summary.sleepEfficiencyPercentage, equals(90));
    });
  });

  group('HabitAutomationEngine Tests', () {
    late MockHabitRepository mockRepo;
    late FakeLocalStorage fakeStorage;
    late HabitAutomationEngine engine;

    setUp(() {
      mockRepo = MockHabitRepository();
      fakeStorage = FakeLocalStorage();
      engine = HabitAutomationEngine(
        habitRepository: mockRepo,
        localStorage: fakeStorage,
      );
    });

    test('auto-completes step habit when daily steps exceed threshold', () async {
      final stepHabit = const Habit(
        id: 'habit_walk_1',
        title: 'Walk 8,000 Steps',
        category: HabitCategory.health,
        targetProgress: 8000,
        currentProgress: 0,
        unit: 'steps',
        isCompleted: false,
      );
      mockRepo.habits = [stepHabit];

      final summary = DailyHealthSummary(
        date: '2026-11-21',
        steps: 8500,
        lastSyncedAt: DateTime.now(),
      );

      final results = await engine.evaluateAndSyncHabits(summary: summary);
      expect(results.length, equals(1));
      expect(results.first.wasAutoCompleted, isTrue);
      expect(mockRepo.habits.first.isCompleted, isTrue);
    });

    test('preserves user manual override when habit was intentionally unchecked', () async {
      final stepHabit = const Habit(
        id: 'habit_walk_2',
        title: 'Morning Walk Steps',
        category: HabitCategory.health,
        targetProgress: 5000,
        currentProgress: 5000,
        unit: 'steps',
        isCompleted: false,
      );
      mockRepo.habits = [stepHabit];

      // User manually toggled off today
      await fakeStorage.saveChangesToken('manual_override_habit_walk_2_2026-11-21', 'uncompleted');

      final summary = DailyHealthSummary(
        date: '2026-11-21',
        steps: 6200,
        lastSyncedAt: DateTime.now(),
      );

      final results = await engine.evaluateAndSyncHabits(summary: summary);
      expect(results.isEmpty, isTrue);
      expect(mockRepo.habits.first.isCompleted, isFalse);
    });
  });

  group('OfflineRuleBasedAIService Tests', () {
    late OfflineRuleBasedAIService aiService;
    late FakeLocalStorage fakeStorage;

    setUp(() {
      fakeStorage = FakeLocalStorage();
      aiService = OfflineRuleBasedAIService(localStorage: fakeStorage);
    });

    test('generates morning briefing with observations and lifestyle recommendations', () async {
      final today = DailyHealthSummary(
        date: '2026-11-21',
        steps: 10200,
        sleepDurationMinutes: 480, // 8 hours
        sleepEfficiencyPercentage: 92,
        restingHeartRate: 52,
        lastSyncedAt: DateTime.now(),
      );

      final briefing = await aiService.generateMorningBriefing(
        today: today,
        recentHistory: [],
      );

      expect(briefing.title, contains('Briefing'));
      expect(briefing.observations.isNotEmpty, isTrue);
      expect(briefing.recommendations.isNotEmpty, isTrue);
      expect(briefing.confidence, greaterThanOrEqualTo(0.9));
    });
  });
}

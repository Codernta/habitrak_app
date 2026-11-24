import 'package:flutter/foundation.dart';
import 'package:hive/hive.dart';
import '../domain/models/ai_health_insight.dart';
import '../domain/models/daily_health_summary.dart';
import '../domain/models/device_connection_metadata.dart';
import '../domain/models/habit_automation_rule.dart';

class HealthSyncLocalStorage {
  static const String syncStateBoxName = 'health_sync_state';
  static const String dailySummariesBoxName = 'daily_health_summaries';
  static const String habitRulesBoxName = 'habit_automation_rules';
  static const String aiInsightsBoxName = 'ai_insights_cache';

  Box<dynamic>? _syncStateBox;
  Box<dynamic>? _dailySummariesBox;
  Box<dynamic>? _habitRulesBox;
  Box<dynamic>? _aiInsightsBox;

  Future<void> init() async {
    try {
      _syncStateBox = Hive.isBoxOpen(syncStateBoxName)
          ? Hive.box<dynamic>(syncStateBoxName)
          : await Hive.openBox<dynamic>(syncStateBoxName);

      _dailySummariesBox = Hive.isBoxOpen(dailySummariesBoxName)
          ? Hive.box<dynamic>(dailySummariesBoxName)
          : await Hive.openBox<dynamic>(dailySummariesBoxName);

      _habitRulesBox = Hive.isBoxOpen(habitRulesBoxName)
          ? Hive.box<dynamic>(habitRulesBoxName)
          : await Hive.openBox<dynamic>(habitRulesBoxName);

      _aiInsightsBox = Hive.isBoxOpen(aiInsightsBoxName)
          ? Hive.box<dynamic>(aiInsightsBoxName)
          : await Hive.openBox<dynamic>(aiInsightsBoxName);
    } catch (e) {
      debugPrint('HealthSyncLocalStorage.init error: $e');
    }
  }

  // --- Sync State & Changes Tokens ---

  String? getChangesToken(String platform) {
    return _syncStateBox?.get('changes_token_$platform') as String?;
  }

  Future<void> saveChangesToken(String platform, String token) async {
    await _syncStateBox?.put('changes_token_$platform', token);
  }

  DateTime? getLastSyncTimestamp() {
    final str = _syncStateBox?.get('last_sync_timestamp') as String?;
    return str != null ? DateTime.tryParse(str) : null;
  }

  Future<void> saveLastSyncTimestamp(DateTime timestamp) async {
    await _syncStateBox?.put('last_sync_timestamp', timestamp.toIso8601String());
  }

  // --- Device Metadata ---

  List<DeviceConnectionMetadata> getConnectedDevices() {
    final raw = _syncStateBox?.get('connected_devices') as List<dynamic>?;
    if (raw == null) return [];
    return raw
        .whereType<Map>()
        .map((m) => DeviceConnectionMetadata.fromMap(m))
        .toList();
  }

  Future<void> saveConnectedDevice(DeviceConnectionMetadata device) async {
    final current = getConnectedDevices().toList();
    final idx = current.indexWhere((d) => d.deviceId == device.deviceId);
    if (idx >= 0) {
      current[idx] = device;
    } else {
      current.add(device);
    }
    await _syncStateBox?.put(
      'connected_devices',
      current.map((d) => d.toMap()).toList(),
    );
  }

  // --- Daily Health Summaries ---

  DailyHealthSummary? getDailySummary(String date) {
    final map = _dailySummariesBox?.get(date) as Map?;
    if (map == null) return null;
    return DailyHealthSummary.fromMap(map);
  }

  List<DailyHealthSummary> getRecentSummaries({int days = 7}) {
    if (_dailySummariesBox == null) return [];
    final List<DailyHealthSummary> list = [];
    final now = DateTime.now();

    for (int i = 0; i < days; i++) {
      final day = now.subtract(Duration(days: i));
      final dateStr =
          '${day.year.toString().padLeft(4, '0')}-${day.month.toString().padLeft(2, '0')}-${day.day.toString().padLeft(2, '0')}';
      final summary = getDailySummary(dateStr);
      if (summary != null) {
        list.add(summary);
      }
    }
    return list;
  }

  Future<void> saveDailySummary(DailyHealthSummary summary) async {
    await _dailySummariesBox?.put(summary.date, summary.toMap());
  }

  // --- Habit Automation Rules ---

  List<HabitAutomationRule> getHabitRules() {
    if (_habitRulesBox == null) return [];
    final List<HabitAutomationRule> rules = [];
    for (final key in _habitRulesBox!.keys) {
      final map = _habitRulesBox!.get(key) as Map?;
      if (map != null) {
        rules.add(HabitAutomationRule.fromMap(map));
      }
    }
    return rules;
  }

  Future<void> saveHabitRule(HabitAutomationRule rule) async {
    await _habitRulesBox?.put(rule.id, rule.toMap());
  }

  Future<void> deleteHabitRule(String ruleId) async {
    await _habitRulesBox?.delete(ruleId);
  }

  // --- AI Health Insights ---

  List<AIHealthInsight> getInsights() {
    if (_aiInsightsBox == null) return [];
    final List<AIHealthInsight> insights = [];
    for (final key in _aiInsightsBox!.keys) {
      final map = _aiInsightsBox!.get(key) as Map?;
      if (map != null) {
        insights.add(AIHealthInsight.fromMap(map));
      }
    }
    insights.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return insights;
  }

  Future<void> saveInsight(AIHealthInsight insight) async {
    await _aiInsightsBox?.put(insight.id, insight.toMap());
  }
}

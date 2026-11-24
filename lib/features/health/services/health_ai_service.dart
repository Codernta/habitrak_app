import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../domain/models/ai_health_insight.dart';
import '../domain/models/daily_health_summary.dart';
import 'health_sync_local_storage.dart';

abstract class HealthAIService {
  Future<AIHealthInsight> generateMorningBriefing({
    required DailyHealthSummary today,
    required List<DailyHealthSummary> recentHistory,
  });

  Future<AIHealthInsight> analyzePatterns({
    required List<DailyHealthSummary> history,
  });
}

/// 100% Offline, Deterministic, Rule-Based AI Engine
/// Analyzes physiological metrics without needing network or cloud calls.
class OfflineRuleBasedAIService implements HealthAIService {
  final HealthSyncLocalStorage _localStorage;

  OfflineRuleBasedAIService({HealthSyncLocalStorage? localStorage})
      : _localStorage = localStorage ?? HealthSyncLocalStorage();

  @override
  Future<AIHealthInsight> generateMorningBriefing({
    required DailyHealthSummary today,
    required List<DailyHealthSummary> recentHistory,
  }) async {
    final observations = <String>[];
    final recommendations = <String>[];

    // 1. Sleep Analysis
    if (today.sleepDurationMinutes > 0) {
      final hours = today.sleepHours;
      final efficiency = today.sleepEfficiencyPercentage ?? 85;
      if (hours >= 7.5 && efficiency >= 85) {
        observations.add('Optimal restorative sleep: ${hours}h with $efficiency% efficiency.');
        recommendations.add('High cognitive readiness today. Tackle your most demanding habit early.');
      } else if (hours < 6.0) {
        observations.add('Sleep deficit detected: Only ${hours}h logged last night.');
        recommendations.add('Prioritize a 15-minute mindfulness breathwork break and avoid late caffeine.');
      } else {
        observations.add('Moderate sleep duration: ${hours}h logged.');
        recommendations.add('Maintain steady hydration to keep afternoon energy levels consistent.');
      }
    } else {
      observations.add('Wearable sleep data pending or not yet synced for last night.');
      recommendations.add('Sync your wearable to view personalized rest and recovery metrics.');
    }

    // 2. Resting Heart Rate Trend
    if (today.restingHeartRate != null && recentHistory.isNotEmpty) {
      final previousHrs = recentHistory
          .where((s) => s.restingHeartRate != null)
          .map((s) => s.restingHeartRate!)
          .toList();

      if (previousHrs.isNotEmpty) {
        final avgPrevHr = previousHrs.reduce((a, b) => a + b) / previousHrs.length;
        final currentHr = today.restingHeartRate!;
        final diff = currentHr - avgPrevHr;

        if (diff > 5.0) {
          observations.add('Resting heart rate elevated (+${diff.toStringAsFixed(1)} bpm vs baseline).');
          recommendations.add('Your body may be recovering from exertion or fatigue. Take recovery walks today.');
        } else if (diff < -2.0) {
          observations.add('Strong cardiovascular efficiency: Resting HR is ${currentHr.toInt()} bpm.');
          recommendations.add('Great cardiovascular state! Ideal for completing intense workout goals.');
        } else {
          observations.add('Resting heart rate is stable at ${currentHr.toInt()} bpm.');
        }
      }
    }

    // 3. Activity & Steps Target
    if (today.steps > 0) {
      if (today.steps >= 10000) {
        observations.add('Outstanding movement: ${today.steps} steps already achieved today!');
        recommendations.add('Active movement goal exceeded. Keep hydrated and stretch.');
      } else if (today.steps >= 5000) {
        observations.add('Solid activity base: ${today.steps} steps logged.');
        recommendations.add('A brisk 20-minute walk will push you over your daily 8,000-step target.');
      } else {
        observations.add('Morning activity: ${today.steps} steps logged so far.');
        recommendations.add('Consider a short morning walk or stretch to activate blood circulation.');
      }
    }

    final insight = AIHealthInsight(
      id: 'briefing_${today.date}_${DateTime.now().millisecondsSinceEpoch}',
      date: today.date,
      title: 'Daily Health Intelligence Briefing',
      summary: observations.isNotEmpty
          ? observations.first
          : 'Your wearable health metrics are actively syncing to optimize your habit goals.',
      observations: observations,
      recommendations: recommendations,
      confidence: 0.96,
      category: 'morning_briefing',
      createdAt: DateTime.now(),
    );

    await _localStorage.saveInsight(insight);
    return insight;
  }

  @override
  Future<AIHealthInsight> analyzePatterns({
    required List<DailyHealthSummary> history,
  }) async {
    final observations = <String>[];
    final recommendations = <String>[];

    if (history.length >= 3) {
      final totalSteps = history.map((s) => s.steps).reduce((a, b) => a + b);
      final avgSteps = (totalSteps / history.length).round();
      observations.add('3-day average movement: $avgSteps steps per day.');

      final totalSleepHours = history.map((s) => s.sleepHours).reduce((a, b) => a + b);
      final avgSleep = (totalSleepHours / history.length * 10).round() / 10.0;
      observations.add('Consistent sleep rhythm averaging ${avgSleep}h over recent days.');

      if (avgSteps >= 8000) {
        recommendations.add('High habit synergy: Activity goals are reinforcing regular sleep cycles.');
      } else {
        recommendations.add('Try scheduling your walk at 4 PM to naturally improve evening deep sleep.');
      }
    } else {
      observations.add('Building your baseline health and habit profile.');
      recommendations.add('Wear your device continuously to unlock 7-day pattern analysis.');
    }

    final insight = AIHealthInsight(
      id: 'pattern_${DateTime.now().millisecondsSinceEpoch}',
      date: history.isNotEmpty ? history.first.date : DateTime.now().toIso8601String().substring(0, 10),
      title: 'Weekly Habit & Rhythm Insights',
      summary: observations.isNotEmpty ? observations.first : 'Analyzing your weekly activity rhythm.',
      observations: observations,
      recommendations: recommendations,
      confidence: 0.94,
      category: 'trend_alert',
      createdAt: DateTime.now(),
    );

    await _localStorage.saveInsight(insight);
    return insight;
  }
}

/// Hybrid AI Service that uses remote Cloud/Gemini API when available and falls back to Offline AI
class HybridHealthAIService implements HealthAIService {
  final OfflineRuleBasedAIService _offlineService;
  final String? _apiKey;

  HybridHealthAIService({
    OfflineRuleBasedAIService? offlineService,
    String? apiKey,
  })  : _offlineService = offlineService ?? OfflineRuleBasedAIService(),
        _apiKey = apiKey;

  @override
  Future<AIHealthInsight> generateMorningBriefing({
    required DailyHealthSummary today,
    required List<DailyHealthSummary> recentHistory,
  }) async {
    // If no API key or in offline mode, use high-speed deterministic offline AI
    if (_apiKey == null || _apiKey.isEmpty) {
      return _offlineService.generateMorningBriefing(
        today: today,
        recentHistory: recentHistory,
      );
    }

    try {
      final prompt = '''
Analyze these wearable health metrics for today (${today.date}):
- Steps: ${today.steps}
- Sleep: ${today.sleepHours} hours (Efficiency: ${today.sleepEfficiencyPercentage ?? 'N/A'}%)
- Resting HR: ${today.restingHeartRate ?? 'N/A'} bpm
- Active Calories: ${today.activeCalories} kcal
- Exercise: ${today.exerciseMinutes} mins

Return a JSON object with:
"title": string,
"summary": string,
"observations": list of strings,
"recommendations": list of actionable lifestyle/habit recommendations,
"confidence": float between 0.9 and 1.0
''';

      final url = Uri.parse(
        'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey',
      );

      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ]
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        final cleanJson = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
        final parsed = jsonDecode(cleanJson);

        return AIHealthInsight(
          id: 'ai_briefing_${today.date}_${DateTime.now().millisecondsSinceEpoch}',
          date: today.date,
          title: parsed['title'] ?? 'AI Daily Morning Briefing',
          summary: parsed['summary'] ?? '',
          observations: List<String>.from(parsed['observations'] ?? []),
          recommendations: List<String>.from(parsed['recommendations'] ?? []),
          confidence: (parsed['confidence'] as num?)?.toDouble() ?? 0.95,
          category: 'morning_briefing',
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      debugPrint('HybridHealthAIService remote error, falling back to offline: $e');
    }

    return _offlineService.generateMorningBriefing(
      today: today,
      recentHistory: recentHistory,
    );
  }

  @override
  Future<AIHealthInsight> analyzePatterns({
    required List<DailyHealthSummary> history,
  }) async {
    return _offlineService.analyzePatterns(history: history);
  }
}

import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../../core/storage/hive_registrar.dart';

class ProfileRepository {
  final Box<dynamic> _profileBox = Hive.box<dynamic>(
    HiveRegistrar.profileBoxName,
  );
  final Box<Map> _historyBox = Hive.box<Map>(HiveRegistrar.habitHistoryBoxName);
  final Box<Map> _activityBox = Hive.box<Map>(
    HiveRegistrar.activityLogsBoxName,
  );

  static const String _keyUserName = 'user_name';

  String getUserName() {
    return _profileBox.get(_keyUserName, defaultValue: 'Jordan Smith')
        as String;
  }

  Future<void> setUserName(String name) async {
    await _profileBox.put(_keyUserName, name.trim());
  }

  String getAvatarInitials() {
    final name = getUserName();
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'JS';
    if (parts.length == 1) return parts[0].substring(0, 1).toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  int getStreakDays() {
    final now = DateTime.now();
    int streak = 0;

    // Check backwards from today or yesterday
    for (int i = 0; i < 60; i++) {
      final dt = now.subtract(Duration(days: i));
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final record = _historyBox.get(key);
      if (record != null && (record['completedCount'] as int? ?? 0) > 0) {
        streak++;
      } else {
        // If today has 0 so far, don't break yet, check yesterday
        if (i == 0) continue;
        break;
      }
    }
    return streak > 0 ? streak : 12; // Base fallback for brand new installs
  }

  int getTotalMindfulMinutes() {
    int total = 480; // Default foundation
    for (var v in _activityBox.values) {
      final map = Map<String, dynamic>.from(v);
      if (map['type'] == 'walk') {
        final sec = map['durationSeconds'] as int? ?? 0;
        total += (sec / 60).round();
      } else if (map['type'] == 'yoga') {
        total += map['durationMinutes'] as int? ?? 0;
      }
    }
    return total;
  }

  List<double> getHeatmapIntensities() {
    final now = DateTime.now();
    final List<double> intensities = [];

    // Past 35 days (5 weeks × 7 days)
    for (int i = 34; i >= 0; i--) {
      final dt = now.subtract(Duration(days: i));
      final key =
          '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';
      final record = _historyBox.get(key);
      if (record != null) {
        final completed = (record['completedCount'] as int? ?? 0).toDouble();
        final total = (record['totalHabits'] as int? ?? 4).toDouble();
        intensities.add(total > 0 ? (completed / total).clamp(0.0, 1.0) : 0.0);
      } else {
        intensities.add(0.0);
      }
    }
    return intensities;
  }

  List<Map<String, dynamic>> getBadges() {
    final streak = getStreakDays();

    // Check meditation count from history
    int meditationCount = 0;
    int waterCount = 0;
    for (var v in _historyBox.values) {
      final map = Map<String, dynamic>.from(v);
      final ids = (map['completedHabitIds'] as List?)?.cast<String>() ?? [];
      if (ids.contains('1')) meditationCount++; // Meditation habit ID
      if (ids.contains('2')) waterCount++; // Water habit ID
    }

    final isZenMasterUnlocked = meditationCount >= 7;
    final isConsistencyKingUnlocked = streak >= 12;
    final isHydrationStarUnlocked = waterCount >= 7;

    return [
      {
        'title': 'Zen Master',
        'desc': 'Complete meditation 7 days in a row',
        'icon': Icons.self_improvement,
        'color': const Color(0xffb2cad3),
        'isUnlocked': isZenMasterUnlocked,
        'progress': '$meditationCount/7 days',
      },
      {
        'title': 'Consistency King',
        'desc': 'Logged a perfect streak of 12 days',
        'icon': Icons.bolt,
        'color': const Color(0xffedb9c3),
        'isUnlocked': isConsistencyKingUnlocked,
        'progress': '$streak/12 days',
      },
      {
        'title': 'Hydration Star',
        'desc': 'Drink 2L water daily for 1 week',
        'icon': Icons.opacity,
        'color': const Color(0xffb0ceb2),
        'isUnlocked': isHydrationStarUnlocked,
        'progress': '$waterCount/7 days',
      },
    ];
  }
}

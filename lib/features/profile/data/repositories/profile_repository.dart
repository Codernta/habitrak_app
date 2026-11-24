import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import '../../../../core/security/secure_data_manager.dart';
import '../../../../core/storage/hive_registrar.dart';
import '../../../../core/theme/app_theme.dart';

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
    final custom = _profileBox.get(_keyUserName) as String?;
    if (custom != null && custom.isNotEmpty && custom != 'Jordan Smith') {
      return custom;
    }
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null &&
        firebaseUser.displayName != null &&
        firebaseUser.displayName!.isNotEmpty) {
      return firebaseUser.displayName!;
    }
    return 'Mindful Explorer';
  }

  String getUserEmail() {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser != null &&
        firebaseUser.email != null &&
        firebaseUser.email!.isNotEmpty) {
      return firebaseUser.email!;
    }
    return 'guest@habitrak.local';
  }

  String? getUserPhotoUrl() {
    return FirebaseAuth.instance.currentUser?.photoURL;
  }

  Future<void> setUserName(String name) async {
    final sanitized = SecureDataManager().sanitizeText(name, maxLength: 40);
    final finalName = sanitized.isNotEmpty ? sanitized : 'Mindful Explorer';
    await _profileBox.put(_keyUserName, finalName);

    // Sync with Firebase Auth and Firestore if user is signed in
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.updateDisplayName(finalName);
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'displayName': finalName,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }
    } catch (_) {}
  }

  String getAvatarInitials() {
    final name = getUserName();
    final parts = name.trim().split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return 'ME';
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
    return streak;
  }

  int getTotalMindfulMinutes() {
    int total = 0;
    for (var v in _activityBox.values) {
      final map = Map<String, dynamic>.from(v);
      if (map['type'] == 'walk') {
        final sec = map['durationSeconds'] as int? ?? 0;
        total += (sec / 60).round();
      } else if (map['type'] == 'yoga') {
        total += map['durationMinutes'] as int? ?? 0;
      }
    }
    try {
      if (Hive.isBoxOpen(HiveRegistrar.soulfulnessBoxName)) {
        final soulBox = Hive.box<dynamic>(HiveRegistrar.soulfulnessBoxName);
        final medMins =
            (soulBox.get('__total_meditation_minutes', defaultValue: 0)
                    as num?)
                ?.toInt() ??
            0;
        total += medMins;
      }
    } catch (_) {}
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
        'color': AppColors.pistaGreen,
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
        'color': const Color(0xFFCEF256),
        'isUnlocked': isHydrationStarUnlocked,
        'progress': '$waterCount/7 days',
      },
    ];
  }
}

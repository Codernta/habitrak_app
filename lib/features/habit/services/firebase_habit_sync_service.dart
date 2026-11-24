import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../domain/entities/habit.dart';

class FirebaseHabitSyncService {
  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  FirebaseHabitSyncService({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _auth = auth ?? FirebaseAuth.instance;

  String? get currentUserId => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _userHabitsRef {
    final uid = currentUserId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('habits');
  }

  CollectionReference<Map<String, dynamic>>? get _userHistoryRef {
    final uid = currentUserId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('habit_history');
  }

  CollectionReference<Map<String, dynamic>>? get _userReflectionsRef {
    final uid = currentUserId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('reflections');
  }

  CollectionReference<Map<String, dynamic>>? get _userGoalsRef {
    final uid = currentUserId;
    if (uid == null) return null;
    return _firestore.collection('users').doc(uid).collection('intentional_goals');
  }

  /// Syncs an individual habit to Cloud Firestore
  Future<void> syncHabitToCloud(Habit habit) async {
    final habitsRef = _userHabitsRef;
    if (habitsRef == null) return;

    try {
      final data = habit.toMap();
      data['serverUpdatedAt'] = FieldValue.serverTimestamp();
      await habitsRef.doc(habit.id).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirebaseHabitSyncService: syncHabitToCloud failed: $e');
    }
  }

  /// Batch syncs a list of habits to Cloud Firestore
  Future<void> syncHabitsToCloud(List<Habit> habits) async {
    final habitsRef = _userHabitsRef;
    if (habitsRef == null) return;

    try {
      final batch = _firestore.batch();
      for (final habit in habits) {
        final docRef = habitsRef.doc(habit.id);
        final data = habit.toMap();
        data['serverUpdatedAt'] = FieldValue.serverTimestamp();
        batch.set(docRef, data, SetOptions(merge: true));
      }
      await batch.commit();
    } catch (e) {
      debugPrint('FirebaseHabitSyncService: syncHabitsToCloud failed: $e');
    }
  }

  /// Deletes a habit from Cloud Firestore
  Future<void> deleteHabitFromCloud(String habitId) async {
    final habitsRef = _userHabitsRef;
    if (habitsRef == null) return;

    try {
      await habitsRef.doc(habitId).delete();
    } catch (e) {
      debugPrint('FirebaseHabitSyncService: deleteHabitFromCloud failed: $e');
    }
  }

  /// Fetches all habits stored in Cloud Firestore for the authenticated user
  Future<List<Habit>> fetchHabitsFromCloud() async {
    final habitsRef = _userHabitsRef;
    if (habitsRef == null) return [];

    try {
      final querySnapshot = await habitsRef.get();
      return querySnapshot.docs
          .map((doc) => Habit.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('FirebaseHabitSyncService: fetchHabitsFromCloud failed: $e');
      return [];
    }
  }

  /// Syncs daily completion summary to Cloud Firestore
  Future<void> syncDailyCompletionHistory(
    String dateKey,
    Map<String, dynamic> historyData,
  ) async {
    final historyRef = _userHistoryRef;
    if (historyRef == null) return;

    try {
      final data = Map<String, dynamic>.from(historyData);
      data['serverUpdatedAt'] = FieldValue.serverTimestamp();
      await historyRef.doc(dateKey).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirebaseHabitSyncService: syncDailyCompletionHistory failed: $e');
    }
  }

  /// Updates user stats (streak and completed count) on the main user document in Firestore
  Future<void> syncUserStats({
    required int currentStreak,
    required int totalCompletedHabits,
  }) async {
    final uid = currentUserId;
    if (uid == null) return;

    try {
      await _firestore.collection('users').doc(uid).set({
        'stats': {
          'currentStreak': currentStreak,
          'totalCompletedHabits': totalCompletedHabits,
        },
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirebaseHabitSyncService: syncUserStats failed: $e');
    }
  }

  /// Syncs a mindful reflection to Cloud Firestore
  Future<void> syncReflectionToCloud(Map<String, dynamic> reflection) async {
    final reflectionsRef = _userReflectionsRef;
    if (reflectionsRef == null) return;

    try {
      final id = reflection['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      final data = Map<String, dynamic>.from(reflection);
      data['serverUpdatedAt'] = FieldValue.serverTimestamp();
      await reflectionsRef.doc(id).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirebaseHabitSyncService: syncReflectionToCloud failed: $e');
    }
  }

  /// Deletes a reflection from Cloud Firestore
  Future<void> deleteReflectionFromCloud(String id) async {
    final reflectionsRef = _userReflectionsRef;
    if (reflectionsRef == null) return;

    try {
      await reflectionsRef.doc(id).delete();
    } catch (e) {
      debugPrint('FirebaseHabitSyncService: deleteReflectionFromCloud failed: $e');
    }
  }

  /// Syncs an intentional goal to Cloud Firestore
  Future<void> syncGoalToCloud(Map<String, dynamic> goal) async {
    final goalsRef = _userGoalsRef;
    if (goalsRef == null) return;

    try {
      final id = goal['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString();
      final data = Map<String, dynamic>.from(goal);
      data['serverUpdatedAt'] = FieldValue.serverTimestamp();
      await goalsRef.doc(id).set(data, SetOptions(merge: true));
    } catch (e) {
      debugPrint('FirebaseHabitSyncService: syncGoalToCloud failed: $e');
    }
  }

  /// Deletes an intentional goal from Cloud Firestore
  Future<void> deleteGoalFromCloud(String id) async {
    final goalsRef = _userGoalsRef;
    if (goalsRef == null) return;

    try {
      await goalsRef.doc(id).delete();
    } catch (e) {
      debugPrint('FirebaseHabitSyncService: deleteGoalFromCloud failed: $e');
    }
  }
}

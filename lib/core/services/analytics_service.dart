import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:flutter/foundation.dart';

class AnalyticsService {
  static final AnalyticsService _instance = AnalyticsService._internal();
  factory AnalyticsService() => _instance;
  AnalyticsService._internal();

  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;

  FirebaseAnalyticsObserver get observer =>
      FirebaseAnalyticsObserver(analytics: _analytics);

  /// Initializes analytics with default application metadata
  Future<void> initialize() async {
    try {
      await _analytics.setAnalyticsCollectionEnabled(true);
      await _analytics.setDefaultEventParameters({
        'app_name': 'Habitrak',
        'platform': defaultTargetPlatform.name,
      });
      debugPrint('AnalyticsService initialized successfully.');
    } catch (e) {
      debugPrint('AnalyticsService.initialize error: $e');
    }
  }

  /// Sets the user identifier for analytics tracking
  Future<void> setUserId(String? userId) async {
    try {
      await _analytics.setUserId(id: userId);
    } catch (e) {
      debugPrint('AnalyticsService.setUserId error: $e');
    }
  }

  /// Sets custom user properties for cohort research
  Future<void> setUserProperty({
    required String name,
    required String? value,
  }) async {
    try {
      await _analytics.setUserProperty(name: name, value: value);
    } catch (e) {
      debugPrint('AnalyticsService.setUserProperty error: $e');
    }
  }

  /// Tracks a screen/route transition
  Future<void> logScreenView({
    required String screenName,
    String? screenClass,
  }) async {
    try {
      await _analytics.logScreenView(
        screenName: screenName,
        screenClass: screenClass ?? screenName,
      );
    } catch (e) {
      debugPrint('AnalyticsService.logScreenView error: $e');
    }
  }

  // ==========================================
  // HABIT & BEHAVIORAL RESEARCH EVENTS
  // ==========================================

  /// Logs when a habit is marked completed with exact streak and progress data
  Future<void> logHabitCompleted({
    required String habitId,
    required String title,
    required String category,
    required int streak,
    required double targetProgress,
    required String unit,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'habit_completed',
        parameters: {
          'habit_id': habitId,
          'habit_title': title,
          'category': category,
          'streak_days': streak,
          'target_progress': targetProgress,
          'unit': unit,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService.logHabitCompleted error: $e');
    }
  }

  /// Logs when a habit completion is toggled off
  Future<void> logHabitUncompleted({
    required String habitId,
    required String title,
    required int streak,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'habit_uncompleted',
        parameters: {
          'habit_id': habitId,
          'habit_title': title,
          'streak_days': streak,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService.logHabitUncompleted error: $e');
    }
  }

  /// Logs incremental progress toward a quantitative habit
  Future<void> logHabitProgressUpdated({
    required String habitId,
    required String title,
    required double progress,
    required double targetProgress,
    required bool isCompleted,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'habit_progress_updated',
        parameters: {
          'habit_id': habitId,
          'habit_title': title,
          'progress': progress,
          'target_progress': targetProgress,
          'is_completed': isCompleted ? 1 : 0,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService.logHabitProgressUpdated error: $e');
    }
  }

  /// Logs the creation of a new habit intention
  Future<void> logHabitCreated({
    required String habitId,
    required String title,
    required String category,
    required double targetProgress,
    required String unit,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'habit_created',
        parameters: {
          'habit_id': habitId,
          'habit_title': title,
          'category': category,
          'target_progress': targetProgress,
          'unit': unit,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService.logHabitCreated error: $e');
    }
  }

  /// Logs streak milestone achievement (e.g. 7, 14, 21, 30, 60 days)
  Future<void> logStreakMilestone({
    required int streakDays,
    required int totalCompletedHabits,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'streak_milestone_achieved',
        parameters: {
          'streak_days': streakDays,
          'total_completed_habits': totalCompletedHabits,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService.logStreakMilestone error: $e');
    }
  }

  // ==========================================
  // MINDFULNESS & SOULFULNESS RESEARCH EVENTS
  // ==========================================

  /// Logs a completed meditation session with exact duration and ambient environment
  Future<void> logMeditationSession({
    required int durationMinutes,
    required String technique,
    required String ambientSound,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'meditation_session_completed',
        parameters: {
          'duration_minutes': durationMinutes,
          'technique': technique,
          'ambient_sound': ambientSound,
          'timestamp': DateTime.now().toIso8601String(),
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService.logMeditationSession error: $e');
    }
  }

  /// Logs a completed breathwork session with duration and technique
  Future<void> logBreathworkSession({
    required int durationMinutes,
    required String technique,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'breathwork_session_completed',
        parameters: {
          'duration_minutes': durationMinutes,
          'technique': technique,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService.logBreathworkSession error: $e');
    }
  }

  /// Logs a thought release session
  Future<void> logThoughtReleased({
    required int thoughtLength,
    required String releaseMethod,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'thought_released',
        parameters: {
          'char_length': thoughtLength,
          'release_method': releaseMethod,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService.logThoughtReleased error: $e');
    }
  }

  /// Logs a mindful reflection entry
  Future<void> logReflectionSaved({
    required int length,
    required String relativeDate,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'mindful_reflection_saved',
        parameters: {
          'char_length': length,
          'relative_date': relativeDate,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService.logReflectionSaved error: $e');
    }
  }

  /// Logs toggling of an intentional daily goal
  Future<void> logIntentionalGoalToggled({
    required String goalId,
    required String title,
    required bool completed,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'intentional_goal_toggled',
        parameters: {
          'goal_id': goalId,
          'goal_title': title,
          'is_completed': completed ? 1 : 0,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService.logIntentionalGoalToggled error: $e');
    }
  }

  // ==========================================
  // PHYSICAL ACTIVITY & EXERCISE EVENTS
  // ==========================================

  /// Logs a mindful walk tracker session with exact duration, distance, and calories
  Future<void> logWalkSession({
    required int durationMinutes,
    required double distanceKm,
    required int caloriesBurned,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'walk_session_completed',
        parameters: {
          'duration_minutes': durationMinutes,
          'distance_km': distanceKm,
          'calories_burned': caloriesBurned,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService.logWalkSession error: $e');
    }
  }

  /// Logs a yoga / posture exercise session
  Future<void> logYogaSession({
    required int durationMinutes,
    required int posesCompleted,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'yoga_session_completed',
        parameters: {
          'duration_minutes': durationMinutes,
          'poses_completed': posesCompleted,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService.logYogaSession error: $e');
    }
  }

  // ==========================================
  // WEARABLE & HEALTH SYNC EVENTS
  // ==========================================

  /// Logs daily wearable health summary data for physiological research
  Future<void> logHealthSummarySynced({
    required int steps,
    required double totalCalories,
    required double activeCalories,
    required double distanceKm,
    required int exerciseMinutes,
    required int sleepDurationMinutes,
    required int sleepEfficiency,
    required int avgHeartRate,
    required int restingHeartRate,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'health_summary_synced',
        parameters: {
          'steps': steps,
          'total_calories': totalCalories.round(),
          'active_calories': activeCalories.round(),
          'distance_km': distanceKm,
          'exercise_minutes': exerciseMinutes,
          'sleep_duration_mins': sleepDurationMinutes,
          'sleep_efficiency': sleepEfficiency,
          'avg_heart_rate': avgHeartRate,
          'resting_heart_rate': restingHeartRate,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService.logHealthSummarySynced error: $e');
    }
  }

  // ==========================================
  // RESEARCH EXPORTS & REPORTS
  // ==========================================

  /// Logs generation of clinical / progress PDF report
  Future<void> logProgressReportGenerated({
    required int streakDays,
    required int mindfulMinutes,
    required int totalCompletedHabits,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'progress_report_pdf_generated',
        parameters: {
          'streak_days': streakDays,
          'mindful_minutes': mindfulMinutes,
          'total_completed_habits': totalCompletedHabits,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService.logProgressReportGenerated error: $e');
    }
  }

  /// Logs user authentication state change
  Future<void> logAuthEvent({
    required String method,
    required bool isAnonymous,
  }) async {
    try {
      await _analytics.logEvent(
        name: 'user_authentication',
        parameters: {
          'auth_method': method,
          'is_anonymous': isAnonymous ? 1 : 0,
        },
      );
    } catch (e) {
      debugPrint('AnalyticsService.logAuthEvent error: $e');
    }
  }
}

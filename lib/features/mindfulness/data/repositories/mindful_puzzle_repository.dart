import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:habitrak/core/storage/hive_registrar.dart';
import 'package:habitrak/core/services/notification_service.dart';

class MindfulPuzzleRepository extends ChangeNotifier {
  final Box _box = Hive.box(HiveRegistrar.mindfulPuzzleBoxName);

  static const String _keyStreak = 'puzzle_streak';
  static const String _keyDayNumber = 'puzzle_day_number';
  static const String _keyVitality = 'puzzle_vitality';
  static const String _keyPlacedPieces = 'placed_pieces';
  static const String _keyLastCompletedDate = 'last_completed_date';
  static const String _keyAudioUnlocked = 'audio_unlocked';

  // Initial state as shown in design: 7 of 9 pieces harmonized (78%)
  // Slots 4 (Center Blossom) and 7 (Stone Ripples) are empty
  static const List<int> defaultInitialPlaced = [0, 1, 2, 3, 5, 6, 8];

  int get streak => _box.get(_keyStreak, defaultValue: 7) as int;
  int get dayNumber => _box.get(_keyDayNumber, defaultValue: 42) as int;
  int get vitality => _box.get(_keyVitality, defaultValue: 120) as int;
  bool get isAudioUnlocked =>
      _box.get(_keyAudioUnlocked, defaultValue: false) as bool;

  List<int> get placedPieceIndices {
    final raw = _box.get(_keyPlacedPieces, defaultValue: defaultInitialPlaced);
    if (raw is List) {
      return List<int>.from(raw);
    }
    return List<int>.from(defaultInitialPlaced);
  }

  bool isPiecePlaced(int index) => placedPieceIndices.contains(index);

  int get harmonizedCount => placedPieceIndices.length;
  double get harmonizedPercentage => (harmonizedCount / 9.0) * 100.0;
  bool get isGardenFullyHarmonized => harmonizedCount >= 9;

  String? get lastCompletedDate =>
      _box.get(_keyLastCompletedDate, defaultValue: null) as String?;

  bool get isCompletedToday {
    final today = _formatDate(DateTime.now());
    return lastCompletedDate == today;
  }

  static String _formatDate(DateTime dt) =>
      '${dt.year}-${dt.month.toString().padLeft(2, '0')}-${dt.day.toString().padLeft(2, '0')}';

  /// Place a specific piece into the grid
  Future<bool> placePiece(int pieceIndex) async {
    final current = List<int>.from(placedPieceIndices);
    if (current.contains(pieceIndex)) return false;

    current.add(pieceIndex);
    await _box.put(_keyPlacedPieces, current);

    // If all 9 pieces are harmonized:
    if (current.length >= 9) {
      await _onPuzzleCompleted();
    }

    notifyListeners();
    return true;
  }

  /// Automatically assists by placing the next missing piece
  Future<int?> harmonizeNextPiece() async {
    final current = List<int>.from(placedPieceIndices);
    for (int i = 0; i < 9; i++) {
      if (!current.contains(i)) {
        await placePiece(i);
        return i;
      }
    }
    return null;
  }

  Future<void> _onPuzzleCompleted() async {
    final today = _formatDate(DateTime.now());
    final alreadyDone = lastCompletedDate == today;

    if (!alreadyDone) {
      final newStreak = streak + 1;
      final newVitality = vitality + 15;
      await _box.put(_keyStreak, newStreak);
      await _box.put(_keyVitality, newVitality);
      await _box.put(_keyLastCompletedDate, today);
      await _box.put(_keyAudioUnlocked, true);

      // Cancel evening streak-loss reminders since the user achieved it today!
      await NotificationService().cancelStreakNotifications();
    }
  }

  /// Reset to play again or advance to the next day's mosaic
  Future<void> resetPuzzle({bool advanceDay = false}) async {
    if (advanceDay) {
      await _box.put(_keyDayNumber, dayNumber + 1);
    }
    await _box.put(_keyPlacedPieces, defaultInitialPlaced);
    notifyListeners();
  }

  /// Verify and notify if streak is not followed
  Future<void> checkStreakAndNotify() async {
    final today = _formatDate(DateTime.now());
    if (lastCompletedDate != today) {
      // Streak not yet followed today
      await NotificationService().scheduleDailyStreakCheckNotification(
        streak: streak,
        hour: 20, // 8 PM
        minute: 0,
      );
    }
  }
}

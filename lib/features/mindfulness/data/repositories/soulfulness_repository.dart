import 'dart:math' as math;
import 'package:hive/hive.dart';
import '../../../../core/storage/hive_registrar.dart';

/// Model representing a daily soul wisdom / contemplation quote.
class SoulWisdom {
  final String quote;
  final String author;
  final String theme;
  final String reflection;

  const SoulWisdom({
    required this.quote,
    required this.author,
    required this.theme,
    required this.reflection,
  });

  Map<String, dynamic> toMap() => {
    'quote': quote,
    'author': author,
    'theme': theme,
    'reflection': reflection,
  };

  factory SoulWisdom.fromMap(Map<String, dynamic> map) => SoulWisdom(
    quote: map['quote'] as String? ?? 'Be still and know peace.',
    author: map['author'] as String? ?? 'Ancient Wisdom',
    theme: map['theme'] as String? ?? 'Presence',
    reflection:
        map['reflection'] as String? ?? 'Take a deep breath and settle in.',
  );
}

class SoulfulnessRepository {
  final Box<dynamic> _box = Hive.box<dynamic>(HiveRegistrar.soulfulnessBoxName);

  static const String _keyMetaSyncDate = '__meta_last_soulfulness_date';
  static const String _keyDailyWisdomIndex = '__daily_wisdom_index';
  static const String _keyDailyPromptIndex = '__daily_prompt_index';
  static const String _keyTodayMeditationMinutes = '__today_meditation_minutes';
  static const String _keyTodayBreathworkSessions =
      '__today_breathwork_sessions';
  static const String _keyTodayReleasedThoughts = '__today_released_thoughts';
  static const String _keyTotalMeditationMinutes = '__total_meditation_minutes';
  static const String _keyTotalBreathworkSessions =
      '__total_breathwork_sessions';
  static const String _keyTotalReleasedThoughts = '__total_released_thoughts';
  static const String _keyMindfulStreak = '__mindful_streak';
  static const String _keyLastActiveDate = '__last_active_date';
  static const String _keyHistory = '__mindful_history';

  static const List<SoulWisdom> _wisdomQuotes = [
    SoulWisdom(
      quote: "Peace comes from within. Do not seek it without.",
      author: "Gautama Buddha",
      theme: "Inner Stillness",
      reflection: "Where can you let go of searching outside yourself today?",
    ),
    SoulWisdom(
      quote:
          "The soul should always stand ajar, ready to welcome the ecstatic experience.",
      author: "Emily Dickinson",
      theme: "Receptivity",
      reflection: "Allow this moment to be fresh and unhurried.",
    ),
    SoulWisdom(
      quote: "Nature does not hurry, yet everything is accomplished.",
      author: "Lao Tzu",
      theme: "Gentle Patience",
      reflection: "Release the rush. Trust your natural unfolding pace.",
    ),
    SoulWisdom(
      quote:
          "You have power over your mind - not outside events. Realize this, and you will find strength.",
      author: "Marcus Aurelius",
      theme: "Stoic Equanimity",
      reflection: "What is within your control right now? Focus there.",
    ),
    SoulWisdom(
      quote: "Silence is not the absence of sound, but the presence of peace.",
      author: "Thich Nhat Hanh",
      theme: "Deep Presence",
      reflection: "Pause between your activities for three slow breaths.",
    ),
    SoulWisdom(
      quote: "The wound is the place where the Light enters you.",
      author: "Rumi",
      theme: "Compassion",
      reflection: "Treat your tender spots with gentle curiosity today.",
    ),
    SoulWisdom(
      quote:
          "Feelings come and go like clouds in a windy sky. Conscious breathing is my anchor.",
      author: "Thich Nhat Hanh",
      theme: "Breath Anchor",
      reflection:
          "Your breath is an unwavering home you can return to anytime.",
    ),
    SoulWisdom(
      quote:
          "Almost everything will work again if you unplug it for a few minutes, including you.",
      author: "Anne Lamott",
      theme: "Rest & Reset",
      reflection: "Give yourself permission to pause without guilt.",
    ),
    SoulWisdom(
      quote:
          "Do not dwell in the past, do not dream of the future, concentrate the mind on the present moment.",
      author: "Buddhist Proverb",
      theme: "The Here & Now",
      reflection:
          "What is one sensory detail you can notice around you right now?",
    ),
    SoulWisdom(
      quote:
          "Simplicity, patience, compassion. These three are your greatest treasures.",
      author: "Tao Te Ching",
      theme: "Core Virtues",
      reflection: "How can you simplify your expectations for this afternoon?",
    ),
    SoulWisdom(
      quote:
          "In the midst of movement and chaos, keep stillness inside of you.",
      author: "Deepak Chopra",
      theme: "Centered Calms",
      reflection:
          "Like the center of a wheel, stay still while everything turns.",
    ),
    SoulWisdom(
      quote: "When you let go of who you are, you become what you might be.",
      author: "Lao Tzu",
      theme: "Letting Go",
      reflection: "Drop the heavy burden of having to be someone else.",
    ),
    SoulWisdom(
      quote: "Breathe in deeply to bring your mind home to your body.",
      author: "Thich Nhat Hanh",
      theme: "Embodiment",
      reflection: "Feel your feet on the ground and soften your shoulders.",
    ),
    SoulWisdom(
      quote: "Muddy water is best cleared by leaving it alone.",
      author: "Alan Watts",
      theme: "Non-Striving",
      reflection: "You don't have to fix everything right this second.",
    ),
    SoulWisdom(
      quote: "Act without expectation.",
      author: "Lao Tzu",
      theme: "Spaciousness",
      reflection:
          "Do your actions today for the joy of giving, not the outcome.",
    ),
  ];

  static const List<String> _gratitudePrompts = [
    "What is an unexpected kindness you witnessed or received today?",
    "What is a simple everyday comfort you often take for granted?",
    "Who is someone whose presence instantly puts you at ease?",
    "What sound in nature brings you an immediate sense of calm?",
    "What challenge in your past can you now look back on with gratitude?",
    "What is a part of your body that worked hard for you today?",
    "What is a warm memory from childhood that still brings a smile?",
    "What is one beautiful color, texture, or scent you experienced today?",
    "What is a book, song, or quote that spoke directly to your heart recently?",
    "What is a quiet moment you had all to yourself today?",
    "What mistake gave you wisdom that you are grateful to possess now?",
    "What is a small luxury (like hot coffee or a soft bed) you enjoy today?",
    "Who made you laugh recently, even for just a few seconds?",
    "What is something you love about the changing seasons right now?",
  ];

  String _todayKey() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _yesterdayKey() {
    final yest = DateTime.now().subtract(const Duration(days: 1));
    return '${yest.year}-${yest.month.toString().padLeft(2, '0')}-${yest.day.toString().padLeft(2, '0')}';
  }

  Future<void> ensureInitialized() async {
    final today = _todayKey();
    if (_box.get(_keyMetaSyncDate) == null) {
      await _box.put(_keyMetaSyncDate, today);
      await _box.put(_keyDailyWisdomIndex, 0);
      await _box.put(_keyDailyPromptIndex, 0);
      await _box.put(_keyTodayMeditationMinutes, 0);
      await _box.put(_keyTodayBreathworkSessions, 0);
      await _box.put(_keyTodayReleasedThoughts, 0);
      await _box.put(_keyTotalMeditationMinutes, 0);
      await _box.put(_keyTotalBreathworkSessions, 0);
      await _box.put(_keyTotalReleasedThoughts, 0);
      await _box.put(_keyMindfulStreak, 1);
      await _box.put(_keyLastActiveDate, today);
      await _box.put(_keyHistory, <Map<String, dynamic>>[]);
    }
    await syncDailySoulfulness();
  }

  Future<void> syncDailySoulfulness() async {
    final today = _todayKey();
    final lastSync = _box.get(_keyMetaSyncDate) as String?;

    if (lastSync != null && lastSync != today) {
      // Rotate quote & prompt based on day of year
      final now = DateTime.now();
      final dayOfYear = now.difference(DateTime(now.year, 1, 1)).inDays;
      final wisdomIdx = (dayOfYear + now.year) % _wisdomQuotes.length;
      final promptIdx = (dayOfYear + 7) % _gratitudePrompts.length;

      await _box.put(_keyDailyWisdomIndex, wisdomIdx);
      await _box.put(_keyDailyPromptIndex, promptIdx);

      // Check mindful streak
      final lastActive = _box.get(_keyLastActiveDate) as String?;
      final yesterday = _yesterdayKey();
      int currentStreak = (_box.get(_keyMindfulStreak) as int?) ?? 0;

      if (lastActive == yesterday) {
        // Streak is continuing!
      } else if (lastActive != today) {
        // Missed yesterday - reset streak to 0
        currentStreak = 0;
        await _box.put(_keyMindfulStreak, currentStreak);
      }

      // Reset today's session counters
      await _box.put(_keyTodayMeditationMinutes, 0);
      await _box.put(_keyTodayBreathworkSessions, 0);
      await _box.put(_keyTodayReleasedThoughts, 0);
      await _box.put(_keyMetaSyncDate, today);
    }
  }

  SoulWisdom getDailyWisdom() {
    final idx = (_box.get(_keyDailyWisdomIndex) as int?) ?? 0;
    final safeIdx = idx.clamp(0, _wisdomQuotes.length - 1);
    return _wisdomQuotes[safeIdx];
  }

  String getDailyPrompt() {
    final idx = (_box.get(_keyDailyPromptIndex) as int?) ?? 0;
    final safeIdx = idx.clamp(0, _gratitudePrompts.length - 1);
    return _gratitudePrompts[safeIdx];
  }

  Future<String> shuffleDailyPrompt() async {
    final currentIdx = (_box.get(_keyDailyPromptIndex) as int?) ?? 0;
    int nextIdx = (currentIdx + 1) % _gratitudePrompts.length;
    await _box.put(_keyDailyPromptIndex, nextIdx);
    return _gratitudePrompts[nextIdx];
  }

  Map<String, dynamic> getTodayStats() {
    return {
      'todayMeditationMinutes':
          (_box.get(_keyTodayMeditationMinutes) as int?) ?? 0,
      'todayBreathworkSessions':
          (_box.get(_keyTodayBreathworkSessions) as int?) ?? 0,
      'todayReleasedThoughts':
          (_box.get(_keyTodayReleasedThoughts) as int?) ?? 0,
      'totalMeditationMinutes':
          (_box.get(_keyTotalMeditationMinutes) as int?) ?? 0,
      'totalBreathworkSessions':
          (_box.get(_keyTotalBreathworkSessions) as int?) ?? 0,
      'totalReleasedThoughts':
          (_box.get(_keyTotalReleasedThoughts) as int?) ?? 0,
      'mindfulStreak': (_box.get(_keyMindfulStreak) as int?) ?? 0,
    };
  }

  int getMindfulStreak() {
    return (_box.get(_keyMindfulStreak) as int?) ?? 0;
  }

  Future<void> _updateStreakAndActiveDate() async {
    final today = _todayKey();
    final lastActive = _box.get(_keyLastActiveDate) as String?;
    int streak = (_box.get(_keyMindfulStreak) as int?) ?? 0;

    if (lastActive != today) {
      final yesterday = _yesterdayKey();
      if (lastActive == yesterday || streak == 0) {
        streak++;
      } else {
        streak = 1;
      }
      await _box.put(_keyMindfulStreak, streak);
      await _box.put(_keyLastActiveDate, today);
    }
  }

  Future<void> recordMeditationSession({
    required int durationMinutes,
    String technique = 'Zen Silence',
  }) async {
    final todayMins =
        ((_box.get(_keyTodayMeditationMinutes) as int?) ?? 0) + durationMinutes;
    final totalMins =
        ((_box.get(_keyTotalMeditationMinutes) as int?) ?? 0) + durationMinutes;

    await _box.put(_keyTodayMeditationMinutes, todayMins);
    await _box.put(_keyTotalMeditationMinutes, totalMins);
    await _updateStreakAndActiveDate();

    await _addHistoryEntry({
      'type': 'meditation',
      'title': '$technique Meditation',
      'minutes': durationMinutes,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> recordBreathworkSession({
    required String patternName,
    required int cycles,
    required int durationSeconds,
  }) async {
    final todaySessions =
        ((_box.get(_keyTodayBreathworkSessions) as int?) ?? 0) + 1;
    final totalSessions =
        ((_box.get(_keyTotalBreathworkSessions) as int?) ?? 0) + 1;
    final durationMinutes = math.max(1, (durationSeconds / 60).round());

    final todayMins =
        ((_box.get(_keyTodayMeditationMinutes) as int?) ?? 0) + durationMinutes;
    final totalMins =
        ((_box.get(_keyTotalMeditationMinutes) as int?) ?? 0) + durationMinutes;

    await _box.put(_keyTodayBreathworkSessions, todaySessions);
    await _box.put(_keyTotalBreathworkSessions, totalSessions);
    await _box.put(_keyTodayMeditationMinutes, todayMins);
    await _box.put(_keyTotalMeditationMinutes, totalMins);
    await _updateStreakAndActiveDate();

    await _addHistoryEntry({
      'type': 'breathwork',
      'title': '$patternName Breathwork ($cycles cycles)',
      'minutes': durationMinutes,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> recordThoughtRelease() async {
    final todayCount = ((_box.get(_keyTodayReleasedThoughts) as int?) ?? 0) + 1;
    final totalCount = ((_box.get(_keyTotalReleasedThoughts) as int?) ?? 0) + 1;

    await _box.put(_keyTodayReleasedThoughts, todayCount);
    await _box.put(_keyTotalReleasedThoughts, totalCount);
    await _updateStreakAndActiveDate();

    await _addHistoryEntry({
      'type': 'thought_release',
      'title': 'Released a thought to the river',
      'minutes': 1,
      'timestamp': DateTime.now().toIso8601String(),
    });
  }

  Future<void> _addHistoryEntry(Map<String, dynamic> entry) async {
    final raw = _box.get(_keyHistory);
    final history = raw != null
        ? List<Map<String, dynamic>>.from(
            (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
          )
        : <Map<String, dynamic>>[];

    history.insert(0, entry);
    if (history.length > 50) {
      history.removeRange(50, history.length);
    }
    await _box.put(_keyHistory, history);
  }

  List<Map<String, dynamic>> getRecentHistory() {
    final raw = _box.get(_keyHistory);
    if (raw == null) return [];
    return List<Map<String, dynamic>>.from(
      (raw as List).map((e) => Map<String, dynamic>.from(e as Map)),
    );
  }
}

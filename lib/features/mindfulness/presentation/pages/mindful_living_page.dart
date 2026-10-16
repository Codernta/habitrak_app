import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitrak/core/animations/animated_modal_sheet.dart';
import 'package:habitrak/core/animations/app_animations.dart';
import 'package:habitrak/core/animations/pressable_scale.dart';
import 'package:habitrak/core/animations/staggered_entrance.dart';
import 'package:habitrak/core/storage/settings_repository.dart';
import '../../data/repositories/reflections_repository.dart';
import '../../data/repositories/intentional_goals_repository.dart';
import '../../data/repositories/soulfulness_repository.dart';
import '../widgets/breathwork_modal.dart';
import '../widgets/meditation_timer_modal.dart';
import '../widgets/thought_release_modal.dart';
import '../widgets/sound_bath_modal.dart';

class MindfulLivingPage extends StatefulWidget {
  const MindfulLivingPage({super.key});

  @override
  State<MindfulLivingPage> createState() => _MindfulLivingPageState();
}

class _MindfulLivingPageState extends State<MindfulLivingPage> {
  final TextEditingController _journalController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  late ReflectionsRepository _reflectionsRepo;
  late IntentionalGoalsRepository _goalsRepo;
  late SettingsRepository _settingsRepo;
  late SoulfulnessRepository _soulfulnessRepo;

  List<Map<String, dynamic>> _reflections = [];
  List<Map<String, dynamic>> _intentionalGoals = [];
  SoulWisdom? _dailyWisdom;
  String _dailyPrompt = '';
  Map<String, dynamic> _soulStats = {};
  int _mindfulStreak = 0;
  bool _isFocusMode = false;
  bool _isDndSchedule = false;
  int _dailyScreenTime = 135;
  int _screenTimeLimit = 180;
  String _lastEntryTime = 'Never';

  @override
  void initState() {
    super.initState();
    _reflectionsRepo = context.read<ReflectionsRepository>();
    _goalsRepo = context.read<IntentionalGoalsRepository>();
    _settingsRepo = context.read<SettingsRepository>();
    _soulfulnessRepo = context.read<SoulfulnessRepository>();

    _reflections = List.from(_reflectionsRepo.getReflections());
    _isFocusMode = _settingsRepo.isFocusModeEnabled;
    _isDndSchedule = _settingsRepo.isDndScheduleEnabled;
    _dailyScreenTime = _settingsRepo.dailyScreenTimeMinutes;
    _screenTimeLimit = _settingsRepo.screenTimeLimitMinutes;
    _lastEntryTime = _reflectionsRepo.getLastEntryTime();

    _dailyWisdom = _soulfulnessRepo.getDailyWisdom();
    _dailyPrompt = _soulfulnessRepo.getDailyPrompt();
    _soulStats = _soulfulnessRepo.getTodayStats();
    _mindfulStreak = _soulfulnessRepo.getMindfulStreak();

    // Ensure daily syncs
    _soulfulnessRepo.syncDailySoulfulness().then((_) {
      if (mounted) _refreshSoulData();
    });

    // Ensure intentional goals are synced for today
    _goalsRepo.syncDailyGoals().then((_) {
      if (mounted) {
        setState(() {
          _intentionalGoals = List.from(_goalsRepo.getGoals());
        });
      }
    });
    _intentionalGoals = List.from(_goalsRepo.getGoals());
  }

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  void _refreshSoulData() {
    if (mounted) {
      setState(() {
        _soulStats = _soulfulnessRepo.getTodayStats();
        _mindfulStreak = _soulfulnessRepo.getMindfulStreak();
        _dailyWisdom = _soulfulnessRepo.getDailyWisdom();
        _dailyPrompt = _soulfulnessRepo.getDailyPrompt();
      });
    }
  }

  void _openBreathwork() {
    HapticFeedback.selectionClick();
    showAnimatedModalSheet(
      context: context,
      builder: (_) => const BreathworkModal(),
    ).then((_) => _refreshSoulData());
  }

  void _openMeditation() {
    HapticFeedback.selectionClick();
    showAnimatedModalSheet(
      context: context,
      builder: (_) => const MeditationTimerModal(),
    ).then((_) => _refreshSoulData());
  }

  void _openThoughtRelease() {
    HapticFeedback.selectionClick();
    showAnimatedModalSheet(
      context: context,
      builder: (_) => const ThoughtReleaseModal(),
    ).then((_) => _refreshSoulData());
  }

  void _openSoundBath() {
    HapticFeedback.selectionClick();
    showAnimatedModalSheet(
      context: context,
      builder: (_) => const SoundBathModal(),
    ).then((_) => _refreshSoulData());
  }

  Future<void> _shuffleDailyPrompt() async {
    HapticFeedback.selectionClick();
    final newPrompt = await _soulfulnessRepo.shuffleDailyPrompt();
    if (mounted) {
      setState(() {
        _dailyPrompt = newPrompt;
      });
    }
  }

  Future<void> _saveReflection() async {
    final text = _journalController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();
    final newRef = await _reflectionsRepo.addReflection(text);
    if (mounted) {
      setState(() {
        _reflections.insert(0, newRef);
        _lastEntryTime = 'Just now';
      });
      _listKey.currentState?.insertItem(
        0,
        duration: const Duration(milliseconds: 500),
      );
      _journalController.clear();

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Gratitude entry saved!')));
    }
  }

  void _toggleGoal(int index) {
    final goal = _intentionalGoals[index];
    final id = goal['id'] as String;
    final newStatus = !(goal['completed'] == true);
    if (newStatus) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    _goalsRepo.toggleGoal(id);
    setState(() {
      _intentionalGoals[index]['completed'] = newStatus;
    });
  }

  void _showAddGoalDialog() {
    final titleController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xff1e201e) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Text(
            'New Intentional Goal',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: TextField(
            controller: titleController,
            autofocus: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              hintText: 'e.g., Afternoon 10m walk',
              hintStyle: TextStyle(
                color: isDark
                    ? const Color(0xffc2c8c0).withValues(alpha: 0.4)
                    : const Color(0xff615e56).withValues(alpha: 0.4),
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                final title = titleController.text.trim();
                if (title.isNotEmpty) {
                  final newGoal = await _goalsRepo.addGoal(title);
                  if (mounted) {
                    setState(() {
                      _intentionalGoals.add(newGoal);
                    });
                    HapticFeedback.lightImpact();
                  }
                }
                if (context.mounted) {
                  Navigator.pop(context);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff8ba88e),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text('Add'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildGoalCheckbox(bool isCompleted, Color primaryColor, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? primaryColor : Colors.transparent,
        border: Border.all(
          color: isCompleted
              ? primaryColor
              : (isDark ? const Color(0xff424842) : const Color(0xffa4a097)),
          width: 2,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) =>
            ScaleTransition(scale: anim, child: child),
        child: isCompleted
            ? const Icon(
                Icons.check,
                key: ValueKey('check'),
                size: 12,
                color: Colors.white,
              )
            : const SizedBox(key: ValueKey('empty')),
      ),
    );
  }

  Widget _buildReflectionItem(
    Map<String, dynamic> ref,
    Animation<double> animation,
    Color primaryColor,
    bool isDark,
  ) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0.0, -0.2),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutBack),
              ),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (ref['date'] as String?) ?? 'Today',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  (ref['text'] as String?) ?? '',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 14,
                    color: isDark
                        ? const Color(0xffc2c8c0)
                        : const Color(0xff615e56),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: primaryColor.withValues(alpha: 0.15), height: 1),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? const Color(0xffb0ceb2)
        : const Color(0xff8ba88e);
    final cardBg = isDark ? const Color(0xff1e201e) : const Color(0xffffffff);

    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'Mindful Living',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            if (_dailyWisdom != null) ...[
              StaggeredEntrance(
                index: 0,
                child: _buildDailyWisdomCard(isDark, primaryColor, cardBg),
              ),
              const SizedBox(height: 20),
            ],
            StaggeredEntrance(
              index: 1,
              child: _buildSoulSanctuaryHub(isDark, primaryColor, cardBg),
            ),
            const SizedBox(height: 18),
            StaggeredEntrance(
              index: 2,
              child: _buildMindfulStatsStrip(isDark, primaryColor, cardBg),
            ),
            const SizedBox(height: 24),
            StaggeredEntrance(
              index: 3,
              child: _buildGratitudeCard(isDark, primaryColor, cardBg),
            ),
            const SizedBox(height: 24),
            StaggeredEntrance(
              index: 4,
              child: _buildGoalsCard(isDark, primaryColor, cardBg),
            ),
            const SizedBox(height: 24),
            StaggeredEntrance(
              index: 5,
              child: _buildWellBeingCard(isDark, primaryColor, cardBg),
            ),
            const SizedBox(height: 24),
            StaggeredEntrance(
              index: 6,
              child: _buildRecentReflections(isDark, primaryColor, cardBg),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildDailyWisdomCard(bool isDark, Color primaryColor, Color cardBg) {
    if (_dailyWisdom == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xff424842).withValues(alpha: 0.1)
              : const Color(0xffdbdad7).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.auto_awesome, color: primaryColor, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      'DAILY SOUL WISDOM • ${_dailyWisdom!.theme.toUpperCase()}',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                'Today',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 11,
                  color: isDark
                      ? const Color(0xffc2c8c0).withValues(alpha: 0.5)
                      : const Color(0xff615e56).withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '"${_dailyWisdom!.quote}"',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 16,
              fontStyle: FontStyle.italic,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '— ${_dailyWisdom!.author}',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 14),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xff182219).withValues(alpha: 0.5)
                  : const Color(0xfff3f7f3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 16,
                  color: primaryColor,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _dailyWisdom!.reflection,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 12,
                      color: isDark
                          ? const Color(0xffc2c8c0).withValues(alpha: 0.85)
                          : const Color(0xff615e56).withValues(alpha: 0.85),
                      height: 1.3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSoulSanctuaryHub(bool isDark, Color primaryColor, Color cardBg) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Icon(Icons.spa_rounded, color: primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Soulful Practices',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSanctuaryCard(
                title: 'Breathwork',
                subtitle: 'Box, 4-7-8, Prana',
                icon: Icons.air_rounded,
                primaryColor: primaryColor,
                isDark: isDark,
                cardBg: cardBg,
                onTap: _openBreathwork,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSanctuaryCard(
                title: 'Meditation',
                subtitle: 'Singing bowl timer',
                icon: Icons.self_improvement_rounded,
                primaryColor: primaryColor,
                isDark: isDark,
                cardBg: cardBg,
                onTap: _openMeditation,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildSanctuaryCard(
                title: 'Release Thought',
                subtitle: 'Surrender to river',
                icon: Icons.waves_rounded,
                primaryColor: primaryColor,
                isDark: isDark,
                cardBg: cardBg,
                onTap: _openThoughtRelease,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildSanctuaryCard(
                title: 'Sound Bath',
                subtitle: 'Ambient nature mixer',
                icon: Icons.graphic_eq_rounded,
                primaryColor: primaryColor,
                isDark: isDark,
                cardBg: cardBg,
                onTap: _openSoundBath,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSanctuaryCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color primaryColor,
    required bool isDark,
    required Color cardBg,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark
                ? const Color(0xff424842).withValues(alpha: 0.1)
                : const Color(0xffdbdad7).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: primaryColor.withValues(alpha: 0.15),
              ),
              child: Icon(icon, color: primaryColor, size: 20),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 11,
                color: isDark
                    ? const Color(0xffc2c8c0).withValues(alpha: 0.6)
                    : const Color(0xff615e56).withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMindfulStatsStrip(
    bool isDark,
    Color primaryColor,
    Color cardBg,
  ) {
    final todayMins = (_soulStats['todayMeditationMinutes'] as int?) ?? 0;
    final todayBreaths = (_soulStats['todayBreathworkSessions'] as int?) ?? 0;
    final todayThoughts = (_soulStats['todayReleasedThoughts'] as int?) ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? const Color(0xff424842).withValues(alpha: 0.1)
              : const Color(0xffdbdad7).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            'Meditated',
            '${todayMins}m',
            Icons.self_improvement_rounded,
            primaryColor,
            isDark,
          ),
          _buildStatDivider(isDark),
          _buildStatItem(
            'Breaths',
            '$todayBreaths',
            Icons.air_rounded,
            primaryColor,
            isDark,
          ),
          _buildStatDivider(isDark),
          _buildStatItem(
            'Released',
            '$todayThoughts',
            Icons.waves_rounded,
            primaryColor,
            isDark,
          ),
          _buildStatDivider(isDark),
          _buildStatItem(
            'Streak',
            '$_mindfulStreak d',
            Icons.local_fire_department_rounded,
            primaryColor,
            isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color primary,
    bool isDark,
  ) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: primary),
            const SizedBox(width: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 10,
            color: isDark
                ? const Color(0xffc2c8c0).withValues(alpha: 0.5)
                : const Color(0xff615e56).withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }

  Widget _buildStatDivider(bool isDark) {
    return Container(
      height: 24,
      width: 1,
      color: isDark
          ? const Color(0xff424842).withValues(alpha: 0.3)
          : const Color(0xffdbdad7).withValues(alpha: 0.5),
    );
  }

  Widget _buildGratitudeCard(bool isDark, Color primaryColor, Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xff424842).withValues(alpha: 0.1)
              : const Color(0xffdbdad7).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.edit_note, color: primaryColor, size: 24),
              const SizedBox(width: 10),
              Text(
                'Daily Gratitude Journal',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Last entry: $_lastEntryTime',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? const Color(0xffc2c8c0).withValues(alpha: 0.5)
                  : const Color(0xff615e56).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 14),

          // Dynamic daily prompt banner with shuffle button
          if (_dailyPrompt.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xff182219).withValues(alpha: 0.5)
                    : const Color(0xfff3f7f3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.format_quote_rounded,
                    size: 18,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _dailyPrompt,
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.shuffle_rounded,
                      size: 18,
                      color: primaryColor,
                    ),
                    tooltip: 'Shuffle Inspiration',
                    onPressed: _shuffleDailyPrompt,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          TextField(
            controller: _journalController,
            maxLines: 3,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'Reflect and write freely...',
              hintStyle: TextStyle(
                color: isDark
                    ? const Color(0xffc2c8c0).withValues(alpha: 0.4)
                    : const Color(0xff615e56).withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: isDark
                  ? const Color(0xff1a1c1a)
                  : const Color(0xfff2f1ee),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveReflection,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: isDark ? const Color(0xff1c3622) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              elevation: 0,
            ),
            child: const Text(
              'SAVE ENTRY',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsCard(bool isDark, Color primaryColor, Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xff424842).withValues(alpha: 0.1)
              : const Color(0xffdbdad7).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Intentional Goals',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  _showAddGoalDialog();
                },
                color: primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (_intentionalGoals.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12.0),
              child: Text(
                'No intentional goals set. Tap + to add one!',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xffc2c8c0).withValues(alpha: 0.5)
                      : const Color(0xff615e56).withValues(alpha: 0.5),
                ),
              ),
            )
          else
            ..._intentionalGoals.asMap().entries.map((entry) {
              final idx = entry.key;
              final g = entry.value;
              final isCompleted = g['completed'] == true;

              return TweenAnimationBuilder<double>(
                key: ValueKey(g['id'] ?? g['title']),
                tween: Tween<double>(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeOutQuad,
                builder: (context, val, child) {
                  return Opacity(
                    opacity: AppAnimations.clampOpacity(val),
                    child: Transform.translate(
                      offset: Offset(0, 15 * (1.0 - val)),
                      child: child,
                    ),
                  );
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6.0),
                  child: InkWell(
                    onTap: () => _toggleGoal(idx),
                    child: Row(
                      children: [
                        _buildGoalCheckbox(isCompleted, primaryColor, isDark),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            g['title'] as String,
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 14,
                              decoration: isCompleted
                                  ? TextDecoration.lineThrough
                                  : null,
                              color: isCompleted
                                  ? (isDark
                                        ? const Color(
                                            0xffc2c8c0,
                                          ).withValues(alpha: 0.5)
                                        : const Color(
                                            0xff615e56,
                                          ).withValues(alpha: 0.5))
                                  : (isDark ? Colors.white : Colors.black),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildWellBeingCard(bool isDark, Color primaryColor, Color cardBg) {
    final dailyHours = _dailyScreenTime ~/ 60;
    final dailyMins = _dailyScreenTime % 60;
    final limitHours = _screenTimeLimit ~/ 60;
    final screenRatio =
        (_dailyScreenTime / (_screenTimeLimit > 0 ? _screenTimeLimit : 1))
            .clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xff424842).withValues(alpha: 0.1)
              : const Color(0xffdbdad7).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.phonelink_off_rounded, color: primaryColor, size: 22),
              const SizedBox(width: 10),
              Text(
                'Digital Well-being',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Screen Time Tracker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SCREEN TIME LIMIT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: isDark
                      ? const Color(0xffc2c8c0).withValues(alpha: 0.5)
                      : const Color(0xff615e56).withValues(alpha: 0.5),
                ),
              ),
              Text(
                '${dailyHours}h ${dailyMins}m / ${limitHours}h',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: screenRatio,
              minHeight: 6,
              backgroundColor: isDark
                  ? const Color(0xff1a1c1a)
                  : const Color(0xfff2f1ee),
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
          const SizedBox(height: 20),
          // Focus mode scheduler row
          _buildWellBeingToggle(
            'Focus Mode',
            Icons.bedtime_outlined,
            _isFocusMode,
            primaryColor,
            isDark,
            (val) {
              setState(() => _isFocusMode = val);
              _settingsRepo.setFocusModeEnabled(val);
            },
          ),
          const SizedBox(height: 12),
          _buildWellBeingToggle(
            'DND Schedule',
            Icons.notifications_paused_outlined,
            _isDndSchedule,
            primaryColor,
            isDark,
            (val) {
              setState(() => _isDndSchedule = val);
              _settingsRepo.setDndScheduleEnabled(val);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildWellBeingToggle(
    String label,
    IconData icon,
    bool active,
    Color primary,
    bool isDark,
    ValueChanged<bool> onChanged,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: isDark ? const Color(0xffc2c8c0) : const Color(0xff615e56),
            ),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        Switch.adaptive(
          value: active,
          activeTrackColor: primary,
          onChanged: (val) {
            HapticFeedback.selectionClick();
            onChanged(val);
          },
        ),
      ],
    );
  }

  Widget _buildRecentReflections(
    bool isDark,
    Color primaryColor,
    Color cardBg,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? const Color(0xff424842).withValues(alpha: 0.1)
              : const Color(0xffdbdad7).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Recent Reflections',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          if (_reflections.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Text(
                'No reflections yet. Write your first entry above!',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xffc2c8c0).withValues(alpha: 0.5)
                      : const Color(0xff615e56).withValues(alpha: 0.5),
                ),
              ),
            )
          else
            AnimatedList(
              key: _listKey,
              initialItemCount: _reflections.length,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemBuilder: (context, index, animation) {
                final ref = _reflections[index];
                return _buildReflectionItem(
                  ref,
                  animation,
                  primaryColor,
                  isDark,
                );
              },
            ),
        ],
      ),
    );
  }
}

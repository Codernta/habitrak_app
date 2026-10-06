import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitrak/core/animations/app_animations.dart';
import 'package:habitrak/core/animations/staggered_entrance.dart';
import 'package:habitrak/core/storage/settings_repository.dart';
import '../../data/repositories/reflections_repository.dart';
import '../../data/repositories/intentional_goals_repository.dart';
import '../../data/repositories/mindful_puzzle_repository.dart';
import 'mindful_garden_puzzle_page.dart';

class MindfulLivingPage extends StatefulWidget {
  const MindfulLivingPage({super.key});

  @override
  State<MindfulLivingPage> createState() => _MindfulLivingPageState();
}

class _MindfulLivingPageState extends State<MindfulLivingPage> {
  final TextEditingController _journalController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  int _selectedSegment = 0; // 0: Zen Garden Game, 1: Gratitude & Goals
  late ReflectionsRepository _reflectionsRepo;
  late IntentionalGoalsRepository _goalsRepo;
  late SettingsRepository _settingsRepo;

  List<Map<String, dynamic>> _reflections = [];
  List<Map<String, dynamic>> _intentionalGoals = [];
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

    _reflections = List.from(_reflectionsRepo.getReflections());
    _intentionalGoals = List.from(_goalsRepo.getGoals());
    _isFocusMode = _settingsRepo.isFocusModeEnabled;
    _isDndSchedule = _settingsRepo.isDndScheduleEnabled;
    _dailyScreenTime = _settingsRepo.dailyScreenTimeMinutes;
    _screenTimeLimit = _settingsRepo.screenTimeLimitMinutes;
    _lastEntryTime = _reflectionsRepo.getLastEntryTime();
  }

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E221E) : const Color(0xFFEBE6DC),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedSegment = 0);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedSegment == 0
                            ? const Color(0xFF38573E)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.spa_rounded,
                            size: 16,
                            color: _selectedSegment == 0
                                ? Colors.white
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Zen Garden Game',
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _selectedSegment == 0
                                  ? Colors.white
                                  : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _selectedSegment = 1);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        color: _selectedSegment == 1
                            ? const Color(0xFF38573E)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit_note_rounded,
                            size: 16,
                            color: _selectedSegment == 1
                                ? Colors.white
                                : (isDark ? Colors.white60 : Colors.black54),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Journal & Goals',
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: _selectedSegment == 1
                                  ? Colors.white
                                  : (isDark ? Colors.white60 : Colors.black54),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _selectedSegment == 0
          ? MindfulGardenPuzzlePage(
              repository: context.read<MindfulPuzzleRepository>(),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  StaggeredEntrance(
                    index: 0,
                    child: _buildGratitudeCard(isDark, primaryColor, cardBg),
                  ),
                  const SizedBox(height: 24),
                  StaggeredEntrance(
                    index: 1,
                    child: _buildGoalsCard(isDark, primaryColor, cardBg),
                  ),
                  const SizedBox(height: 24),
                  StaggeredEntrance(
                    index: 2,
                    child: _buildWellBeingCard(isDark, primaryColor, cardBg),
                  ),
                  const SizedBox(height: 24),
                  StaggeredEntrance(
                    index: 3,
                    child: _buildRecentReflections(
                      isDark,
                      primaryColor,
                      cardBg,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
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
          const SizedBox(height: 18),
          TextField(
            controller: _journalController,
            maxLines: 3,
            style: TextStyle(
              color: isDark ? Colors.white : Colors.black,
              fontSize: 14,
            ),
            decoration: InputDecoration(
              hintText: 'What is one thing you are grateful for today?',
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

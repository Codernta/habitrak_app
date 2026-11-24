import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:haptic_flow/haptic_flow.dart';
import 'package:habitrak/core/animations/app_animations.dart';
import 'package:habitrak/core/animations/staggered_entrance.dart';
import 'package:habitrak/core/theme/app_theme.dart';
import 'package:habitrak/features/habit/domain/entities/habit.dart';
import 'package:habitrak/features/habit/presentation/bloc/habit_bloc.dart';
import '../../data/repositories/activity_repository.dart';

class YogaExercisesPage extends StatefulWidget {
  const YogaExercisesPage({super.key});

  @override
  State<YogaExercisesPage> createState() => _YogaExercisesPageState();
}

class _YogaExercisesPageState extends State<YogaExercisesPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _breathingController;
  late Animation<double> _coreBreathingAnimation;
  late Animation<double> _midBreathingAnimation;
  late Animation<double> _outerBreathingAnimation;
  String _breathingStatus = 'Inhale';
  int _selectedPaceSeconds = 4;

  final List<Map<String, dynamic>> _stretchPoses = [
    {'title': 'Child\'s Pose', 'duration': '2 mins', 'completed': false},
    {'title': 'Cat-Cow Stretch', 'duration': '1 min', 'completed': false},
    {'title': 'Downward Dog', 'duration': '2 mins', 'completed': false},
    {'title': 'Cobra Pose', 'duration': '1 min', 'completed': false},
  ];

  @override
  void initState() {
    super.initState();
    _initBreathingController(_selectedPaceSeconds);
  }

  void _initBreathingController(int seconds) {
    _breathingController = AnimationController(
      vsync: this,
      duration: Duration(seconds: seconds),
    );

    _coreBreathingAnimation = Tween<double>(begin: 0.7, end: 1.15).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _midBreathingAnimation = Tween<double>(begin: 0.65, end: 1.35).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: const Interval(0.1, 1.0, curve: Curves.easeOut),
      ),
    );

    _outerBreathingAnimation = Tween<double>(begin: 0.6, end: 1.6).animate(
      CurvedAnimation(
        parent: _breathingController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeOut),
      ),
    );

    _breathingController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() {
          _breathingStatus = 'Exhale';
        });
        HapticFlow.selection();
        _breathingController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          _breathingStatus = 'Inhale';
        });
        HapticFlow.selection();
        _breathingController.forward();
      }
    });

    _breathingController.forward();
  }

  void _changePace(int seconds) {
    if (_selectedPaceSeconds == seconds) return;
    HapticFlow.light();
    _breathingController.dispose();
    setState(() {
      _selectedPaceSeconds = seconds;
      _breathingStatus = 'Inhale';
    });
    _initBreathingController(seconds);
  }

  @override
  void dispose() {
    _breathingController.dispose();
    super.dispose();
  }

  Widget _buildPoseCheckbox(bool isCompleted, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? AppColors.limeAccent : Colors.transparent,
        border: Border.all(
          color: isCompleted
              ? AppColors.limeAccent
              : (isDark ? AppColors.charcoalBorder : const Color(0xFFD1D5DB)),
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
                size: 14,
                color: Color(0xFF1E201E),
              )
            : const SizedBox(key: ValueKey('empty')),
      ),
    );
  }

  void _togglePose(int index) {
    final newStatus = !_stretchPoses[index]['completed'];
    if (newStatus) {
      HapticFlow.play(HapticPresets.successSnap);
    } else {
      HapticFlow.light();
    }
    setState(() {
      _stretchPoses[index]['completed'] = newStatus;
    });
  }

  void _finishRoutine() {
    HapticFlow.play(HapticPresets.sparkle);
    final completedCount = _stretchPoses
        .where((p) => p['completed'] == true)
        .length;
    final totalPoses = _stretchPoses.length;
    final posesCount = completedCount == 0 ? totalPoses : completedCount;
    const durationMinutes = 6; // Standard 6 min stretch routine

    // Log to Hive activity_logs
    context.read<ActivityRepository>().logYogaSession(
      durationMinutes: durationMinutes,
      posesCompleted: posesCount,
    );

    // Complete mindfulness habit in HabitBloc
    context.read<HabitBloc>().add(
      const CompleteActivityHabitEvent(category: HabitCategory.mindfulness),
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: AppColors.limeAccent, size: 20),
            const SizedBox(width: 8),
            Text(
              'Yoga routine completed! ($durationMinutes mins, $posesCount poses)',
              style: const TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.obsidianBlack,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : AppColors.obsidianBlack;
    final textMuted = isDark ? const Color(0xFFA0A5AD) : const Color(0xFF7A7E85);
    final cardBg = isDark ? AppColors.charcoalCard : Colors.white;
    final borderCol = isDark ? AppColors.charcoalBorder : const Color(0xFFE8E9EC);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F1012) : const Color(0xFFF9FAFB),
      appBar: AppBar(
        title: Text(
          'Yoga & Exercises',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: textPrimary,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            StaggeredEntrance(
              index: 0,
              child: _buildBreathingSection(isDark, cardBg, borderCol, textPrimary, textMuted),
            ),
            const SizedBox(height: 20),
            StaggeredEntrance(
              index: 1,
              child: _buildPosesSection(isDark, cardBg, borderCol, textPrimary, textMuted),
            ),
            const SizedBox(height: 24),
            StaggeredEntrance(
              index: 2,
              child: ElevatedButton.icon(
                onPressed: _finishRoutine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? AppColors.limeAccent : AppColors.obsidianBlack,
                  foregroundColor: isDark ? const Color(0xFF1E201E) : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18),
                  ),
                  elevation: 0,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 22),
                label: const Text(
                  'Finish Routine',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildBreathingSection(
    bool isDark,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderCol, width: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            'Breathing Guide',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 17,
              fontWeight: FontWeight.w700,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Inhale as the circle expands, exhale as it contracts',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 12,
              color: textMuted,
            ),
          ),
          const SizedBox(height: 36),
          // Interactive glowing expansion bubble with Neo-Health Lavender / Lime
          Center(
            child: AnimatedBuilder(
              animation: _breathingController,
              builder: (context, child) {
                final outerScale = _outerBreathingAnimation.value;
                final midScale = _midBreathingAnimation.value;
                final coreScale = _coreBreathingAnimation.value;
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    // Outer glow rings
                    Container(
                      width: 120 * outerScale,
                      height: 120 * outerScale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.lavenderAccent.withValues(alpha: 0.08),
                        border: Border.all(
                          color: AppColors.lavenderAccent.withValues(
                            alpha: 0.2 * (2.0 - outerScale),
                          ),
                          width: 1,
                        ),
                      ),
                    ),
                    Container(
                      width: 100 * midScale,
                      height: 100 * midScale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.lavenderAccent.withValues(alpha: 0.2),
                      ),
                    ),
                    // Core bubble
                    Container(
                      width: 82 * coreScale,
                      height: 82 * coreScale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: AppColors.lavenderAccent,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.lavenderAccent.withValues(alpha: 0.5),
                            blurRadius: 18 * coreScale,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          _breathingStatus.toUpperCase(),
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 13 * coreScale,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                            color: const Color(0xFF1E201E),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 36),
          // Custom stretch time presets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeOption('4s Pace', 4, isDark, textMuted),
              _buildTimeOption('6s Deep Pace', 6, isDark, textMuted),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOption(
    String label,
    int seconds,
    bool isDark,
    Color textMuted,
  ) {
    final isSelected = _selectedPaceSeconds == seconds;

    return GestureDetector(
      onTap: () => _changePace(seconds),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.limeAccent
              : (isDark ? const Color(0xFF22252A) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? AppColors.limeAccent : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected
                ? const Color(0xFF1E201E)
                : textMuted,
          ),
        ),
      ),
    );
  }

  Widget _buildPosesSection(
    bool isDark,
    Color cardBg,
    Color borderCol,
    Color textPrimary,
    Color textMuted,
  ) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderCol, width: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Stretch Routine',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF22252A) : const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${_stretchPoses.length} Poses',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: textMuted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          ..._stretchPoses.asMap().entries.map((entry) {
            final idx = entry.key;
            final pose = entry.value;
            final isCompleted = pose['completed'] == true;

            return TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: Duration(milliseconds: 300 + (idx * 100)),
              curve: Curves.easeOutQuint,
              builder: (context, val, child) {
                return Opacity(
                  opacity: AppAnimations.clampOpacity(val),
                  child: Transform.translate(
                    offset: Offset(0, 20 * (1.0 - val)),
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onTap: () => _togglePose(idx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? (isDark
                              ? const Color(0xFF1E241E)
                              : const Color(0xFFF4F9F2))
                        : (isDark
                              ? const Color(0xFF1C1E22)
                              : const Color(0xFFF9FAFB)),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isCompleted
                          ? AppColors.limeAccent.withValues(alpha: 0.4)
                          : borderCol,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildPoseCheckbox(isCompleted, isDark),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pose['title'] as String,
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                decoration: isCompleted
                                    ? TextDecoration.lineThrough
                                    : null,
                                color: isCompleted
                                    ? textMuted.withValues(alpha: 0.6)
                                    : textPrimary,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pose['duration'] as String,
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 12,
                                color: textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isCompleted
                            ? Icons.check_circle_rounded
                            : Icons.play_circle_fill_rounded,
                        color: isCompleted
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.white70 : AppColors.obsidianBlack),
                        size: 24,
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
}

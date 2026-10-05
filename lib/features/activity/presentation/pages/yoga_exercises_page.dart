import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitrak/core/animations/app_animations.dart';
import 'package:habitrak/core/animations/staggered_entrance.dart';
import 'package:habitrak/features/habit/domain/entities/habit.dart';
import 'package:habitrak/features/habit/presentation/bloc/habit_bloc.dart';
import '../../data/repositories/activity_repository.dart';

class YogaExercisesPage extends StatefulWidget {
  const YogaExercisesPage({super.key});

  @override
  State<YogaExercisesPage> createState() => _YogaExercisesPageState();
}

class _YogaExercisesPageState extends State<YogaExercisesPage> with SingleTickerProviderStateMixin {
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
        HapticFeedback.selectionClick();
        _breathingController.reverse();
      } else if (status == AnimationStatus.dismissed) {
        setState(() {
          _breathingStatus = 'Inhale';
        });
        HapticFeedback.selectionClick();
        _breathingController.forward();
      }
    });

    _breathingController.forward();
  }

  void _changePace(int seconds) {
    if (_selectedPaceSeconds == seconds) return;
    HapticFeedback.lightImpact();
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

  Widget _buildPoseCheckbox(bool isCompleted, Color primaryColor, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? primaryColor : Colors.transparent,
        border: Border.all(
          color: isCompleted ? primaryColor : (isDark ? const Color(0xff424842) : const Color(0xffa4a097)),
          width: 2,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: isCompleted
            ? const Icon(
                Icons.check,
                key: ValueKey('check'),
                size: 14,
                color: Colors.white,
              )
            : const SizedBox(key: ValueKey('empty')),
      ),
    );
  }

  void _togglePose(int index) {
    final newStatus = !_stretchPoses[index]['completed'];
    if (newStatus) {
      HapticFeedback.mediumImpact();
    } else {
      HapticFeedback.lightImpact();
    }
    setState(() {
      _stretchPoses[index]['completed'] = newStatus;
    });
  }

  void _finishRoutine() {
    HapticFeedback.heavyImpact();
    final completedCount = _stretchPoses.where((p) => p['completed'] == true).length;
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 8),
            Text('Yoga routine completed! ($durationMinutes mins, $posesCount poses)'),
          ],
        ),
        backgroundColor: primaryColor,
      ),
    );

    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e);
    final cardBg = isDark ? const Color(0xff1e201e) : const Color(0xffffffff);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Yoga & Exercises',
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
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            StaggeredEntrance(index: 0, child: _buildBreathingSection(isDark, primaryColor, cardBg)),
            const SizedBox(height: 28),
            StaggeredEntrance(index: 1, child: _buildPosesSection(isDark, primaryColor, cardBg)),
            const SizedBox(height: 24),
            StaggeredEntrance(
              index: 2,
              child: ElevatedButton.icon(
                onPressed: _finishRoutine,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: isDark ? const Color(0xff1c3622) : Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 2,
                ),
                icon: const Icon(Icons.check_circle_outline, size: 22),
                label: const Text(
                  'Finish Routine',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildBreathingSection(bool isDark, Color primaryColor, Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xff424842).withValues(alpha: 0.1) : const Color(0xffdbdad7).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Breathing Guide',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Inhale as the circle expands, exhale as it contracts',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 12,
              color: isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.6) : const Color(0xff615e56).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 40),
          // Interactive glowing expansion bubble
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
                        color: primaryColor.withValues(alpha: 0.04),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.1 * (2.0 - outerScale)),
                          width: 1,
                        ),
                      ),
                    ),
                    Container(
                      width: 100 * midScale,
                      height: 100 * midScale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withValues(alpha: 0.08),
                      ),
                    ),
                    // Core bubble
                    Container(
                      width: 80 * coreScale,
                      height: 80 * coreScale,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: RadialGradient(
                          colors: [
                            primaryColor.withValues(alpha: 0.8),
                            primaryColor,
                          ],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.4),
                            blurRadius: 15 * coreScale,
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
                            fontWeight: FontWeight.bold,
                            letterSpacing: 1.0,
                            color: isDark ? const Color(0xff1c3622) : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
          const SizedBox(height: 40),
          // Custom stretch time presets
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildTimeOption('4s Pace', 4, isDark, primaryColor),
              _buildTimeOption('6s Deep Pace', 6, isDark, primaryColor),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTimeOption(String label, int seconds, bool isDark, Color primaryColor) {
    final isSelected = _selectedPaceSeconds == seconds;

    return GestureDetector(
      onTap: () => _changePace(seconds),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? primaryColor.withValues(alpha: 0.2)
              : (isDark ? const Color(0xff1a1c1a) : const Color(0xfff2f1ee)),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? primaryColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isSelected ? primaryColor : (isDark ? const Color(0xffc2c8c0) : const Color(0xff615e56)),
          ),
        ),
      ),
    );
  }

  Widget _buildPosesSection(bool isDark, Color primaryColor, Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xff424842).withValues(alpha: 0.1) : const Color(0xffdbdad7).withValues(alpha: 0.4),
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
                'Stretch Routine',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              Text(
                '${_stretchPoses.length} Poses',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 12,
                  color: isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.5) : const Color(0xff615e56).withValues(alpha: 0.5),
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
              duration: Duration(milliseconds: 400 + (idx * 150)),
              curve: Curves.easeOutQuint,
              builder: (context, val, child) {
                return Opacity(
                  opacity: AppAnimations.clampOpacity(val),
                  child: Transform.translate(
                    offset: Offset(0, 30 * (1.0 - val)),
                    child: child,
                  ),
                );
              },
              child: GestureDetector(
                onTap: () => _togglePose(idx),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? (isDark ? const Color(0xff1a1c1a).withValues(alpha: 0.4) : const Color(0xfff2f1ee).withValues(alpha: 0.6))
                        : (isDark ? const Color(0xff1a1c1a) : const Color(0xfff2f1ee)),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isCompleted
                          ? primaryColor.withValues(alpha: 0.2)
                          : Colors.transparent,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      _buildPoseCheckbox(isCompleted, primaryColor, isDark),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pose['title'] as String,
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 15,
                                fontWeight: FontWeight.bold,
                                decoration: isCompleted ? TextDecoration.lineThrough : null,
                                color: isCompleted
                                    ? (isDark ? Colors.white30 : Colors.black38)
                                    : (isDark ? Colors.white : Colors.black),
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              pose['duration'] as String,
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 12,
                                color: isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.5) : const Color(0xff615e56).withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(
                        isCompleted ? Icons.check_circle : Icons.play_circle_fill_rounded,
                        color: primaryColor.withValues(alpha: 0.7),
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

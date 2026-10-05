import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitrak/core/animations/app_animations.dart';
import 'package:habitrak/core/animations/app_page_route.dart';
import 'package:habitrak/core/animations/pressable_scale.dart';
import 'package:habitrak/core/animations/staggered_entrance.dart';
import '../bloc/habit_bloc.dart';
import 'package:habitrak/features/habit/domain/entities/habit.dart';
import 'library_page.dart';
import '../../../activity/presentation/pages/walk_tracker_page.dart';
import '../../../activity/presentation/pages/yoga_exercises_page.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _ambientController;
  late Animation<double> _progressAnimation;
  double _lastPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _ambientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);

    final habitState = context.read<HabitBloc>().state;
    if (habitState is HabitLoaded) {
      _lastPercentage = habitState.completionPercentage;
      _progressAnimation = Tween<double>(
        begin: 0.0,
        end: _lastPercentage / 100.0,
      ).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
      );
      _progressController.forward();
    } else {
      _progressAnimation = Tween<double>(begin: 0.0, end: 0.0).animate(
        CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
      );
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _animateProgress(double targetPercentage) {
    _progressAnimation = Tween<double>(
      begin: _lastPercentage / 100.0,
      end: targetPercentage / 100.0,
    ).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeOutCubic),
    );
    _lastPercentage = targetPercentage;
    _progressController.forward(from: 0.0);
  }

  void _showCelebrationOverlay() {
    HapticFeedback.vibrate();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e);
    
    showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.4),
      builder: (context) {
        return TweenAnimationBuilder<double>(
          duration: AppAnimations.slow,
          curve: AppAnimations.bounce,
          tween: Tween<double>(begin: 0.0, end: 1.0),
          builder: (context, val, child) {
            return Transform.scale(
              scale: 0.85 + (val * 0.15),
              child: Opacity(
                opacity: AppAnimations.clampOpacity(val),
                child: Transform.translate(
                  offset: Offset(0, (1 - val) * 30),
                  child: AlertDialog(
                  backgroundColor: isDark ? const Color(0xff1e201e) : const Color(0xffffffff),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                  title: Column(
                    children: [
                      Icon(Icons.stars_rounded, color: primaryColor, size: 54),
                      const SizedBox(height: 12),
                      const Text(
                        '100% Completed!',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Brilliant focus! You\'ve completed all of your daily intentions for today.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 14,
                          color: isDark ? const Color(0xffc2c8c0) : const Color(0xff615e56),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: isDark ? const Color(0xff1c3622) : Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          child: const Text(
                            'Keep it up!',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Habitrak',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e),
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              HapticFeedback.mediumImpact();
              // Trigger a reset of habits to default as a settings shortcut
              context.read<HabitBloc>().add(ResetHabitsEvent());
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Habits reset to Stitch defaults!'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: BlocConsumer<HabitBloc, HabitState>(
        listener: (context, state) {
          if (state is HabitLoaded) {
            final targetPercentage = state.completionPercentage;
            final wasAlreadyLoaded = _lastPercentage > 0.0;
            final prevPercentage = _lastPercentage;
            _animateProgress(targetPercentage);
            if (targetPercentage >= 100.0 && prevPercentage < 100.0 && wasAlreadyLoaded) {
              _showCelebrationOverlay();
            }
          }
        },
        builder: (context, state) {
          if (state is HabitInitial) {
            context.read<HabitBloc>().add(LoadHabitsEvent());
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HabitLoading) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state is HabitLoaded) {
            return SingleChildScrollView(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 10),
                  StaggeredEntrance(
                    index: 0,
                    child: Center(
                      child: _buildProgressRing(state.completionPercentage),
                    ),
                  ),
                  const SizedBox(height: 24),
                  StaggeredEntrance(
                    index: 1,
                    child: _buildDateSlider(state.activeDate),
                  ),
                  const SizedBox(height: 28),
                  StaggeredEntrance(
                    index: 2,
                    child: _buildHabitList(state.habits),
                  ),
                  const SizedBox(height: 28),
                  StaggeredEntrance(
                    index: 3,
                    child: _buildQuoteBanner(isDark),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            );
          }
          if (state is HabitError) {
            return Center(child: Text(state.message));
          }
          return const SizedBox();
        },
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 80),
        child: TweenAnimationBuilder<double>(
          tween: Tween(begin: 0, end: 1),
          duration: const Duration(milliseconds: 800),
          curve: AppAnimations.bounce,
          builder: (context, value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: AppAnimations.clampOpacity(value),
                child: child,
              ),
            );
          },
          child: FloatingActionButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.of(context).push(
                AppPageRoute(page: const YogaExercisesPage()),
              );
            },
            backgroundColor: isDark ? const Color(0xff334d38) : const Color(0xffcceace),
            foregroundColor: isDark ? const Color(0xffe2e3df) : const Color(0xff1c3622),
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: const Icon(Icons.self_improvement, size: 28),
          ),
        ),
      ),
    );
  }

  Widget _buildProgressRing(double percentage) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e);
    final trackColor = primaryColor.withValues(alpha: 0.2);

    return AnimatedBuilder(
      animation: Listenable.merge([_progressController, _ambientController]),
      builder: (context, child) {
        final scale = 0.98 + (_ambientController.value * 0.04);
        return Transform.scale(
          scale: scale,
          child: Container(
            width: 190,
            height: 190,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.transparent,
              boxShadow: [
                BoxShadow(
                  color: primaryColor.withValues(alpha: isDark ? 0.03 : 0.06),
                  blurRadius: 25 * scale,
                  spreadRadius: 2 * scale,
                )
              ]
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: const Size(190, 190),
                  painter: CircularProgressPainter(
                    progress: _progressAnimation.value,
                    primaryColor: primaryColor,
                    trackColor: trackColor,
                    strokeWidth: 18,
                  ),
                ),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AnimatedScale(
                      scale: percentage == 100.0 ? 1.1 : 1.0,
                      duration: const Duration(milliseconds: 500),
                      curve: Curves.elasticOut,
                      child: Text(
                        '${(percentage).round()}%',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 44,
                          fontWeight: FontWeight.w600,
                          color: primaryColor,
                          letterSpacing: -1,
                        ),
                      ),
                    ),
                    Text(
                      'DAILY FOCUS',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.5,
                        color: isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.5) : const Color(0xff615e56).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSlider(DateTime activeDate) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];

    // Generate 5 days centered on today
    final days = List.generate(5, (index) {
      final date = today.add(Duration(days: index - 2));
      final isActive = date.year == activeDate.year &&
          date.month == activeDate.month &&
          date.day == activeDate.day;
      return {
        'date': date,
        'day': weekdays[date.weekday - 1],
        'num': date.day.toString().padLeft(2, '0'),
        'isActive': isActive,
      };
    });

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: days.map((d) {
        final isActive = d['isActive'] == true;
        final date = d['date'] as DateTime;
        
        return Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              HapticFeedback.selectionClick();
              context.read<HabitBloc>().add(ChangeActiveDateEvent(date));
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? (isDark ? const Color(0xff3f4941).withValues(alpha: 0.3) : const Color(0xffcee7f0).withValues(alpha: 0.3))
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive 
                      ? (isDark ? const Color(0xffb0ceb2).withValues(alpha: 0.2) : const Color(0xff8ba88e).withValues(alpha: 0.2))
                      : Colors.transparent,
                  width: 1,
                ),
              ),
              child: Column(
                children: [
                  Text(
                    d['day'] as String,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      color: isActive 
                          ? (isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e))
                          : (isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.4) : const Color(0xff615e56).withValues(alpha: 0.4)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    d['num'] as String,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 18,
                      fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                      color: isActive 
                          ? (isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e))
                          : (isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.7) : const Color(0xff615e56).withValues(alpha: 0.7)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHabitList(List<Habit> habits) {
    return Column(
      children: [
        ...habits.asMap().entries.map((entry) {
          final idx = entry.key;
          final h = entry.value;
          return StaggeredEntrance(
            index: idx + 3,
            child: _buildHabitCard(h),
          );
        }),
        const SizedBox(height: 6),
        // Add Daily Intention Dashed Button
        PressableScale(
          onTap: () {
            HapticFeedback.lightImpact();
            Navigator.push(
              context,
              AppSlideRoute(page: const LibraryPage()),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Theme.of(context).brightness == Brightness.dark
                    ? const Color(0xff424842).withValues(alpha: 0.4)
                    : const Color(0xffdbdad7).withValues(alpha: 0.6),
                width: 1.5,
                style: BorderStyle.solid, // dashed border simulated with styled solid border in UI
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add_circle_outline,
                  color: Theme.of(context).brightness == Brightness.dark 
                      ? const Color(0xffc2c8c0).withValues(alpha: 0.6) 
                      : const Color(0xff615e56).withValues(alpha: 0.6),
                  size: 22,
                ),
                const SizedBox(width: 8),
                Text(
                  'Add Daily Intention',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).brightness == Brightness.dark 
                        ? const Color(0xffc2c8c0).withValues(alpha: 0.8) 
                        : const Color(0xff615e56).withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHabitCard(Habit habit) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Design matching spec
    if (habit.id == '2') {
      // Interactive slider for Water Habit
      final isWaterCompleted = habit.currentProgress >= habit.targetProgress;
      final completedBg = isDark ? const Color(0xff1f303a) : const Color(0xffedf6fa);
      final normalBg = isDark ? const Color(0xff1e201e) : const Color(0xffffffff);
      final waterBorder = isWaterCompleted
          ? (isDark ? const Color(0xffb2cad3).withValues(alpha: 0.2) : const Color(0xff8ba88e).withValues(alpha: 0.2))
          : (isDark ? const Color(0xff424842).withValues(alpha: 0.1) : const Color(0xffdbdad7).withValues(alpha: 0.4));

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isWaterCompleted ? completedBg : normalBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: waterBorder,
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.1 : 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  habit.title,
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xffe2e3df) : const Color(0xff2f312f),
                  ),
                ),
                AnimatedScale(
                  scale: isWaterCompleted ? 1.05 : 1.0,
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.elasticOut,
                  child: Text(
                    '${habit.currentProgress.toStringAsFixed(1)}L / ${habit.targetProgress.round()}L',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isWaterCompleted 
                          ? (isDark ? const Color(0xffb2cad3) : const Color(0xff5a93ab))
                          : (isDark ? const Color(0xffc2c8c0) : const Color(0xff615e56)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: isWaterCompleted
                    ? (isDark ? const Color(0xffb2cad3) : const Color(0xff5a93ab))
                    : (isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e)),
                inactiveTrackColor: isDark ? const Color(0xff1a1c1a) : const Color(0xfff2f1ee),
                thumbColor: isWaterCompleted
                    ? (isDark ? const Color(0xffb2cad3) : const Color(0xff5a93ab))
                    : (isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e)),
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: Slider(
                value: habit.currentProgress,
                min: 0.0,
                max: habit.targetProgress,
                onChanged: (val) {
                  if (val == habit.targetProgress && habit.currentProgress < habit.targetProgress) {
                    HapticFeedback.mediumImpact();
                  } else if ((val * 10).round() % 2 == 0) {
                    HapticFeedback.selectionClick();
                  }
                  context.read<HabitBloc>().add(UpdateHabitProgressEvent(habit.id, val));
                },
              ),
            ),
          ],
        ),
      );
    }

    if (habit.title == 'No Screen Time') {
      // Habit styled with "LATER" tag
      return Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff1e201e).withValues(alpha: 0.8) : const Color(0xffffffff).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xff424842).withValues(alpha: 0.1) : const Color(0xffdbdad7).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  habit.title,
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xffe2e3df) : const Color(0xff2f312f),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scheduled for ${habit.scheduledTime ?? "9:00 PM"}',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.6) : const Color(0xff615e56).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff333533) : const Color(0xffefeeeb),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'LATER',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark ? const Color(0xffc2c8c0) : const Color(0xff615e56),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Standard items with active checking/toggling
    final completedColor = isDark ? const Color(0xff223a26) : const Color(0xffedf7ee);
    final normalColor = isDark ? const Color(0xff1e201e) : const Color(0xffffffff);
    final borderColor = habit.isCompleted
        ? (isDark ? const Color(0xffb0ceb2).withValues(alpha: 0.2) : const Color(0xff8ba88e).withValues(alpha: 0.2))
        : (isDark ? const Color(0xff424842).withValues(alpha: 0.1) : const Color(0xffdbdad7).withValues(alpha: 0.4));

    return PressableScale(
      onTap: () {
        final title = habit.title.toLowerCase();
        if (habit.id == '3' || title.contains('walk')) {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            AppPageRoute(page: const WalkTrackerPage()),
          );
        } else if (title.contains('yoga') || title.contains('stretch') || title.contains('meditat') || title.contains('breath')) {
          HapticFeedback.lightImpact();
          Navigator.of(context).push(
            AppPageRoute(page: const YogaExercisesPage()),
          );
        } else {
          if (habit.isCompleted) {
            HapticFeedback.lightImpact();
          } else {
            HapticFeedback.mediumImpact();
          }
          context.read<HabitBloc>().add(ToggleHabitEvent(habit.id));
        }
      },
      child: AnimatedContainer(
      duration: AppAnimations.fast,
      curve: AppAnimations.smooth,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: habit.isCompleted ? completedColor : normalColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: habit.isCompleted ? 0.0 : (isDark ? 0.1 : 0.03)),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    decoration: habit.isCompleted ? TextDecoration.lineThrough : TextDecoration.none,
                    color: habit.isCompleted
                        ? (isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.5) : const Color(0xff615e56).withValues(alpha: 0.5))
                        : (isDark ? const Color(0xffe2e3df) : const Color(0xff2f312f)),
                  ),
                  child: Text(habit.title),
                ),
                const SizedBox(height: 4),
                AnimatedDefaultTextStyle(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: habit.isCompleted
                        ? (isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e))
                        : (isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.6) : const Color(0xff615e56).withValues(alpha: 0.6)),
                  ),
                  child: Text(
                    habit.isCompleted
                        ? 'Completed at ${habit.completedAt ?? "7:15 AM"}'
                        : 'Current streak: ${habit.streak} days',
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () {
              if (habit.isCompleted) {
                HapticFeedback.lightImpact();
              } else {
                HapticFeedback.mediumImpact();
              }
              context.read<HabitBloc>().add(ToggleHabitEvent(habit.id));
            },
            child: AnimatedScale(
              scale: habit.isCompleted ? 1.05 : 1.0,
              duration: const Duration(milliseconds: 150),
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 250),
                transitionBuilder: (child, animation) {
                  return ScaleTransition(scale: animation, child: child);
                },
                child: habit.isCompleted
                    ? Icon(
                        Icons.check_circle_rounded,
                        key: ValueKey('completed_${habit.id}'),
                        color: isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e),
                        size: 32,
                      )
                    : Icon(
                        Icons.radio_button_unchecked,
                        key: ValueKey('uncompleted_${habit.id}'),
                        color: isDark ? const Color(0xff424842) : const Color(0xffa4a097),
                        size: 32,
                      ),
              ),
            ),
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildQuoteBanner(bool isDark) {
    final primaryColor = isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e);
    
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 1200),
      curve: Curves.easeInOut,
      builder: (context, breathe, child) {
        return Transform.scale(
          scale: 1 + (breathe * 0.01),
          child: child,
        );
      },
      child: Container(
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: isDark ? const Color(0xff1a1c1a) : const Color(0xffefeeeb),
        image: const DecorationImage(
          image: NetworkImage(
            'https://images.unsplash.com/photo-1511497584788-876760111969?q=80&w=1000&auto=format&fit=crop',
          ),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black45,
            BlendMode.darken,
          ),
        ),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '"Nature does not hurry, yet everything is accomplished."',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 20,
              fontWeight: FontWeight.w400,
              fontStyle: FontStyle.italic,
              color: const Color(0xfffaf9f6),
              height: 1.4,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  offset: const Offset(1, 1),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Text(
            '— LAO TZU',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: primaryColor,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.6),
                  offset: const Offset(1, 1),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ],
      ),
      ),
    );
  }
}

class CircularProgressPainter extends CustomPainter {
  final double progress;
  final Color primaryColor;
  final Color trackColor;
  final double strokeWidth;

  CircularProgressPainter({
    required this.progress,
    required this.primaryColor,
    required this.trackColor,
    required this.strokeWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width / 2, size.height / 2) - strokeWidth / 2;

    // Track
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, trackPaint);

    if (progress <= 0.0) return;

    // Gradient to give a slightly 3D/Apple Health feel
    final gradient = SweepGradient(
      colors: [
        primaryColor.withValues(alpha: 0.5),
        primaryColor,
      ],
      transform: const GradientRotation(-pi / 2),
    );

    // Progress Arc
    final progressPaint = Paint()
      ..shader = gradient.createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeWidth = strokeWidth;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi / 2,
      2 * pi * progress,
      false,
      progressPaint,
    );

    // Draw the shadow for the overlapping head
    final headAngle = -pi / 2 + 2 * pi * progress;
    final headPoint = Offset(
      center.dx + radius * cos(headAngle),
      center.dy + radius * sin(headAngle),
    );

    // Shadow underneath the head
    final shadowPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 5.0);
    
    // Offset shadow slightly to indicate direction/overlap
    canvas.drawCircle(
      headPoint + Offset(cos(headAngle) * 3, sin(headAngle) * 3),
      strokeWidth / 2,
      shadowPaint,
    );

    // Draw the head cap to cover the shadow's bleed onto the arc
    final headPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(headPoint, strokeWidth / 2, headPaint);

    // Draw a small arrow at the start (12 o'clock)
    final startPoint = Offset(center.dx, center.dy - radius);
    final arrowPaint = Paint()
      ..color = trackColor.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;
    
    final path = Path();
    final arrowSize = strokeWidth * 0.35;
    path.moveTo(startPoint.dx - arrowSize / 2, startPoint.dy - arrowSize / 2);
    path.lineTo(startPoint.dx + arrowSize / 2, startPoint.dy);
    path.lineTo(startPoint.dx - arrowSize / 2, startPoint.dy + arrowSize / 2);
    path.close();
    
    canvas.drawPath(path, arrowPaint);
  }

  @override
  bool shouldRepaint(covariant CircularProgressPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.trackColor != trackColor ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

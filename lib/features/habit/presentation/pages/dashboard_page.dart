import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:haptic_flow/haptic_flow.dart';
import 'package:habitrak/core/animations/app_animations.dart';
import 'package:habitrak/core/animations/app_page_route.dart';
import 'package:habitrak/core/animations/pressable_scale.dart';
import 'package:habitrak/core/animations/staggered_entrance.dart';
import '../bloc/habit_bloc.dart';
import 'package:habitrak/core/animations/animated_modal_sheet.dart';
import 'package:habitrak/features/habit/domain/entities/habit.dart';
import 'library_page.dart';
import '../../../activity/presentation/pages/walk_tracker_page.dart';
import '../../../activity/presentation/pages/yoga_exercises_page.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../music/presentation/widgets/soulful_music_card.dart';
import '../../../health_news/presentation/widgets/health_news_section.dart';
import '../../../mindfulness/data/repositories/soulfulness_repository.dart';
import '../../../mindfulness/presentation/widgets/breathwork_modal.dart';
import '../../../mindfulness/presentation/widgets/meditation_timer_modal.dart';
import '../../../mindfulness/presentation/widgets/thought_release_modal.dart';
import '../widgets/bento/bento_header.dart';
import '../widgets/bento/bento_energy_card.dart';
import '../widgets/bento/bento_metrics_cards.dart';
import '../widgets/bento/bento_wellness_card.dart';
import '../widgets/bento/bento_sleep_card.dart';
import '../widgets/bento/bento_ai_promo_card.dart';
import '../../../health/domain/models/daily_health_summary.dart';
import '../../../health/presentation/bloc/wearable_sync_bloc.dart';
import '../../../health/presentation/bloc/wearable_sync_state.dart';
import '../../../health/presentation/widgets/wearables_hub_modal.dart';
import '../../../auth/presentation/cubit/auth_cubit.dart';
import '../../../auth/presentation/cubit/auth_state.dart';
import '../../../profile/data/repositories/profile_repository.dart';
import '../../../profile/presentation/pages/profile_page.dart';
import '../../../activity/data/repositories/activity_repository.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _ambientController;
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
      _progressController.forward();
    }
  }

  @override
  void dispose() {
    _progressController.dispose();
    _ambientController.dispose();
    super.dispose();
  }

  void _animateProgress(double targetPercentage) {
    _lastPercentage = targetPercentage;
    _progressController.forward(from: 0.0);
  }

  void _showCelebrationOverlay() {
    HapticFlow.play(HapticPresets.sparkle);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppColors.limeAccent
        : AppColors.obsidianBlack;

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
                    backgroundColor: isDark
                        ? const Color(0xff1e201e)
                        : const Color(0xffffffff),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    title: Column(
                      children: [
                        Icon(
                          Icons.stars_rounded,
                          color: primaryColor,
                          size: 54,
                        ),
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
                            color: isDark
                                ? const Color(0xffc2c8c0)
                                : const Color(0xff615e56),
                          ),
                        ),
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: primaryColor,
                              foregroundColor: isDark
                                  ? const Color(0xff1c3622)
                                  : Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
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
      body: SafeArea(
        bottom: false,
        child: BlocConsumer<HabitBloc, HabitState>(
          listener: (context, state) {
            if (state is HabitLoaded) {
              final targetPercentage = state.completionPercentage;
              final wasAlreadyLoaded = _lastPercentage > 0.0;
              final prevPercentage = _lastPercentage;
              _animateProgress(targetPercentage);
              if (targetPercentage >= 100.0 &&
                  prevPercentage < 100.0 &&
                  wasAlreadyLoaded) {
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
                physics: const HapticScrollPhysics(
                  detentDistance: 140.0,
                  triggerAtEdges: true,
                ),
                padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120, top: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // 1. Bento Header: Avatar, Name, Health Overview, Search & Today Selector
                    Builder(
                      builder: (context) {
                        final profileRepo = context.watch<ProfileRepository>();
                        final authState = context.watch<AuthCubit>().state;
                        String userName = profileRepo.getUserName();
                        String userEmail = profileRepo.getUserEmail();
                        String? userPhotoUrl = profileRepo.getUserPhotoUrl();

                        if (authState is Authenticated) {
                          if (authState.user.displayName.isNotEmpty) {
                            userName = authState.user.displayName;
                          }
                          if (authState.user.email.isNotEmpty) {
                            userEmail = authState.user.email;
                          }
                          if (authState.user.photoUrl != null) {
                            userPhotoUrl = authState.user.photoUrl;
                          }
                        }

                        return BentoHeader(
                          userName: userName,
                          userEmail: userEmail,
                          userPhotoUrl: userPhotoUrl,
                          onProfileTap: () {
                            HapticFlow.selection();
                            Navigator.push(
                              context,
                              AppPageRoute(page: const ProfilePage()),
                            ).then((_) {
                              if (context.mounted) {
                                setState(() {});
                              }
                            });
                          },
                          onNotificationTap: () async {
                            HapticFlow.light();
                            await NotificationService().showTestStreakNotification(streak: 7);
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('🔔 Notification alert triggered!'),
                                  backgroundColor: AppColors.obsidianBlack,
                                  duration: Duration(seconds: 2),
                                ),
                              );
                            }
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 18),

                    // 2. Bento Grid with Live Wearable Health Data & Tap-to-Inspect
                    BlocBuilder<WearableSyncBloc, WearableSyncState>(
                      builder: (context, wearableState) {
                        DailyHealthSummary? summary;
                        if (wearableState is WearableSyncSuccess) {
                          summary = wearableState.currentSummary;
                        }

                        final activityRepo = context.read<ActivityRepository>();
                        final logs = activityRepo.getActivityLogs();
                        double loggedCalories = 0.0;
                        double loggedWalkCalories = 0.0;
                        for (final l in logs) {
                          final cal = (l['calories'] as num?)?.toDouble() ?? 0.0;
                          loggedCalories += cal;
                          if (l['type'] == 'walk') loggedWalkCalories += cal;
                        }

                        final totalCalories = (summary?.totalCalories != null && summary!.totalCalories > 0)
                            ? summary.totalCalories
                            : (loggedCalories > 0 ? loggedCalories : 0.0);
                        final activeCalories = (summary?.activeCalories != null && summary!.activeCalories > 0)
                            ? summary.activeCalories
                            : (loggedCalories > 0 ? loggedCalories * 0.7 : 0.0);
                        final walkCalories = (summary?.steps != null && summary!.steps > 0)
                            ? (summary.steps * 0.04)
                            : (loggedWalkCalories > 0 ? loggedWalkCalories : 0.0);
                        final workoutCalories = (activeCalories - walkCalories).clamp(0.0, activeCalories);

                        final hr = summary?.avgHeartRate?.round() ?? 0;
                        final restingHr = summary?.restingHeartRate?.round() ?? 0;
                        final distKm = (summary?.distanceKm != null && summary!.distanceKm > 0)
                            ? summary.distanceKm
                            : 0.0;
                        final activeMins = summary?.exerciseMinutes != null && summary!.exerciseMinutes > 0
                            ? summary.exerciseMinutes
                            : 0;
                        final sleepEff = summary?.sleepEfficiencyPercentage ?? 0;
                        final sleepDurStr = (summary?.sleepDurationMinutes != null && summary!.sleepDurationMinutes > 0)
                            ? '${summary.sleepDurationMinutes ~/ 60}h ${summary.sleepDurationMinutes % 60}m'
                            : '--';

                        // Dynamic Wellness Index calculation
                        final habitRatio = state.completionPercentage / 100.0;
                        final sleepRatio = sleepEff > 0 ? (sleepEff / 100.0) : 0.75;
                        final stepRatio = ((summary?.steps ?? 0) / 10000.0).clamp(0.0, 1.0);
                        final int wellnessScore = ((habitRatio * 50) + (sleepRatio * 30) + (stepRatio * 20)).round().clamp(10, 100);
                        final int scoreDelta = (state.completionPercentage > 0 ? 5 : 0) + ((summary?.steps ?? 0) > 5000 ? 5 : 0);

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            GestureDetector(
                              onTap: () {
                                HapticFlow.light();
                                WearablesHubModal.show(context);
                              },
                              child: StaggeredEntrance(
                                index: 1,
                                child: BentoEnergyCard(
                                  totalCalories: totalCalories,
                                  runningCalories: activeCalories,
                                  workoutCalories: workoutCalories,
                                  walkingCalories: walkCalories,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () {
                                HapticFlow.light();
                                WearablesHubModal.show(context);
                              },
                              child: StaggeredEntrance(
                                index: 2,
                                child: BentoMetricsCards(
                                  heartRate: hr,
                                  avgHeartRate: restingHr,
                                  distanceKm: distKm,
                                  activeMinutes: activeMins,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () {
                                HapticFlow.light();
                                WearablesHubModal.show(context);
                              },
                              child: StaggeredEntrance(
                                index: 3,
                                child: BentoWellnessCard(
                                  wellnessScore: wellnessScore,
                                  scoreDelta: scoreDelta,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            GestureDetector(
                              onTap: () {
                                HapticFlow.light();
                                WearablesHubModal.show(context);
                              },
                              child: StaggeredEntrance(
                                index: 4,
                                child: BentoSleepCard(
                                  sleepEfficiency: sleepEff,
                                  sleepDuration: sleepDurStr,
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                            StaggeredEntrance(
                              index: 5,
                              child: BentoAiPromoCard(
                                onActionTap: () {
                                  HapticFlow.medium();
                                  WearablesHubModal.show(context);
                                },
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    const SizedBox(height: 28),

                    // 7. Habits & Routines Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Daily Habits & Streaks',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                                color: isDark ? Colors.white : AppColors.obsidianBlack,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${state.habits.where((h) => h.isCompleted).length} of ${state.habits.length} habits completed today',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 12,
                                color: isDark ? const Color(0xFFA0A5AD) : const Color(0xFF7A7E85),
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.charcoalCard : Colors.white,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: isDark ? AppColors.charcoalBorder : const Color(0xFFE5E7EB),
                              width: 0.8,
                            ),
                          ),
                          child: Text(
                            '${state.completionPercentage.round()}% Done',
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              color: isDark ? AppColors.limeAccent : AppColors.obsidianBlack,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    StaggeredEntrance(
                      index: 6,
                      child: _buildDateSlider(state.activeDate),
                    ),
                    const SizedBox(height: 16),
                    StaggeredEntrance(
                      index: 7,
                      child: _buildHabitList(state.habits, state.activeDate),
                    ),
                    const SizedBox(height: 20),

                    // 8. Soulful Micro-Pause Card
                    StaggeredEntrance(
                      index: 8,
                      child: _buildSoulfulPauseCard(isDark, AppColors.limeAccentDark),
                    ),
                    const SizedBox(height: 20),
                    const StaggeredEntrance(index: 9, child: SoulfulMusicCard()),
                    const SizedBox(height: 24),
                    const StaggeredEntrance(index: 10, child: HealthNewsSection()),
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
      ),
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 112),
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
          child: FloatingActionButton.small(
            onPressed: () {
              HapticFlow.light();
              Navigator.of(
                context,
              ).push(AppPageRoute(page: const YogaExercisesPage()));
            },
            backgroundColor: const Color(0xFF16181A),
            foregroundColor: AppColors.limeAccent,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: const BorderSide(color: Color(0xFF2E3236), width: 0.8),
            ),
            child: const Icon(Icons.add_rounded, size: 22),
          ),
        ),
      ),
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
      final isActive =
          date.year == activeDate.year &&
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
              HapticFlow.selection();
              context.read<HabitBloc>().add(ChangeActiveDateEvent(date));
            },
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              decoration: BoxDecoration(
                color: isActive
                    ? (isDark ? AppColors.charcoalCard : Colors.white)
                    : (isDark ? const Color(0xFF1A1D20) : const Color(0xFFEBEDF0)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isActive
                      ? AppColors.limeAccentDark
                      : (isDark ? const Color(0xFF282B30) : const Color(0xFFE2E4E8)),
                  width: isActive ? 1.5 : 0.8,
                ),
                boxShadow: isActive
                    ? [
                        BoxShadow(
                          color: AppColors.limeAccent.withValues(alpha: 0.2),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                children: [
                  Text(
                    d['day'] as String,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 12,
                      fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                      color: isActive
                          ? (isDark ? AppColors.limeAccent : AppColors.obsidianBlack)
                          : (isDark
                                ? const Color(0xFFA0A5AD).withValues(alpha: 0.6)
                                : const Color(0xFF7A7E85).withValues(alpha: 0.8)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    d['num'] as String,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 18,
                      fontWeight: isActive ? FontWeight.w800 : FontWeight.w500,
                      color: isActive
                          ? (isDark ? Colors.white : AppColors.obsidianBlack)
                          : (isDark
                                ? const Color(0xFFA0A5AD)
                                : const Color(0xFF7A7E85)),
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

  Widget _buildHabitList(List<Habit> habits, [DateTime? activeDate]) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = activeDate != null
        ? DateTime(activeDate.year, activeDate.month, activeDate.day)
        : today;
    final isToday = target.isAtSameMomentAs(today);
    final isPast = target.isBefore(today);

    return Column(
      children: [
        if (!isToday) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E2024) : const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color:
                    (isDark ? AppColors.limeAccent : AppColors.obsidianBlack)
                        .withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(
                      isPast
                          ? Icons.history_rounded
                          : Icons.event_available_rounded,
                      size: 18,
                      color: isDark
                          ? AppColors.limeAccent
                          : AppColors.obsidianBlack,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isPast
                          ? 'Viewing Historical Record'
                          : 'Viewing Future Plan',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : AppColors.obsidianBlack,
                      ),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: () {
                    HapticFlow.light();
                    context.read<HabitBloc>().add(ChangeActiveDateEvent(today));
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color:
                          (isDark
                                  ? AppColors.limeAccent
                                  : AppColors.obsidianBlack)
                              .withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Back to Today',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark
                            ? AppColors.limeAccent
                            : AppColors.obsidianBlack,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        ...habits.asMap().entries.map((entry) {
          final idx = entry.key;
          final h = entry.value;
          return StaggeredEntrance(index: idx + 3, child: _buildHabitCard(h));
        }),
        const SizedBox(height: 6),
        // Add Daily Intention Dashed Button
        PressableScale(
          onTap: () {
            HapticFlow.light();
            Navigator.push(context, AppSlideRoute(page: const LibraryPage()));
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
                style: BorderStyle
                    .solid, // dashed border simulated with styled solid border in UI
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
      final completedBg = isDark
          ? const Color(0xff1f303a)
          : const Color(0xffedf6fa);
      final normalBg = isDark
          ? const Color(0xff1e201e)
          : const Color(0xffffffff);
      final waterBorder = isWaterCompleted
          ? (isDark
                ? const Color(0xffb2cad3).withValues(alpha: 0.2)
                : AppColors.obsidianBlack.withValues(alpha: 0.1))
          : (isDark
                ? const Color(0xff424842).withValues(alpha: 0.1)
                : const Color(0xffdbdad7).withValues(alpha: 0.4));

      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isWaterCompleted ? completedBg : normalBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: waterBorder, width: 1),
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
                    color: isDark
                        ? const Color(0xffe2e3df)
                        : const Color(0xff2f312f),
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
                          ? (isDark
                                ? const Color(0xffb2cad3)
                                : const Color(0xff5a93ab))
                          : (isDark
                                ? const Color(0xffc2c8c0)
                                : const Color(0xff615e56)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: isWaterCompleted
                    ? (isDark
                          ? const Color(0xffb2cad3)
                          : const Color(0xff5a93ab))
                    : (isDark
                          ? AppColors.limeAccent
                          : AppColors.obsidianBlack),
                inactiveTrackColor: isDark
                    ? const Color(0xff1a1c1a)
                    : const Color(0xfff2f1ee),
                thumbColor: isWaterCompleted
                    ? (isDark
                          ? const Color(0xffb2cad3)
                          : const Color(0xff5a93ab))
                    : (isDark
                          ? AppColors.limeAccent
                          : AppColors.obsidianBlack),
                trackHeight: 6,
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8),
              ),
              child: HapticSlider(
                value: habit.currentProgress,
                min: 0.0,
                max: habit.targetProgress,
                detentInterval: habit.targetProgress > 1.0 ? 1.0 : 0.2,
                enableEdgeFeedback: true,
                onChanged: (val) {
                  if (val == habit.targetProgress &&
                      habit.currentProgress < habit.targetProgress) {
                    HapticFlow.play(HapticPresets.successSnap);
                  }
                  context.read<HabitBloc>().add(
                    UpdateHabitProgressEvent(habit.id, val),
                  );
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
          color: isDark
              ? const Color(0xff1e201e).withValues(alpha: 0.8)
              : const Color(0xffffffff).withValues(alpha: 0.8),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xff424842).withValues(alpha: 0.1)
                : const Color(0xffdbdad7).withValues(alpha: 0.4),
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
                    color: isDark
                        ? const Color(0xffe2e3df)
                        : const Color(0xff2f312f),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Scheduled for ${habit.scheduledTime ?? "9:00 PM"}',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isDark
                        ? const Color(0xffc2c8c0).withValues(alpha: 0.6)
                        : const Color(0xff615e56).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xff333533)
                    : const Color(0xffefeeeb),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'LATER',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark
                      ? const Color(0xffc2c8c0)
                      : const Color(0xff615e56),
                ),
              ),
            ),
          ],
        ),
      );
    }

    // Standard items with active checking/toggling
    final completedColor = isDark
        ? const Color(0xFF202717)
        : const Color(0xFFF7FCEB);
    final normalColor = isDark
        ? AppColors.charcoalCard
        : Colors.white;
    final borderColor = habit.isCompleted
        ? AppColors.limeAccentDark.withValues(alpha: 0.6)
        : (isDark
              ? AppColors.charcoalBorder
              : const Color(0xFFE8E9EC));

    return PressableScale(
      onTap: () {
        final title = habit.title.toLowerCase();
        if (habit.id == '3' || title.contains('walk')) {
          HapticFlow.light();
          Navigator.of(
            context,
          ).push(AppPageRoute(page: const WalkTrackerPage()));
        } else if (title.contains('yoga') ||
            title.contains('stretch') ||
            title.contains('meditat') ||
            title.contains('breath')) {
          HapticFlow.light();
          Navigator.of(
            context,
          ).push(AppPageRoute(page: const YogaExercisesPage()));
        } else {
          if (habit.isCompleted) {
            HapticFlow.light();
          } else {
            HapticFlow.play(HapticPresets.successSnap);
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
          border: Border.all(color: borderColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(
                alpha: habit.isCompleted ? 0.0 : (isDark ? 0.1 : 0.03),
              ),
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
                      decoration: habit.isCompleted
                          ? TextDecoration.lineThrough
                          : TextDecoration.none,
                      color: habit.isCompleted
                          ? (isDark
                                ? const Color(0xffc2c8c0).withValues(alpha: 0.5)
                                : const Color(
                                    0xff615e56,
                                  ).withValues(alpha: 0.5))
                          : (isDark
                                ? const Color(0xffe2e3df)
                                : const Color(0xff2f312f)),
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
                          ? (isDark
                                ? AppColors.limeAccent
                                : const Color(0xFF10B981))
                          : (isDark
                                ? const Color(0xffc2c8c0).withValues(alpha: 0.6)
                                : const Color(
                                    0xff615e56,
                                  ).withValues(alpha: 0.6)),
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
                  HapticFlow.light();
                } else {
                  HapticFlow.play(HapticPresets.successSnap);
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
                      ? Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            color: AppColors.limeAccent,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check_rounded,
                            key: ValueKey('completed_check'),
                            color: AppColors.obsidianBlack,
                            size: 20,
                          ),
                        )
                      : Container(
                          width: 30,
                          height: 30,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isDark ? const Color(0xFF42464D) : const Color(0xFFCED1D7),
                              width: 1.8,
                            ),
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSoulfulPauseCard(bool isDark, Color primaryColor) {
    final soulRepo = context.read<SoulfulnessRepository>();
    final streak = soulRepo.getMindfulStreak();
    final cardBg = isDark ? const Color(0xff1e201e) : const Color(0xffffffff);

    return Container(
      padding: const EdgeInsets.all(18),
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
              Row(
                children: [
                  Icon(Icons.spa_rounded, color: primaryColor, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Soulful Micro-Pause',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.local_fire_department_rounded,
                      size: 13,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      '$streak d',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildPauseAction(
                  label: '1m Breath',
                  icon: Icons.air_rounded,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () {
                    HapticFlow.selection();
                    showAnimatedModalSheet(
                      context: context,
                      builder: (_) => const BreathworkModal(),
                    ).then((_) => setState(() {}));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPauseAction(
                  label: '3m Meditate',
                  icon: Icons.self_improvement_rounded,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () {
                    HapticFlow.selection();
                    showAnimatedModalSheet(
                      context: context,
                      builder: (_) =>
                          const MeditationTimerModal(initialMinutes: 3),
                    ).then((_) => setState(() {}));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildPauseAction(
                  label: 'Let Go',
                  icon: Icons.waves_rounded,
                  primaryColor: primaryColor,
                  isDark: isDark,
                  onTap: () {
                    HapticFlow.selection();
                    showAnimatedModalSheet(
                      context: context,
                      builder: (_) => const ThoughtReleaseModal(),
                    ).then((_) => setState(() {}));
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPauseAction({
    required String label,
    required IconData icon,
    required Color primaryColor,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return PressableScale(
      onPressed: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 6),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff2a2d2a) : const Color(0xfff0efe9),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 15, color: primaryColor),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
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
      colors: [primaryColor.withValues(alpha: 0.5), primaryColor],
      transform: const GradientRotation(-pi / 2),
    );

    // Progress Arc
    final progressPaint = Paint()
      ..shader = gradient.createShader(
        Rect.fromCircle(center: center, radius: radius),
      )
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

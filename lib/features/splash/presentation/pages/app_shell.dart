import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:haptic_flow/haptic_flow.dart';
import 'package:habitrak/core/animations/app_animations.dart';
import 'package:habitrak/core/animations/app_page_route.dart';
import 'package:habitrak/core/theme/app_theme.dart';
import 'package:habitrak/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:habitrak/features/auth/presentation/cubit/auth_state.dart';
import 'package:habitrak/features/auth/presentation/pages/login_page.dart';
import 'package:habitrak/features/habit/presentation/bloc/habit_bloc.dart';
import 'package:habitrak/features/habit/presentation/pages/dashboard_page.dart';
import 'package:habitrak/features/habit/presentation/pages/library_page.dart';
import 'package:habitrak/features/mindfulness/data/repositories/intentional_goals_repository.dart';
import 'package:habitrak/features/mindfulness/data/repositories/soulfulness_repository.dart';
import 'package:habitrak/features/mindfulness/presentation/pages/mindful_living_page.dart';
import 'package:habitrak/features/profile/presentation/pages/profile_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> with WidgetsBindingObserver {
  int _currentIndex = 0;
  int _previousIndex = 0;
  Timer? _midnightTimer;

  static const _pages = [
    DashboardPage(),
    LibraryPage(),
    MindfulLivingPage(),
    ProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _scheduleMidnightSync();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _midnightTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _triggerDailySync();
      _scheduleMidnightSync();
    }
  }

  void _triggerDailySync() {
    if (mounted) {
      context.read<HabitBloc>().add(SyncDailyHabitsEvent());
      context.read<IntentionalGoalsRepository>().syncDailyGoals();
      context.read<SoulfulnessRepository>().syncDailySoulfulness();
    }
  }

  void _scheduleMidnightSync() {
    _midnightTimer?.cancel();
    final now = DateTime.now();
    final tomorrow = DateTime(now.year, now.month, now.day + 1);
    final durationUntilMidnight =
        tomorrow.difference(now) + const Duration(seconds: 1);
    _midnightTimer = Timer(durationUntilMidnight, () {
      _triggerDailySync();
      _scheduleMidnightSync();
    });
  }

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    HapticFlow.selection();
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final slideDirection = _currentIndex > _previousIndex ? 1.0 : -1.0;

    return Scaffold(
      body: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is Unauthenticated) {
            Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
              AppPageRoute(page: const LoginPage()),
              (route) => false,
            );
          }
        },
        child: AnimatedSwitcher(
        duration: AppAnimations.normal,
        switchInCurve: AppAnimations.spring,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          final slide =
              Tween<Offset>(
                begin: Offset(0.04 * slideDirection, 0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: AppAnimations.spring),
              );
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: slide,
              child: ScaleTransition(
                scale: Tween<double>(begin: 0.98, end: 1).animate(
                  CurvedAnimation(
                    parent: animation,
                    curve: AppAnimations.spring,
                  ),
                ),
                child: child,
              ),
            ),
          );
        },
        child: KeyedSubtree(
          key: ValueKey<int>(_currentIndex),
          child: _pages[_currentIndex],
        ),
      ),
    ),
      extendBody: true,
      bottomNavigationBar: SafeArea(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF16181A),
            borderRadius: BorderRadius.circular(36),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.25),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: const Color(0xFF2A2D32),
              width: 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNeoNavItem(
                index: 0,
                icon: Icons.grid_view_rounded,
                label: 'Dashboard',
                badgeText: '3',
              ),
              _buildNeoNavItem(
                index: 1,
                icon: Icons.format_list_bulleted_rounded,
                label: 'Habits',
              ),
              _buildNeoNavItem(
                index: 2,
                icon: Icons.spa_rounded,
                label: 'Mindful',
                badgeText: '1',
              ),
              _buildNeoNavItem(
                index: 3,
                icon: Icons.person_rounded,
                label: 'Profile',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNeoNavItem({
    required int index,
    required IconData icon,
    required String label,
    String? badgeText,
  }) {
    final isSelected = _currentIndex == index;

    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        padding: isSelected
            ? const EdgeInsets.symmetric(horizontal: 14, vertical: 9)
            : const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isSelected ? const Color(0xFF16181A) : Colors.white60,
              size: 20,
            ),
            if (isSelected) ...[
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF16181A),
                ),
              ),
            ],
            if (badgeText != null && isSelected) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: index == 2 ? AppColors.pistaGreen : AppColors.limeAccent,
                  shape: BoxShape.circle,
                ),
                child: Text(
                  badgeText,
                  style: const TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF16181A),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

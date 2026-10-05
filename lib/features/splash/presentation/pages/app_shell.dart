import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitrak/core/animations/app_animations.dart';
import 'package:habitrak/features/habit/presentation/pages/dashboard_page.dart';
import 'package:habitrak/features/habit/presentation/pages/library_page.dart';
import 'package:habitrak/features/mindfulness/presentation/pages/mindful_living_page.dart';
import 'package:habitrak/features/profile/presentation/pages/profile_page.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key});

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  int _currentIndex = 0;
  int _previousIndex = 0;

  static const _pages = [
    DashboardPage(),
    LibraryPage(),
    MindfulLivingPage(),
    ProfilePage(),
  ];

  void _onTabSelected(int index) {
    if (index == _currentIndex) return;
    HapticFeedback.selectionClick();
    setState(() {
      _previousIndex = _currentIndex;
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final slideDirection = _currentIndex > _previousIndex ? 1.0 : -1.0;

    return Scaffold(
      body: AnimatedSwitcher(
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
      extendBody: true,
      bottomNavigationBar: ClipRect(
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 30, sigmaY: 30),
          child: Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xff121212).withValues(alpha: 0.65)
                  : Colors.white.withValues(alpha: 0.65),
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.15)
                      : Colors.black.withValues(alpha: 0.1),
                  width: 0.5,
                ),
              ),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.black.withValues(alpha: 0.05),
                  isDark
                      ? Colors.white.withValues(alpha: 0.0)
                      : Colors.black.withValues(alpha: 0.0),
                ],
                stops: const [0.0, 0.4],
              ),
            ),
            child: SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(top: 8, bottom: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildGlassNavItem(
                      0,
                      Icons.home_filled,
                      Icons.home_outlined,
                      'Home',
                    ),
                    _buildGlassNavItem(
                      1,
                      Icons.library_books,
                      Icons.library_books_outlined,
                      'Library',
                    ),
                    _buildGlassNavItem(
                      2,
                      Icons.grid_view_rounded,
                      Icons.grid_view_outlined,
                      'Mindful',
                    ),
                    _buildGlassNavItem(
                      3,
                      Icons.person,
                      Icons.person_outline,
                      'Profile',
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlassNavItem(
    int index,
    IconData filledIcon,
    IconData outlineIcon,
    String label,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _currentIndex == index;

    final activeColor = isDark ? Colors.white : Colors.black;
    final inactiveColor = isDark ? Colors.white54 : Colors.black54;

    return GestureDetector(
      onTap: () => _onTabSelected(index),
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        width: 76,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              transitionBuilder: (child, animation) {
                return ScaleTransition(
                  scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                    CurvedAnimation(
                      parent: animation,
                      curve: Curves.easeOutBack,
                    ),
                  ),
                  child: FadeTransition(opacity: animation, child: child),
                );
              },
              child: Icon(
                isSelected ? filledIcon : outlineIcon,
                key: ValueKey<bool>(isSelected),
                color: isSelected ? activeColor : inactiveColor,
                size: 26,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:habitrak/core/animations/app_animations.dart';
import 'package:habitrak/core/animations/app_page_route.dart';
import 'package:habitrak/core/animations/staggered_entrance.dart';
import 'app_shell.dart';

class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage> with TickerProviderStateMixin {
  late AnimationController _entranceController;
  late AnimationController _pulseController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _ringRotation;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: AppAnimations.splash,
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.55, curve: Curves.easeOut),
      ),
    );
    _scaleAnimation = Tween<double>(begin: 0.75, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0, 0.65, curve: Curves.easeOutBack),
      ),
    );
    _ringRotation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entranceController,
        curve: const Interval(0.2, 1, curve: Curves.easeInOut),
      ),
    );

    _entranceController.forward();

    Future.delayed(const Duration(milliseconds: 2600), () {
      if (mounted) {
        Navigator.of(
          context,
        ).pushReplacement(AppPageRoute(page: const AppShell()));
      }
    });
  }

  @override
  void dispose() {
    _entranceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Center(
        child: AnimatedBuilder(
          animation: Listenable.merge([_entranceController, _pulseController]),
          builder: (context, child) {
            final pulse = 0.92 + (_pulseController.value * 0.08);
            return FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 130,
                      height: 130,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Transform.rotate(
                            angle: _ringRotation.value * math.pi * 2,
                            child: Container(
                              width: 120 * pulse,
                              height: 120 * pulse,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: primary.withValues(alpha: 0.25),
                                  width: 2,
                                ),
                              ),
                            ),
                          ),
                          Container(
                            width: 108 * pulse,
                            height: 108 * pulse,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primary.withValues(alpha: 0.08),
                            ),
                          ),
                          Container(
                            width: 100,
                            height: 100,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(24),
                              boxShadow: [
                                BoxShadow(
                                  color: primary.withValues(
                                    alpha: isDark ? 0.2 : 0.15,
                                  ),
                                  blurRadius: 24 * pulse,
                                  spreadRadius: 2,
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Image.asset(
                                'assets/images/logo.png',
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),
                    StaggeredEntrance(
                      index: 1,
                      delay: const Duration(milliseconds: 400),
                      child: Text(
                        'habitrak',
                        style: Theme.of(context).textTheme.displayLarge
                            ?.copyWith(
                              fontSize: 36,
                              fontWeight: FontWeight.w700,
                              color: primary,
                              letterSpacing: -0.5,
                            ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    StaggeredEntrance(
                      index: 2,
                      delay: const Duration(milliseconds: 550),
                      child: Text(
                        'Mindful Progress',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? const Color(0xffc2c8c0).withValues(alpha: 0.6)
                              : const Color(0xff615e56).withValues(alpha: 0.6),
                          fontSize: 14,
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

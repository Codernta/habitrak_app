import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitrak/core/animations/app_animations.dart';
import 'package:habitrak/core/animations/pressable_scale.dart';
import '../../data/repositories/soulfulness_repository.dart';

class ThoughtReleaseModal extends StatefulWidget {
  const ThoughtReleaseModal({super.key});

  @override
  State<ThoughtReleaseModal> createState() => _ThoughtReleaseModalState();
}

class _ThoughtReleaseModalState extends State<ThoughtReleaseModal>
    with SingleTickerProviderStateMixin {
  final TextEditingController _thoughtController = TextEditingController();
  late AnimationController _driftController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _slideDownAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _driftAngleAnimation;

  bool _isReleasing = false;
  bool _isReleased = false;

  @override
  void initState() {
    super.initState();
    _driftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );

    _fadeAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _driftController,
        curve: const Interval(0.55, 1.0, curve: Curves.easeIn),
      ),
    );

    _slideDownAnimation = Tween<double>(begin: 0.0, end: 180.0).animate(
      CurvedAnimation(
        parent: _driftController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOutQuad),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.25).animate(
      CurvedAnimation(
        parent: _driftController,
        curve: const Interval(0.2, 1.0, curve: Curves.easeInBack),
      ),
    );

    _driftAngleAnimation = Tween<double>(begin: 0.0, end: 0.35).animate(
      CurvedAnimation(
        parent: _driftController,
        curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
      ),
    );

    _driftController.addStatusListener((status) {
      if (status == AnimationStatus.completed && mounted) {
        setState(() {
          _isReleased = true;
          _isReleasing = false;
        });
      }
    });
  }

  @override
  void dispose() {
    _thoughtController.dispose();
    _driftController.dispose();
    super.dispose();
  }

  void _releaseThought() {
    final text = _thoughtController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _isReleasing = true;
    });

    // Record release in Hive repository
    context.read<SoulfulnessRepository>().recordThoughtRelease();

    _driftController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? const Color(0xffb0ceb2)
        : const Color(0xff8ba88e);
    final cardBg = isDark ? const Color(0xff1e201e) : const Color(0xffffffff);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xff424842)
                      : const Color(0xffdbdad7),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.waves_rounded, color: primaryColor, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        'Release to the River',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    ],
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(
                      Icons.close_rounded,
                      color: isDark
                          ? const Color(0xffc2c8c0)
                          : const Color(0xff615e56),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (!_isReleased) ...[
                Text(
                  'Write down what is weighing on you. When you send it to the river, it gently drifts downstream. This thought is not saved anywhere.',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xffc2c8c0).withValues(alpha: 0.7)
                        : const Color(0xff615e56).withValues(alpha: 0.7),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Animated Thought Leaf / Input card
                AnimatedBuilder(
                  animation: _driftController,
                  builder: (context, child) {
                    return Transform.translate(
                      offset: Offset(
                        math.sin(_driftAngleAnimation.value * 5) * 20,
                        _slideDownAnimation.value,
                      ),
                      child: Transform.rotate(
                        angle: _driftAngleAnimation.value,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: Opacity(
                            opacity: AppAnimations.clampOpacity(
                              _fadeAnimation.value,
                            ),
                            child: child,
                          ),
                        ),
                      ),
                    );
                  },
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xff182219).withValues(alpha: 0.6)
                          : const Color(0xffeaf0ea),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: primaryColor.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.eco_rounded,
                              size: 18,
                              color: primaryColor,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Leaf on the River',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _thoughtController,
                          maxLines: 4,
                          enabled: !_isReleasing,
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 14,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          decoration: InputDecoration(
                            hintText:
                                'What worry, irritation, or burden are you ready to surrender to the water?',
                            hintStyle: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 13,
                              color: isDark
                                  ? const Color(
                                      0xffc2c8c0,
                                    ).withValues(alpha: 0.4)
                                  : const Color(
                                      0xff615e56,
                                    ).withValues(alpha: 0.4),
                            ),
                            border: InputBorder.none,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                if (!_isReleasing)
                  PressableScale(
                    onPressed: _releaseThought,
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      decoration: BoxDecoration(
                        color: primaryColor,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        'LET IT FLOAT AWAY',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.0,
                          color: isDark
                              ? const Color(0xff1c3622)
                              : Colors.white,
                        ),
                      ),
                    ),
                  )
                else
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    alignment: Alignment.center,
                    child: Text(
                      'Drifting with the current...',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: primaryColor,
                      ),
                    ),
                  ),
              ] else ...[
                // Released Affirmation State
                const SizedBox(height: 24),
                Container(
                  width: 90,
                  height: 90,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: primaryColor.withValues(alpha: 0.15),
                  ),
                  child: Icon(
                    Icons.water_rounded,
                    color: primaryColor,
                    size: 46,
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'The River Carried It Away',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  '"You do not have to hold on to what has passed. The current is gentle, and your mind is clear again."',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 14,
                    fontStyle: FontStyle.italic,
                    color: isDark
                        ? const Color(0xffc2c8c0)
                        : const Color(0xff615e56),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                PressableScale(
                  onPressed: () => Navigator.pop(context),
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'REST IN PRESENCE',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: isDark ? const Color(0xff1c3622) : Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

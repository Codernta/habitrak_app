import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitrak/core/animations/pressable_scale.dart';
import '../../data/repositories/soulfulness_repository.dart';

enum BreathPhase { inhale, holdIn, exhale, holdOut }

class BreathPattern {
  final String id;
  final String name;
  final String subtitle;
  final int inhaleSeconds;
  final int holdInSeconds;
  final int exhaleSeconds;
  final int holdOutSeconds;
  final int targetCycles;

  const BreathPattern({
    required this.id,
    required this.name,
    required this.subtitle,
    required this.inhaleSeconds,
    required this.holdInSeconds,
    required this.exhaleSeconds,
    required this.holdOutSeconds,
    this.targetCycles = 4,
  });

  int get cycleDuration =>
      inhaleSeconds + holdInSeconds + exhaleSeconds + holdOutSeconds;
}

class BreathworkModal extends StatefulWidget {
  const BreathworkModal({super.key});

  @override
  State<BreathworkModal> createState() => _BreathworkModalState();
}

class _BreathworkModalState extends State<BreathworkModal>
    with TickerProviderStateMixin {
  static const List<BreathPattern> patterns = [
    BreathPattern(
      id: 'box',
      name: 'Box Breathing',
      subtitle: 'Balance nervous system & focus (4-4-4-4)',
      inhaleSeconds: 4,
      holdInSeconds: 4,
      exhaleSeconds: 4,
      holdOutSeconds: 4,
      targetCycles: 4,
    ),
    BreathPattern(
      id: 'relax_478',
      name: '4-7-8 Relax',
      subtitle: 'Deep calm & sleep tranquility',
      inhaleSeconds: 4,
      holdInSeconds: 7,
      exhaleSeconds: 8,
      holdOutSeconds: 0,
      targetCycles: 4,
    ),
    BreathPattern(
      id: 'coherent',
      name: 'Heart Coherence',
      subtitle: '5.5s In & 5.5s Out for optimal HRV',
      inhaleSeconds: 5,
      holdInSeconds: 0,
      exhaleSeconds: 5,
      holdOutSeconds: 0,
      targetCycles: 6,
    ),
    BreathPattern(
      id: 'prana_awaken',
      name: 'Awakening Prana',
      subtitle: 'Brisk energy & mental clarity',
      inhaleSeconds: 2,
      holdInSeconds: 1,
      exhaleSeconds: 2,
      holdOutSeconds: 1,
      targetCycles: 8,
    ),
  ];

  late BreathPattern _selectedPattern;
  late AnimationController _animController;
  late AnimationController _pulseController;
  Timer? _countdownTimer;
  AudioPlayer? _bellPlayer;

  bool _isActive = false;
  bool _isCompleted = false;
  BreathPhase _currentPhase = BreathPhase.inhale;
  int _secondsRemainingInPhase = 4;
  int _completedCycles = 0;
  int _totalElapsedSeconds = 0;

  @override
  void initState() {
    super.initState();
    _selectedPattern = patterns[0];
    _secondsRemainingInPhase = _selectedPattern.inhaleSeconds;

    _animController = AnimationController(
      vsync: this,
      duration: Duration(seconds: _selectedPattern.inhaleSeconds),
    );

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _animController.dispose();
    _pulseController.dispose();
    _bellPlayer?.dispose();
    super.dispose();
  }

  void _startSession() {
    HapticFeedback.heavyImpact();
    setState(() {
      _isActive = true;
      _isCompleted = false;
      _completedCycles = 0;
      _totalElapsedSeconds = 0;
      _currentPhase = BreathPhase.inhale;
      _secondsRemainingInPhase = _selectedPattern.inhaleSeconds;
    });

    _startPhase(BreathPhase.inhale);
  }

  void _startPhase(BreathPhase phase) {
    _currentPhase = phase;
    int durationSec;
    switch (phase) {
      case BreathPhase.inhale:
        durationSec = _selectedPattern.inhaleSeconds;
        _animController.duration = Duration(seconds: durationSec);
        _animController.forward(from: 0.0);
        HapticFeedback.mediumImpact();
        break;
      case BreathPhase.holdIn:
        durationSec = _selectedPattern.holdInSeconds;
        HapticFeedback.lightImpact();
        break;
      case BreathPhase.exhale:
        durationSec = _selectedPattern.exhaleSeconds;
        _animController.duration = Duration(seconds: durationSec);
        _animController.reverse(from: 1.0);
        HapticFeedback.mediumImpact();
        break;
      case BreathPhase.holdOut:
        durationSec = _selectedPattern.holdOutSeconds;
        HapticFeedback.lightImpact();
        break;
    }

    _secondsRemainingInPhase = durationSec;

    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      setState(() {
        _totalElapsedSeconds++;
        _secondsRemainingInPhase--;
      });

      if (_secondsRemainingInPhase <= 0) {
        timer.cancel();
        _nextPhase();
      }
    });
  }

  void _nextPhase() {
    if (!_isActive) return;

    switch (_currentPhase) {
      case BreathPhase.inhale:
        if (_selectedPattern.holdInSeconds > 0) {
          _startPhase(BreathPhase.holdIn);
        } else {
          _startPhase(BreathPhase.exhale);
        }
        break;
      case BreathPhase.holdIn:
        _startPhase(BreathPhase.exhale);
        break;
      case BreathPhase.exhale:
        if (_selectedPattern.holdOutSeconds > 0) {
          _startPhase(BreathPhase.holdOut);
        } else {
          _completeCycle();
        }
        break;
      case BreathPhase.holdOut:
        _completeCycle();
        break;
    }
  }

  void _completeCycle() {
    _completedCycles++;
    if (_completedCycles >= _selectedPattern.targetCycles) {
      _finishSession();
    } else {
      _startPhase(BreathPhase.inhale);
    }
  }

  Future<void> _playCompletionBell() async {
    try {
      _bellPlayer ??= AudioPlayer();
      await _bellPlayer!.play(AssetSource('audio/zen_bell.mp3'), volume: 0.7);
    } catch (_) {}
  }

  void _finishSession() {
    _countdownTimer?.cancel();
    _playCompletionBell();
    HapticFeedback.heavyImpact();

    // Record session into Hive repository
    context.read<SoulfulnessRepository>().recordBreathworkSession(
      patternName: _selectedPattern.name,
      cycles: _completedCycles,
      durationSeconds: _totalElapsedSeconds,
    );

    setState(() {
      _isActive = false;
      _isCompleted = true;
    });
  }

  void _stopSession() {
    HapticFeedback.selectionClick();
    _countdownTimer?.cancel();
    _animController.stop();
    setState(() {
      _isActive = false;
      _secondsRemainingInPhase = _selectedPattern.inhaleSeconds;
    });
  }

  String _getPhaseTitle() {
    switch (_currentPhase) {
      case BreathPhase.inhale:
        return 'Inhale Slowly';
      case BreathPhase.holdIn:
        return 'Hold Fullness';
      case BreathPhase.exhale:
        return 'Exhale Smoothly';
      case BreathPhase.holdOut:
        return 'Rest in Stillness';
    }
  }

  String _getPhaseSubtitle() {
    switch (_currentPhase) {
      case BreathPhase.inhale:
        return 'Feel the chest and belly expand with fresh life';
      case BreathPhase.holdIn:
        return 'Suspended in quiet, effortless presence';
      case BreathPhase.exhale:
        return 'Let go of tension, stress, and busy thoughts';
      case BreathPhase.holdOut:
        return 'Empty space before the next natural breath';
    }
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
        maxHeight: MediaQuery.of(context).size.height * 0.90,
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

              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(Icons.air_rounded, color: primaryColor, size: 26),
                      const SizedBox(width: 10),
                      Text(
                        'Pranayama Pacer',
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

              // Pattern Selector Chips (when not actively breathing)
              if (!_isActive && !_isCompleted) ...[
                SizedBox(
                  height: 38,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: patterns.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (context, idx) {
                      final p = patterns[idx];
                      final isSelected = p.id == _selectedPattern.id;
                      return ChoiceChip(
                        label: Text(
                          p.name,
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 12,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: isSelected
                                ? (isDark
                                      ? const Color(0xff1c3622)
                                      : Colors.white)
                                : (isDark
                                      ? const Color(0xffc2c8c0)
                                      : const Color(0xff615e56)),
                          ),
                        ),
                        selected: isSelected,
                        selectedColor: primaryColor,
                        backgroundColor: isDark
                            ? const Color(0xff2a2d2a)
                            : const Color(0xfff0efe9),
                        onSelected: (val) {
                          if (val) {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedPattern = p;
                              _secondsRemainingInPhase = p.inhaleSeconds;
                            });
                          }
                        },
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _selectedPattern.subtitle,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 12,
                    color: isDark
                        ? const Color(0xffc2c8c0).withValues(alpha: 0.6)
                        : const Color(0xff615e56).withValues(alpha: 0.6),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Breathing Animation Circle
              if (!_isCompleted)
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _animController,
                    _pulseController,
                  ]),
                  builder: (context, child) {
                    final breathScale = 0.55 + (_animController.value * 0.45);
                    final pulseAura = 1.0 + (_pulseController.value * 0.08);

                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        // Outer pulsating aura ring
                        Transform.scale(
                          scale: breathScale * pulseAura * 1.35,
                          child: Container(
                            width: 220,
                            height: 220,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: RadialGradient(
                                colors: [
                                  primaryColor.withValues(alpha: 0.22),
                                  primaryColor.withValues(alpha: 0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                        // Intermediate dashed guidance ring
                        Container(
                          width: 230,
                          height: 230,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.2),
                              width: 1.5,
                            ),
                          ),
                        ),
                        // Main expanding breathing sphere
                        Transform.scale(
                          scale: breathScale,
                          child: Container(
                            width: 190,
                            height: 190,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [
                                  primaryColor.withValues(alpha: 0.85),
                                  primaryColor.withValues(alpha: 0.50),
                                ],
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withValues(alpha: 0.35),
                                  blurRadius: 28,
                                  spreadRadius: 4,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                _isActive
                                    ? '$_secondsRemainingInPhase'
                                    : 'Start',
                                style: TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: _isActive ? 46 : 24,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? const Color(0xff122014)
                                      : Colors.white,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                )
              else
                // Completion card
                Column(
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        Icons.spa_rounded,
                        color: primaryColor,
                        size: 50,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Session Complete',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Completed $_completedCycles cycles (${_totalElapsedSeconds}s). Mindful session saved to your daily practice.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 14,
                        color: isDark
                            ? const Color(0xffc2c8c0)
                            : const Color(0xff615e56),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // Text cues
              if (_isActive) ...[
                Text(
                  _getPhaseTitle(),
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _getPhaseSubtitle(),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 13,
                    color: isDark
                        ? const Color(0xffc2c8c0).withValues(alpha: 0.7)
                        : const Color(0xff615e56).withValues(alpha: 0.7),
                  ),
                ),
                const SizedBox(height: 14),
                // Cycle progress pill
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xff2a2d2a)
                        : const Color(0xfff0efe9),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'Cycle ${_completedCycles + 1} of ${_selectedPattern.targetCycles}',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: primaryColor,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Action buttons
              if (!_isActive && !_isCompleted)
                PressableScale(
                  onPressed: _startSession,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'BEGIN BREATHING',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.0,
                        color: isDark ? const Color(0xff1c3622) : Colors.white,
                      ),
                    ),
                  ),
                )
              else if (_isActive)
                PressableScale(
                  onPressed: _stopSession,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xff2a2d2a)
                          : const Color(0xfff0efe9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'END SESSION',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isDark
                            ? const Color(0xffc2c8c0)
                            : const Color(0xff615e56),
                      ),
                    ),
                  ),
                )
              else
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
                      'CLOSE & REST',
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
          ),
        ),
      ),
    );
  }
}

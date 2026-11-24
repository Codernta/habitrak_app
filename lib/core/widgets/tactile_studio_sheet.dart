import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:haptic_flow/haptic_flow.dart';
import '../theme/app_theme.dart';
import 'package:habitrak/core/animations/pressable_scale.dart';

/// Interactive Tactile Sensation Studio
///
/// Showcases and allows hands-on exploration of all major `haptic_flow`
/// capabilities: physical presets, HapticSlider, HapticPickerWheel,
/// HapticGestureDetector, and declarative shorthand pattern composition.
class TactileStudioSheet extends StatefulWidget {
  const TactileStudioSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const TactileStudioSheet(),
    );
  }

  @override
  State<TactileStudioSheet> createState() => _TactileStudioSheetState();
}

class _TactileStudioSheetState extends State<TactileStudioSheet> {
  double _sliderValue = 50.0;
  int _selectedWheelIndex = 2;
  String _lastGestureEvent = 'Touch the pad below to feel cues';
  final TextEditingController _patternController =
      TextEditingController(text: '.-=*_M_H');
  bool _isPlayingPattern = false;

  final List<Map<String, dynamic>> _presets = [
    {
      'name': 'Success Snap',
      'desc': 'Affirmative double-stage confirmation',
      'icon': Icons.check_circle_outline_rounded,
      'preset': HapticPresets.successSnap,
      'color': AppColors.limeAccent,
    },
    {
      'name': 'Mechanical Dial',
      'desc': 'Rotary safe combination ticks',
      'icon': Icons.tune_rounded,
      'preset': HapticPresets.mechanicalDial,
      'color': const Color(0xff5a93ab),
    },
    {
      'name': 'Heartbeat',
      'desc': 'Two-stage cardiac rhythm (lub-dub)',
      'icon': Icons.favorite_rounded,
      'preset': HapticPresets.heartbeat,
      'color': const Color(0xffd47a88),
    },
    {
      'name': 'Sparkle',
      'desc': 'Magical staccato micro-click flutter',
      'icon': Icons.auto_awesome_rounded,
      'preset': HapticPresets.sparkle,
      'color': const Color(0xffd4af37),
    },
    {
      'name': 'Recharge Pulse',
      'desc': 'Escalating power crescendo ramp',
      'icon': Icons.bolt_rounded,
      'preset': HapticPresets.rechargePulse,
      'color': const Color(0xffe59866),
    },
    {
      'name': 'Countdown',
      'desc': '3-2-1 cadence concluding in launch pulse',
      'icon': Icons.timer_rounded,
      'preset': HapticPresets.countdown,
      'color': const Color(0xff7fb3d5),
    },
    {
      'name': 'Typewriter',
      'desc': 'Sharp typebar strike & escapement',
      'icon': Icons.keyboard_rounded,
      'preset': HapticPresets.typewriter,
      'color': const Color(0xff99a3a4),
    },
    {
      'name': 'Dice Roll',
      'desc': 'Decelerating bouncing dice clicks',
      'icon': Icons.casino_rounded,
      'preset': HapticPresets.diceRoll,
      'color': const Color(0xffa569bd),
    },
    {
      'name': 'Lock Pick',
      'desc': 'Tumbler pin clicks & cylinder turn',
      'icon': Icons.lock_open_rounded,
      'preset': HapticPresets.lockPick,
      'color': const Color(0xff73c6b6),
    },
    {
      'name': 'Warning Buzz',
      'desc': 'Double-pulse cautionary alert',
      'icon': Icons.warning_amber_rounded,
      'preset': HapticPresets.warningBuzz,
      'color': const Color(0xfff39c12),
    },
    {
      'name': 'Error Alarm',
      'desc': 'Forceful triplet destructive alarm',
      'icon': Icons.error_outline_rounded,
      'preset': HapticPresets.errorAlarm,
      'color': const Color(0xffe74c3c),
    },
    {
      'name': 'Battering Ram',
      'desc': 'Massive impact with reverberating aftershocks',
      'icon': Icons.fitness_center_rounded,
      'preset': HapticPresets.batteringRam,
      'color': const Color(0xff5d6d7e),
    },
  ];

  final List<String> _wheelItems = [
    '5 Minutes',
    '10 Minutes',
    '15 Minutes',
    '20 Minutes',
    '30 Minutes',
    '45 Minutes',
    '60 Minutes',
  ];

  @override
  void dispose() {
    _patternController.dispose();
    super.dispose();
  }

  Future<void> _playPattern() async {
    final pattern = _patternController.text.trim();
    if (pattern.isEmpty) return;

    setState(() => _isPlayingPattern = true);
    try {
      final score = HapticSequence.fromPattern(
        pattern,
        tickDuration: const Duration(milliseconds: 45),
        pauseDuration: const Duration(milliseconds: 70),
      );
      await HapticFlow.play(score);
    } catch (_) {
      HapticFlow.play(HapticPresets.warningBuzz);
    } finally {
      if (mounted) setState(() => _isPlayingPattern = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor =
        isDark ? AppColors.limeAccent : AppColors.obsidianBlack;
    final cardBg =
        isDark ? const Color(0xff1e201e) : const Color(0xffffffff);
    final sectionBg =
        isDark ? const Color(0xff252825) : const Color(0xfff7f6f2);

    return BackdropFilter(
      filter: ui.ImageFilter.blur(sigmaX: 12, sigmaY: 12),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
        ),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 30,
              offset: const Offset(0, -6),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag handle
              const SizedBox(height: 12),
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: (isDark ? Colors.white : Colors.black)
                        .withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Sheet Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.vibration_rounded,
                        color: primaryColor,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Tactile Sensation Studio',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                          Text(
                            'Powered by haptic_flow choreography engine',
                            overflow: TextOverflow.ellipsis,
                            maxLines: 1,
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 12,
                              color: isDark
                                  ? AppColors.limeAccent
                                  : const Color(0xff615e56),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 24, thickness: 1),

              // Scrollable Studio Sections
              Expanded(
                child: SingleChildScrollView(
                  physics: const HapticScrollPhysics(
                    detentDistance: 100.0,
                    triggerAtEdges: true,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Section 1: Tactile Slider
                      _buildSectionHeader(
                        '1. HapticSlider (Detents & Snaps)',
                        Icons.linear_scale_rounded,
                        primaryColor,
                        isDark,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: sectionBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Tactile ticks at every 10 units, center snap at 50, and firm edge bumpers at 0 and 100:',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xffc2c8c0)
                                    : const Color(0xff615e56),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Value: ${_sliderValue.round()}',
                                  style: TextStyle(
                                    fontFamily: 'Hanken Grotesk',
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                    color: primaryColor,
                                  ),
                                ),
                                if (_sliderValue == 50.0)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: primaryColor.withValues(alpha: 0.2),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      'Center Snap Point',
                                      style: TextStyle(
                                        fontFamily: 'Hanken Grotesk',
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: primaryColor,
                                inactiveTrackColor: primaryColor.withValues(alpha: 0.2),
                                thumbColor: primaryColor,
                              ),
                              child: HapticSlider(
                                value: _sliderValue,
                                min: 0.0,
                                max: 100.0,
                                detentInterval: 10.0,
                                centerDetentValue: 50.0,
                                enableEdgeFeedback: true,
                                onChanged: (val) {
                                  setState(() => _sliderValue = val);
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section 2: Haptic Picker Wheel
                      _buildSectionHeader(
                        '2. HapticPickerWheel (Mechanical Rotary Tumbler)',
                        Icons.rotate_right_rounded,
                        primaryColor,
                        isDark,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: sectionBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Spin the rotary dial to experience crisp mechanical clicks on each index:',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 13,
                                color: isDark
                                    ? const Color(0xffc2c8c0)
                                    : const Color(0xff615e56),
                              ),
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              height: 130,
                              child: HapticPickerWheel(
                                itemExtent: 40,
                                initialIndex: _selectedWheelIndex,
                                onSelectedItemChanged: (idx) {
                                  setState(() => _selectedWheelIndex = idx);
                                },
                                children: _wheelItems.map((item) {
                                  final isSelected =
                                      _wheelItems[_selectedWheelIndex] == item;
                                  return Center(
                                    child: Text(
                                      item,
                                      style: TextStyle(
                                        fontFamily: 'Hanken Grotesk',
                                        fontSize: isSelected ? 17 : 14,
                                        fontWeight: isSelected
                                            ? FontWeight.bold
                                            : FontWeight.normal,
                                        color: isSelected
                                            ? primaryColor
                                            : (isDark
                                                ? Colors.white60
                                                : Colors.black54),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section 3: HapticGestureDetector Touch Pad
                      _buildSectionHeader(
                        '3. HapticGestureDetector (Tactile Touch Pad)',
                        Icons.touch_app_rounded,
                        primaryColor,
                        isDark,
                      ),
                      const SizedBox(height: 8),
                      HapticGestureDetector(
                        onTap: () {
                          setState(() {
                            _lastGestureEvent = 'Single Tap Triggered (Light Impact)';
                          });
                        },
                        onDoubleTap: () {
                          setState(() {
                            _lastGestureEvent = 'Double Tap Triggered (Selection Click)';
                          });
                        },
                        onLongPress: () {
                          setState(() {
                            _lastGestureEvent = 'Long Press Triggered (Heavy Bump)';
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            vertical: 24,
                            horizontal: 20,
                          ),
                          decoration: BoxDecoration(
                            color: sectionBg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: primaryColor.withValues(alpha: 0.35),
                              width: 1.5,
                            ),
                          ),
                          child: Column(
                            children: [
                              Icon(
                                Icons.fingerprint_rounded,
                                size: 38,
                                color: primaryColor,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                _lastGestureEvent,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                'Tap = Light  •  Double Tap = Click  •  Hold = Heavy',
                                style: TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 11,
                                  color: isDark
                                      ? AppColors.limeAccent
                                      : const Color(0xff615e56),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Section 4: Physical Presets Library
                      _buildSectionHeader(
                        '4. Real-World Physical Presets Library',
                        Icons.auto_fix_high_rounded,
                        primaryColor,
                        isDark,
                      ),
                      const SizedBox(height: 10),
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                          childAspectRatio: 1.55,
                        ),
                        itemCount: _presets.length,
                        itemBuilder: (context, idx) {
                          final p = _presets[idx];
                          final name = p['name'] as String;
                          final desc = p['desc'] as String;
                          final icon = p['icon'] as IconData;
                          final color = p['color'] as Color;
                          final preset = p['preset'] as HapticSequence;

                          return PressableScale(
                            onTap: () async {
                              await HapticFlow.play(preset);
                            },
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: sectionBg,
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: color.withValues(alpha: 0.25),
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.all(6),
                                        decoration: BoxDecoration(
                                          color: color.withValues(alpha: 0.15),
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(icon, color: color, size: 18),
                                      ),
                                      Icon(
                                        Icons.play_arrow_rounded,
                                        color: color.withValues(alpha: 0.6),
                                        size: 20,
                                      ),
                                    ],
                                  ),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        name,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Hanken Grotesk',
                                          fontWeight: FontWeight.bold,
                                          fontSize: 13,
                                          color: isDark
                                              ? Colors.white
                                              : Colors.black,
                                        ),
                                      ),
                                      Text(
                                        desc,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontFamily: 'Hanken Grotesk',
                                          fontSize: 10,
                                          color: isDark
                                              ? const Color(0xffc2c8c0)
                                              : const Color(0xff615e56),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                      const SizedBox(height: 24),

                      // Section 5: Pattern String Composer
                      _buildSectionHeader(
                        '5. Shorthand Pattern Composer',
                        Icons.music_note_rounded,
                        primaryColor,
                        isDark,
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: sectionBg,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Key: . (light)  - (medium)  = (heavy)  * (click)  _ (pause)',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: primaryColor,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _patternController,
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: isDark ? Colors.white : Colors.black,
                                      letterSpacing: 2,
                                    ),
                                    decoration: InputDecoration(
                                      labelText: 'Tactile Pattern String',
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 14,
                                        vertical: 10,
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                ElevatedButton.icon(
                                  onPressed: _isPlayingPattern ? null : _playPattern,
                                  icon: _isPlayingPattern
                                      ? const SizedBox(
                                          width: 16,
                                          height: 16,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Icon(Icons.play_arrow_rounded),
                                  label: const Text('Play'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: primaryColor,
                                    foregroundColor:
                                        isDark ? const Color(0xff1e201e) : Colors.white,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionHeader(
    String title,
    IconData icon,
    Color primaryColor,
    bool isDark,
  ) {
    return Row(
      children: [
        Icon(icon, size: 18, color: primaryColor),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      ],
    );
  }
}

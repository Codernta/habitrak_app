import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitrak/core/animations/pressable_scale.dart';
import '../../data/repositories/soulfulness_repository.dart';
import '../../../music/services/soulful_music_service.dart';

class MeditationTimerModal extends StatefulWidget {
  final int initialMinutes;

  const MeditationTimerModal({super.key, this.initialMinutes = 5});

  @override
  State<MeditationTimerModal> createState() => _MeditationTimerModalState();
}

class _MeditationTimerModalState extends State<MeditationTimerModal>
    with SingleTickerProviderStateMixin {
  late int _selectedMinutes;
  int _secondsRemaining = 0;
  bool _isActive = false;
  bool _isFinished = false;
  Timer? _ticker;

  AudioPlayer? _bellPlayer;
  final SoulfulMusicService _musicService = SoulfulMusicService();
  String _selectedAmbientSound =
      'silence'; // 'silence', 'rain', 'forest', 'ocean'

  late AnimationController _ambientPulseController;

  static const List<int> _durations = [1, 3, 5, 10, 15, 20];

  @override
  void initState() {
    super.initState();
    _selectedMinutes = widget.initialMinutes;
    _secondsRemaining = _selectedMinutes * 60;

    _ambientPulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _ticker?.cancel();
    _ambientPulseController.dispose();
    _bellPlayer?.dispose();
    if (_selectedAmbientSound != 'silence') {
      _musicService.pause();
    }
    super.dispose();
  }

  Future<void> _playZenBell() async {
    try {
      _bellPlayer ??= AudioPlayer();
      await _bellPlayer!.play(AssetSource('audio/zen_bell.mp3'), volume: 0.85);
    } catch (_) {}
  }

  void _startTimer() {
    HapticFeedback.heavyImpact();
    _playZenBell();

    if (_selectedAmbientSound != 'silence') {
      _startAmbientSound();
    }

    setState(() {
      _isActive = true;
      _isFinished = false;
      _secondsRemaining = _selectedMinutes * 60;
    });

    _ticker?.cancel();
    _ticker = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) return;
      if (_secondsRemaining > 0) {
        setState(() {
          _secondsRemaining--;
        });
      } else {
        _onTimerComplete();
      }
    });
  }

  void _startAmbientSound() {
    final tracks = SoulfulMusicService.curatedTracks;
    switch (_selectedAmbientSound) {
      case 'rain':
        final rain = tracks.firstWhere(
          (t) => t.id == 'rain_reflection_3',
          orElse: () => tracks[0],
        );
        _musicService.playTrack(rain);
        break;
      case 'forest':
        final forest = tracks.firstWhere(
          (t) => t.id == 'forest_canopy_6',
          orElse: () => tracks[0],
        );
        _musicService.playTrack(forest);
        break;
      case 'ocean':
        final ocean = tracks.firstWhere(
          (t) => t.id == 'ocean_breath_2',
          orElse: () => tracks[0],
        );
        _musicService.playTrack(ocean);
        break;
    }
  }

  void _onTimerComplete() {
    _ticker?.cancel();
    _playZenBell();
    HapticFeedback.heavyImpact();

    if (_selectedAmbientSound != 'silence') {
      _musicService.pause();
    }

    // Save meditation session in Hive
    context.read<SoulfulnessRepository>().recordMeditationSession(
      durationMinutes: _selectedMinutes,
      technique: _selectedAmbientSound == 'silence'
          ? 'Silent Zen'
          : 'Ambient Zen',
    );

    setState(() {
      _isActive = false;
      _isFinished = true;
    });
  }

  void _stopTimer() {
    HapticFeedback.lightImpact();
    _ticker?.cancel();
    if (_selectedAmbientSound != 'silence') {
      _musicService.pause();
    }
    setState(() {
      _isActive = false;
      _secondsRemaining = _selectedMinutes * 60;
    });
  }

  String _formatTime(int totalSeconds) {
    final m = totalSeconds ~/ 60;
    final s = totalSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? const Color(0xffb0ceb2)
        : const Color(0xff8ba88e);
    final cardBg = isDark ? const Color(0xff1e201e) : const Color(0xffffffff);
    final totalSecs = _selectedMinutes * 60;
    final progress = totalSecs > 0 ? (_secondsRemaining / totalSecs) : 0.0;

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
              // Drag Handle
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
                  Expanded(
                    child: Row(
                      children: [
                        Icon(
                          Icons.self_improvement_rounded,
                          color: primaryColor,
                          size: 26,
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Meditation Sanctuary',
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                      ],
                    ),
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

              // Duration chips (when not active)
              if (!_isActive && !_isFinished) ...[
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  clipBehavior: Clip.none,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: _durations.map((mins) {
                      final isSel = mins == _selectedMinutes;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: InkWell(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedMinutes = mins;
                              _secondsRemaining = mins * 60;
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: isSel
                                  ? primaryColor
                                  : (isDark
                                        ? const Color(0xff2a2d2a)
                                        : const Color(0xfff0efe9)),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${mins}m',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 13,
                                fontWeight: isSel
                                    ? FontWeight.bold
                                    : FontWeight.w500,
                                color: isSel
                                    ? (isDark
                                          ? const Color(0xff1c3622)
                                          : Colors.white)
                                    : (isDark
                                          ? const Color(0xffc2c8c0)
                                          : const Color(0xff615e56)),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                const SizedBox(height: 14),

                // Sound atmosphere chips
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  clipBehavior: Clip.none,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildSoundChip(
                        'Silence',
                        'silence',
                        Icons.volume_off_rounded,
                        primaryColor,
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildSoundChip(
                        'Rain',
                        'rain',
                        Icons.water_drop_rounded,
                        primaryColor,
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildSoundChip(
                        'Forest',
                        'forest',
                        Icons.forest_rounded,
                        primaryColor,
                        isDark,
                      ),
                      const SizedBox(width: 8),
                      _buildSoundChip(
                        'Ocean',
                        'ocean',
                        Icons.waves_rounded,
                        primaryColor,
                        isDark,
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Circular Countdown / Completed state
              if (!_isFinished)
                AnimatedBuilder(
                  animation: _ambientPulseController,
                  builder: (context, child) {
                    final pulse = 1.0 + (_ambientPulseController.value * 0.05);
                    return SizedBox(
                      width: 200,
                      height: 200,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Outer ambient pulse glow
                          Transform.scale(
                            scale: pulse,
                            child: Container(
                              width: 190,
                              height: 190,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryColor.withValues(
                                  alpha: _isActive ? 0.08 : 0.03,
                                ),
                              ),
                            ),
                          ),
                          // Progress ring
                          SizedBox(
                            width: 180,
                            height: 180,
                            child: CircularProgressIndicator(
                              value: _isActive ? progress : 1.0,
                              strokeWidth: 4.5,
                              backgroundColor: isDark
                                  ? const Color(0xff2a2d2a)
                                  : const Color(0xffe8e7e1),
                              valueColor: AlwaysStoppedAnimation<Color>(
                                primaryColor,
                              ),
                            ),
                          ),
                          // Center time readout
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _formatTime(_secondsRemaining),
                                style: TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 38,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                _isActive
                                    ? 'Resting in Stillness'
                                    : 'Ready to Sit',
                                style: TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: primaryColor,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                )
              else
                // Finished state
                Column(
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor.withValues(alpha: 0.15),
                      ),
                      child: Icon(
                        Icons.check_circle_outline_rounded,
                        color: primaryColor,
                        size: 44,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Peace Arrives',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'You dedicated $_selectedMinutes minutes to mindful presence today. Recorded to your daily soulful journey.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 13,
                        color: isDark
                            ? const Color(0xffc2c8c0)
                            : const Color(0xff615e56),
                        height: 1.4,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 28),

              // Action buttons
              if (!_isActive && !_isFinished)
                PressableScale(
                  onPressed: _startTimer,
                  child: Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: primaryColor,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'BEGIN MEDITATION',
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
                  onPressed: _stopTimer,
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
                      'PAUSE & END',
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
                      'RETURN TO DAY',
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

  Widget _buildSoundChip(
    String label,
    String id,
    IconData icon,
    Color primary,
    bool isDark,
  ) {
    final isSel = _selectedAmbientSound == id;
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        setState(() => _selectedAmbientSound = id);
      },
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSel
              ? primary.withValues(alpha: 0.2)
              : (isDark ? const Color(0xff2a2d2a) : const Color(0xfff0efe9)),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSel ? primary : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSel
                  ? primary
                  : (isDark
                        ? const Color(0xffc2c8c0)
                        : const Color(0xff615e56)),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 11,
                fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                color: isSel
                    ? primary
                    : (isDark
                          ? const Color(0xffc2c8c0)
                          : const Color(0xff615e56)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

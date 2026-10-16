import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../music/models/soulful_track.dart';
import '../../../music/services/soulful_music_service.dart';

class SoundBathModal extends StatefulWidget {
  const SoundBathModal({super.key});

  @override
  State<SoundBathModal> createState() => _SoundBathModalState();
}

class _SoundBathModalState extends State<SoundBathModal> {
  final SoulfulMusicService _musicService = SoulfulMusicService();
  final List<StreamSubscription> _subs = [];

  SoulfulTrack? _activeTrack;
  PlayerState _playerState = PlayerState.stopped;

  Timer? _sleepTimer;
  int? _sleepTimerMinutes;

  @override
  void initState() {
    super.initState();
    _activeTrack =
        _musicService.currentTrack ??
        SoulfulMusicService.curatedTracks[1]; // Zen Singing bowl default
    _playerState = _musicService.playerState;

    _subs.add(
      _musicService.currentTrackStream.listen((track) {
        if (track != null && mounted) {
          setState(() {
            _activeTrack = track;
          });
        }
      }),
    );

    _subs.add(
      _musicService.playerStateStream.listen((st) {
        if (mounted) setState(() => _playerState = st);
      }),
    );
  }

  @override
  void dispose() {
    for (final s in _subs) {
      s.cancel();
    }
    _sleepTimer?.cancel();
    super.dispose();
  }

  void _togglePlay(SoulfulTrack track) {
    HapticFeedback.mediumImpact();
    if (_activeTrack?.id == track.id && _playerState == PlayerState.playing) {
      _musicService.pause();
    } else {
      _musicService.playTrack(track);
    }
  }

  void _setSleepTimer(int minutes) {
    HapticFeedback.selectionClick();
    _sleepTimer?.cancel();
    setState(() {
      _sleepTimerMinutes = minutes;
    });

    _sleepTimer = Timer(Duration(minutes: minutes), () {
      if (mounted) {
        _musicService.pause();
        HapticFeedback.heavyImpact();
        setState(() {
          _sleepTimerMinutes = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sound bath sleep timer ended. Sweet dreams.'),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? const Color(0xffb0ceb2)
        : const Color(0xff8ba88e);
    final cardBg = isDark ? const Color(0xff1e201e) : const Color(0xffffffff);
    final tracks = SoulfulMusicService.curatedTracks;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Drag handle
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xff424842)
                        : const Color(0xffdbdad7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.graphic_eq_rounded,
                        color: primaryColor,
                        size: 26,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Ambient Sound Bath',
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
              const SizedBox(height: 8),

              Text(
                'Organic soundscapes for meditation, deep work, or falling asleep.',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 13,
                  color: isDark
                      ? const Color(0xffc2c8c0).withValues(alpha: 0.6)
                      : const Color(0xff615e56).withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),

              // Sleep timer bar
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                child: Row(
                  children: [
                    Icon(Icons.bedtime_rounded, size: 16, color: primaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'Sleep Timer:',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    ...[5, 15, 30, 45].map((mins) {
                      final isSel = _sleepTimerMinutes == mins;
                      return Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: InkWell(
                          onTap: () => _setSleepTimer(mins),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
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
                                fontSize: 11,
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
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Soundscape track list
              Expanded(
                child: ListView.separated(
                  itemCount: tracks.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, idx) {
                    final track = tracks[idx];
                    final isCurrent = _activeTrack?.id == track.id;
                    final isThisPlaying =
                        isCurrent && _playerState == PlayerState.playing;

                    return InkWell(
                      onTap: () => _togglePlay(track),
                      borderRadius: BorderRadius.circular(16),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isCurrent
                              ? primaryColor.withValues(alpha: 0.12)
                              : (isDark
                                    ? const Color(
                                        0xff2a2d2a,
                                      ).withValues(alpha: 0.5)
                                    : const Color(0xfff5f4ef)),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isCurrent
                                ? primaryColor
                                : Colors.transparent,
                            width: 1.2,
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isThisPlaying
                                    ? primaryColor
                                    : primaryColor.withValues(alpha: 0.15),
                              ),
                              child: Icon(
                                isThisPlaying
                                    ? Icons.pause_rounded
                                    : Icons.play_arrow_rounded,
                                color: isThisPlaying
                                    ? (isDark
                                          ? const Color(0xff1c3622)
                                          : Colors.white)
                                    : primaryColor,
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    track.title,
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: isDark
                                          ? Colors.white
                                          : Colors.black,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    track.category,
                                    style: TextStyle(
                                      fontFamily: 'Hanken Grotesk',
                                      fontSize: 11,
                                      color: primaryColor,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${track.durationSeconds ~/ 60}:${(track.durationSeconds % 60).toString().padLeft(2, '0')}',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 12,
                                color: isDark
                                    ? const Color(
                                        0xffc2c8c0,
                                      ).withValues(alpha: 0.5)
                                    : const Color(
                                        0xff615e56,
                                      ).withValues(alpha: 0.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

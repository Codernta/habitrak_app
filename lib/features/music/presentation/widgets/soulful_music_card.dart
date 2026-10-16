import 'dart:async';
import 'dart:ui' as ui;
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitrak/core/animations/pressable_scale.dart';
import 'package:habitrak/core/services/connectivity_service.dart';
import 'package:habitrak/core/theme/app_theme.dart';
import 'package:habitrak/core/widgets/offline_status_sheet.dart';
import 'package:habitrak/features/music/models/soulful_track.dart';
import 'package:habitrak/features/music/services/soulful_music_service.dart';
import 'music_search_sheet.dart';
import 'waveform_visualizer.dart';

/// The centerpiece card on the Home Screen displaying "Today's Soulful Music"
/// with built-in playback, waveform animation, and free music search.
class SoulfulMusicCard extends StatefulWidget {
  const SoulfulMusicCard({super.key});

  @override
  State<SoulfulMusicCard> createState() => _SoulfulMusicCardState();
}

class _SoulfulMusicCardState extends State<SoulfulMusicCard> {
  final SoulfulMusicService _musicService = SoulfulMusicService();
  final ConnectivityService _connectivityService = ConnectivityService();

  late SoulfulTrack _activeTrack;
  PlayerState _playerState = PlayerState.stopped;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isOnline = true;
  bool _isLooping = false;

  final List<StreamSubscription> _subscriptions = [];

  @override
  void initState() {
    super.initState();
    _activeTrack = _musicService.currentTrack ?? _musicService.getTodaysTrack();
    _playerState = _musicService.playerState;
    _position = _musicService.position;
    _duration = Duration(seconds: _activeTrack.durationSeconds);
    _isOnline = _connectivityService.isOnline;

    _subscriptions.add(
      _musicService.currentTrackStream.listen((track) {
        if (track != null && mounted) {
          setState(() {
            _activeTrack = track;
            _duration = Duration(seconds: track.durationSeconds);
          });
        }
      }),
    );

    _subscriptions.add(
      _musicService.playerStateStream.listen((state) {
        if (mounted) setState(() => _playerState = state);
      }),
    );

    _subscriptions.add(
      _musicService.positionStream.listen((pos) {
        if (mounted) setState(() => _position = pos);
      }),
    );

    _subscriptions.add(
      _musicService.durationStream.listen((dur) {
        if (mounted && dur > Duration.zero) {
          setState(() => _duration = dur);
        }
      }),
    );

    _subscriptions.add(
      _connectivityService.isOnlineStream.listen((online) {
        if (mounted) setState(() => _isOnline = online);
      }),
    );
  }

  @override
  void dispose() {
    for (final sub in _subscriptions) {
      sub.cancel();
    }
    super.dispose();
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _onTogglePlayPause() {
    HapticFeedback.mediumImpact();
    _musicService.togglePlayPause(_activeTrack);
  }

  void _onNextTrack() {
    HapticFeedback.lightImpact();
    final next = _musicService.getNextTrack(_activeTrack);
    setState(() {
      _activeTrack = next;
      _duration = Duration(seconds: next.durationSeconds);
      _position = Duration.zero;
    });
    _musicService.playTrack(next);
  }

  void _onOpenSearch() {
    HapticFeedback.lightImpact();
    MusicSearchSheet.show(
      context,
      onTrackSelected: (selectedTrack) {
        setState(() {
          _activeTrack = selectedTrack;
          _duration = Duration(seconds: selectedTrack.durationSeconds);
          _position = Duration.zero;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark
        ? AppColors.darkPrimary
        : AppColors.lightPrimary;
    final isPlaying = _playerState == PlayerState.playing;

    final maxSeconds = _duration.inSeconds > 0
        ? _duration.inSeconds.toDouble()
        : _activeTrack.durationSeconds.toDouble();
    final currentSeconds = _position.inSeconds.toDouble().clamp(
      0.0,
      maxSeconds,
    );

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                (isDark ? const Color(0xff1f2620) : const Color(0xfff4f9f4))
                    .withValues(alpha: 0.85),
                (isDark ? const Color(0xff181d18) : const Color(0xffeef5ee))
                    .withValues(alpha: 0.70),
              ],
            ),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : primaryColor.withValues(alpha: 0.25),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: primaryColor.withValues(alpha: isDark ? 0.05 : 0.08),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Top Section: Header & Controls
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color:
                          (isDark
                                  ? AppColors.darkPrimaryContainer
                                  : AppColors.lightPrimaryContainer)
                              .withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.self_improvement_rounded,
                      color: primaryColor,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "TODAY'S SOULFUL MUSIC",
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.4,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Yoga & Meditation • 1–5 Mins',
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Search / Discover Button
                  PressableScale(
                    onTap: _onOpenSearch,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black)
                            .withValues(alpha: 0.06),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (isDark ? Colors.white : Colors.black)
                              .withValues(alpha: 0.08),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.search_rounded,
                            size: 14,
                            color: primaryColor,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Explore',
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDark
                                  ? AppColors.darkOnSurface
                                  : AppColors.lightOnSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Track Title & Category Chips
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _activeTrack.title,
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isDark
                                ? AppColors.darkOnSurface
                                : AppColors.lightOnSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${_activeTrack.artist} • ${_activeTrack.category}',
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 12,
                            color: isDark
                                ? AppColors.darkOnSurfaceVariant
                                : AppColors.lightOnSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Offline Indicator or Free Badge
                  if (!_isOnline)
                    GestureDetector(
                      onTap: () => OfflineStatusSheet.show(context),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                              (isDark
                                      ? AppColors.darkTertiary
                                      : const Color(0xffd9777f))
                                  .withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color:
                                (isDark
                                        ? AppColors.darkTertiary
                                        : const Color(0xffd9777f))
                                    .withValues(alpha: 0.4),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.wifi_off_rounded,
                              size: 12,
                              color: Color(0xffd9777f),
                            ),
                            SizedBox(width: 4),
                            Text(
                              'Offline',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: Color(0xffd9777f),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '100% Free',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: primaryColor,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Waveform Visualizer
              WaveformVisualizer(
                isPlaying: isPlaying,
                barCount: 22,
                height: 28,
              ),
              const SizedBox(height: 10),

              // Seek Slider
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  trackHeight: 4,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 6,
                  ),
                  overlayShape: const RoundSliderOverlayShape(
                    overlayRadius: 12,
                  ),
                  activeTrackColor: primaryColor,
                  inactiveTrackColor: (isDark ? Colors.white : Colors.black)
                      .withValues(alpha: 0.1),
                  thumbColor: primaryColor,
                ),
                child: Slider(
                  value: currentSeconds,
                  max: maxSeconds > 0 ? maxSeconds : 1.0,
                  onChanged: (val) {
                    _musicService.seek(Duration(seconds: val.round()));
                  },
                ),
              ),

              // Time labels
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _formatDuration(_position),
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                    Text(
                      _formatDuration(_duration),
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 11,
                        color: isDark
                            ? AppColors.darkOnSurfaceVariant
                            : AppColors.lightOnSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Playback Actions Row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Loop Toggle
                  IconButton(
                    icon: Icon(
                      _isLooping
                          ? Icons.repeat_one_rounded
                          : Icons.repeat_rounded,
                      size: 20,
                      color: _isLooping
                          ? primaryColor
                          : (isDark
                                ? AppColors.darkOutline
                                : AppColors.lightOutline),
                    ),
                    tooltip: 'Repeat Track',
                    onPressed: () {
                      HapticFeedback.selectionClick();
                      setState(() => _isLooping = !_isLooping);
                      _musicService.player.setReleaseMode(
                        _isLooping ? ReleaseMode.loop : ReleaseMode.release,
                      );
                    },
                  ),
                  const SizedBox(width: 16),

                  // Big Center Play/Pause Button
                  PressableScale(
                    onTap: _onTogglePlayPause,
                    child: Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        isPlaying
                            ? Icons.pause_rounded
                            : Icons.play_arrow_rounded,
                        color: isDark ? AppColors.darkOnPrimary : Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Next Track / Shuffle Button
                  IconButton(
                    icon: const Icon(Icons.skip_next_rounded, size: 24),
                    tooltip: 'Next Soulful Track',
                    color: isDark
                        ? AppColors.darkOnSurface
                        : AppColors.lightOnSurface,
                    onPressed: _onNextTrack,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:habitrak/core/animations/pressable_scale.dart';
import 'package:habitrak/core/services/notification_service.dart';
import '../../data/repositories/mindful_puzzle_repository.dart';

class MindfulGardenPuzzlePage extends StatefulWidget {
  final MindfulPuzzleRepository? repository;
  final bool showBottomNav;

  const MindfulGardenPuzzlePage({
    super.key,
    this.repository,
    this.showBottomNav = false,
  });

  @override
  State<MindfulGardenPuzzlePage> createState() =>
      _MindfulGardenPuzzlePageState();
}

class _MindfulGardenPuzzlePageState extends State<MindfulGardenPuzzlePage>
    with TickerProviderStateMixin {
  late MindfulPuzzleRepository _puzzleRepo;
  late AudioPlayer _audioPlayer;

  bool _isPlayingAudio = false;
  late AnimationController _equalizerController;
  late AnimationController _celebrationController;

  // Track newly placed piece for animated feedback
  int? _recentlyPlacedPiece;

  @override
  void initState() {
    super.initState();
    _puzzleRepo = widget.repository ?? MindfulPuzzleRepository();
    _puzzleRepo.addListener(_onRepoChanged);

    _audioPlayer = AudioPlayer();
    _audioPlayer.setReleaseMode(ReleaseMode.loop);

    _equalizerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _celebrationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    // Initial streak check to schedule notifications if needed
    _puzzleRepo.checkStreakAndNotify();
  }

  void _onRepoChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  @override
  void dispose() {
    _puzzleRepo.removeListener(_onRepoChanged);
    _equalizerController.dispose();
    _celebrationController.dispose();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _toggleAudio() async {
    HapticFeedback.lightImpact();
    try {
      if (_isPlayingAudio) {
        await _audioPlayer.pause();
        _equalizerController.stop();
        setState(() {
          _isPlayingAudio = false;
        });
      } else {
        await _audioPlayer.play(AssetSource('audio/rain_bamboo.wav'));
        _equalizerController.repeat(reverse: true);
        setState(() {
          _isPlayingAudio = true;
        });
      }
    } catch (e) {
      debugPrint('Audio error: $e');
      // Graceful fallback: toggle visual equalizer state
      setState(() {
        _isPlayingAudio = !_isPlayingAudio;
        if (_isPlayingAudio) {
          _equalizerController.repeat(reverse: true);
        } else {
          _equalizerController.stop();
        }
      });
    }
  }

  Future<void> _handlePlacePiece(int pieceIndex) async {
    if (_puzzleRepo.isPiecePlaced(pieceIndex)) return;

    HapticFeedback.mediumImpact();
    setState(() {
      _recentlyPlacedPiece = pieceIndex;
    });

    final success = await _puzzleRepo.placePiece(pieceIndex);
    if (success && mounted) {
      if (_puzzleRepo.isGardenFullyHarmonized) {
        HapticFeedback.heavyImpact();
        _showHarmonizedCelebration();
      }
    }
  }

  Future<void> _handleHarmonizeNext() async {
    HapticFeedback.mediumImpact();
    final nextIndex = await _puzzleRepo.harmonizeNextPiece();
    if (nextIndex != null && mounted) {
      setState(() {
        _recentlyPlacedPiece = nextIndex;
      });

      if (_puzzleRepo.isGardenFullyHarmonized) {
        HapticFeedback.heavyImpact();
        _showHarmonizedCelebration();
      }
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✨ Garden is already fully harmonized in peace!'),
          backgroundColor: Color(0xFF38573E),
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  void _showHarmonizedCelebration() {
    _celebrationController.forward(from: 0.0);
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.all(26),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E221E) : Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF38573E).withValues(alpha: 0.25),
                  blurRadius: 32,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: Color(0xFFD6E9D7),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.spa_rounded,
                      color: Color(0xFF285432),
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Garden Harmonized!',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E201E),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Your mindful pause restored serenity. Day ${_puzzleRepo.dayNumber} Zen Mosaic completed.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 14,
                    color: isDark ? Colors.white70 : const Color(0xFF6E736E),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF282D28)
                        : const Color(0xFFF3F7F3),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.local_fire_department_rounded,
                            color: Color(0xFFD97706),
                            size: 22,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${_puzzleRepo.streak} Day Streak',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 24,
                        color: Colors.grey.withValues(alpha: 0.3),
                      ),
                      Row(
                        children: const [
                          Icon(
                            Icons.energy_savings_leaf_rounded,
                            color: Color(0xFF2E7D32),
                            size: 22,
                          ),
                          SizedBox(width: 6),
                          Text(
                            '+15 Vitality',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: Color(0xFF2E7D32),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _puzzleRepo.resetPuzzle(advanceDay: false);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: const BorderSide(color: Color(0xFF38573E)),
                        ),
                        child: const Text(
                          'Replay',
                          style: TextStyle(
                            color: Color(0xFF38573E),
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pop(context);
                          _puzzleRepo.resetPuzzle(advanceDay: true);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF38573E),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: const Text(
                          'Next Day',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showPeekOriginalModal() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1C1A) : Colors.white,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(32),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Original Zen Garden',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1E201E),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: AspectRatio(
                    aspectRatio: 1.0,
                    child: Image.asset(
                      'assets/images/puzzle/full_garden_original.jpg',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  '🌸 Harmonized Tranquility • Day ${_puzzleRepo.dayNumber} Reference',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white70 : const Color(0xFF545954),
                  ),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF38573E),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: const Text(
                    'Return to Puzzle',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showZenMenuSheet() {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E201E) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.withValues(alpha: 0.3),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Mindful Garden Options',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6E9D7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.notifications_active_outlined,
                    color: Color(0xFF285432),
                  ),
                ),
                title: const Text(
                  'Test Cool Streak Notification',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text(
                  'Shows notification with Habitrak logo and cool phrasing',
                ),
                onTap: () async {
                  Navigator.pop(context);
                  await NotificationService().showTestStreakNotification(
                    streak: _puzzleRepo.streak,
                  );
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          '🔔 Cool Streak Notification sent with App Logo!',
                        ),
                        backgroundColor: Color(0xFF38573E),
                      ),
                    );
                  }
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3ECE2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.refresh_rounded,
                    color: Color(0xFF6B4E2B),
                  ),
                ),
                title: const Text(
                  'Reset Garden Mosaic',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: const Text('Return to initial 7/9 pieces state'),
                onTap: () {
                  Navigator.pop(context);
                  _puzzleRepo.resetPuzzle(advanceDay: false);
                  HapticFeedback.lightImpact();
                },
              ),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE1F0F7),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    color: Color(0xFF4A8CA8),
                  ),
                ),
                title: const Text(
                  '432Hz Soundscape',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Text(
                  _isPlayingAudio ? 'Currently Playing' : 'Paused',
                ),
                trailing: Switch(
                  value: _isPlayingAudio,
                  activeThumbColor: const Color(0xFF38573E),
                  onChanged: (val) {
                    _toggleAudio();
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF141714)
        : const Color(0xFFF6F3ED); // exact zen background tone

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              _buildTopBar(isDark),
              const SizedBox(height: 16),
              _buildTagsRow(isDark),
              const SizedBox(height: 16),
              _buildHeader(isDark),
              const SizedBox(height: 16),
              _buildAudioPlayerCard(isDark),
              const SizedBox(height: 20),
              _buildHarmonizationProgressRow(isDark),
              const SizedBox(height: 16),
              _build3x3PuzzleGrid(isDark),
              const SizedBox(height: 24),
              _buildMindfulStonesTray(isDark),
              const SizedBox(height: 20),
              _buildMindfulIntentionCard(isDark),
              const SizedBox(height: 22),
              _buildHarmonizeActionButton(isDark),
              const SizedBox(height: 12),
              _buildFooterCaption(isDark),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTopBar(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        PressableScale(
          onTap: _showZenMenuSheet,
          child: Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF222622) : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.menu_rounded,
              size: 28,
              color: isDark ? Colors.white : const Color(0xFF2E382E),
            ),
          ),
        ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo.png',
              height: 28,
              width: 28,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const Icon(
                Icons.spa_rounded,
                color: Color(0xFF38573E),
                size: 26,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Habitrak',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 21,
                fontWeight: FontWeight.bold,
                letterSpacing: -0.3,
                color: isDark ? Colors.white : const Color(0xFF233626),
              ),
            ),
          ],
        ),
        PressableScale(
          onTap: _showZenMenuSheet,
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF6B8A6E), width: 2),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: ClipOval(
              child: Image.asset(
                'assets/icon.jpg',
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(
                  Icons.person,
                  color: Color(0xFF38573E),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTagsRow(bool isDark) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFD6E9D7), // exact sage tint
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.eco_rounded,
                size: 15,
                color: Color(0xFF285432),
              ),
              const SizedBox(width: 6),
              Text(
                'Day ${_puzzleRepo.dayNumber} • Zen Mosaic',
                style: const TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF285432),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: const Color(0xFFF5EBE1), // exact warm tint
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.local_fire_department_rounded,
                size: 15,
                color: Color(0xFF7A4F23),
              ),
              const SizedBox(width: 6),
              Text(
                '${_puzzleRepo.streak} Day Streak',
                style: const TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 12.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF6B4E2B),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mindful Garden Puzzle',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 27,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.4,
            color: isDark ? Colors.white : const Color(0xFF1E201E),
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Assemble tranquil moments to restore focus & calm.',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 14.5,
            color: isDark ? Colors.white70 : const Color(0xFF5E655E),
            height: 1.3,
          ),
        ),
      ],
    );
  }

  Widget _buildAudioPlayerCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E221E) : Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE9E5DD),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
              color: Color(0xFFDDF0F7),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: AnimatedBuilder(
                animation: _equalizerController,
                builder: (context, child) {
                  return Icon(
                    _isPlayingAudio
                        ? Icons.graphic_eq_rounded
                        : Icons.headphones_rounded,
                    color: const Color(0xFF387A99),
                    size: 22,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Rain & Bamboo Whispers',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E201E),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Binaural 432Hz • Soft Focus',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 12.5,
                    color: isDark ? Colors.white60 : const Color(0xFF7A807A),
                  ),
                ),
              ],
            ),
          ),
          PressableScale(
            onTap: _toggleAudio,
            child: Container(
              padding: const EdgeInsets.all(6),
              child: Icon(
                _isPlayingAudio
                    ? Icons.pause_circle_outline_rounded
                    : Icons.play_circle_outline_rounded,
                size: 34,
                color: isDark ? Colors.white70 : const Color(0xFF38573E),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHarmonizationProgressRow(bool isDark) {
    final count = _puzzleRepo.harmonizedCount;
    final percentage = _puzzleRepo.harmonizedPercentage.toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  '$count / 9 Harmonized',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : const Color(0xFF1E201E),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD6E9D7),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 11.5,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF285432),
                    ),
                  ),
                ),
              ],
            ),
            PressableScale(
              onTap: _showPeekOriginalModal,
              child: Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 17,
                    color: isDark ? Colors.white70 : const Color(0xFF4A5C4D),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    'Peek Original',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF4A5C4D),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 6,
            color: isDark ? const Color(0xFF2C332C) : const Color(0xFFDEE8DE),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: count / 9.0,
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF38573E),
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _build3x3PuzzleGrid(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1B1E1B) : const Color(0xFFEEEBE2),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : const Color(0xFFE2DDD2),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _buildTile(0, isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildTile(1, isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildTile(2, isDark)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTile(3, isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildSlotOrTile(4, 'Tap Piece 1', 1, isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildTile(5, isDark)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildTile(6, isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildSlotOrTile(7, 'Tap Piece 2', 2, isDark)),
              const SizedBox(width: 8),
              Expanded(child: _buildTile(8, isDark)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTile(int index, bool isDark) {
    final imageNames = [
      'tile_0_maple.jpg',
      'tile_1_cherry.jpg',
      'tile_2_misty_garden.jpg',
      'tile_3_sand_path.jpg',
      'tile_4_center_blossom.jpg',
      'tile_5_stacked_stones.jpg',
      'tile_6_fern_moss.jpg',
      'tile_7_stone_ripples.jpg',
      'tile_8_sand_waves.jpg',
    ];

    final isHighlighted = _recentlyPlacedPiece == index;

    return AspectRatio(
      aspectRatio: 1.0,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOutBack,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighlighted
                ? const Color(0xFF38573E)
                : Colors.white.withValues(alpha: 0.4),
            width: isHighlighted ? 2.5 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(15),
          child: Image.asset(
            'assets/images/puzzle/${imageNames[index]}',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: const Color(0xFFCAD8CB),
              child: const Icon(Icons.spa, color: Color(0xFF38573E)),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSlotOrTile(
    int index,
    String tapLabel,
    int slotNumber,
    bool isDark,
  ) {
    final isPlaced = _puzzleRepo.isPiecePlaced(index);

    if (isPlaced) {
      return _buildTile(index, isDark);
    }

    return AspectRatio(
      aspectRatio: 1.0,
      child: PressableScale(
        onTap: () => _handlePlacePiece(index),
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF242824) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF38573E).withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.04),
                blurRadius: 6,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                slotNumber == 1
                    ? Icons.filter_vintage_outlined
                    : Icons.eco_outlined,
                color: const Color(0xFF38573E),
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                tapLabel,
                style: const TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 11.5,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF38573E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMindfulStonesTray(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Mindful Stones Tray',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 16.5,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : const Color(0xFF1E201E),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Tap pieces to place into harmony',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 12,
                color: isDark ? Colors.white54 : const Color(0xFF7A807A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildTrayCard(
                pieceIndex: 4,
                badgeText: '#1',
                title: 'Center Blossom',
                imagePath: 'assets/images/puzzle/tile_4_center_blossom.jpg',
                isDark: isDark,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _buildTrayCard(
                pieceIndex: 7,
                badgeText: '#2',
                title: 'Stone Ripples',
                imagePath: 'assets/images/puzzle/tile_7_stone_ripples.jpg',
                isDark: isDark,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTrayCard({
    required int pieceIndex,
    required String badgeText,
    required String title,
    required String imagePath,
    required bool isDark,
  }) {
    final isPlaced = _puzzleRepo.isPiecePlaced(pieceIndex);

    return PressableScale(
      onTap: isPlaced ? null : () => _handlePlacePiece(pieceIndex),
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 300),
        opacity: isPlaced ? 0.45 : 1.0,
        child: Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E221E) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.08)
                  : const Color(0xFFE9E5DD),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(14),
                      child: AspectRatio(
                        aspectRatio: 1.05,
                        child: Image.asset(imagePath, fit: BoxFit.cover),
                      ),
                    ),
                    Positioned(
                      bottom: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 7,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.92),
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.15),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Text(
                          badgeText,
                          style: const TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E382E),
                          ),
                        ),
                      ),
                    ),
                    if (isPlaced)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Center(
                            child: Icon(
                              Icons.check_circle_rounded,
                              color: Colors.white,
                              size: 32,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.only(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  top: 2,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 13.5,
                          fontWeight: FontWeight.bold,
                          color: isDark
                              ? Colors.white
                              : const Color(0xFF1E201E),
                        ),
                      ),
                    ),
                    Icon(
                      isPlaced
                          ? Icons.check_rounded
                          : Icons.add_circle_outline_rounded,
                      size: 20,
                      color: isPlaced
                          ? Colors.grey
                          : const Color(0xFF38573E),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMindfulIntentionCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E221E) : const Color(0xFFFBF8F3),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFEFECE5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF2B302B)
                      : const Color(0xFFE9E5DC),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Center(
                  child: Icon(
                    Icons.format_quote_rounded,
                    size: 22,
                    color: Color(0xFF4A544A),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MINDFUL INTENTION',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.8,
                        color: isDark
                            ? Colors.white60
                            : const Color(0xFF6B736B),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '“Patience is the calm acceptance that things happen in a different order than the one you have in your mind.”',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 14.5,
                        fontStyle: FontStyle.italic,
                        height: 1.4,
                        color: isDark
                            ? Colors.white.withValues(alpha: 0.9)
                            : const Color(0xFF2A2D2A),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Divider(
            color: Colors.grey.withValues(alpha: 0.15),
            height: 1,
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: const BoxDecoration(
                      color: Color(0xFFD6E9D7),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volume_up_rounded,
                      size: 14,
                      color: Color(0xFF285432),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Unlocks: Bamboo Wind Chime Audio',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white70 : const Color(0xFF384338),
                    ),
                  ),
                ],
              ),
              Text(
                '+15 Vitality',
                style: const TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF2E6B39),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHarmonizeActionButton(bool isDark) {
    return PressableScale(
      onTap: _handleHarmonizeNext,
      child: Container(
        height: 56,
        decoration: BoxDecoration(
          color: const Color(0xFF38573E), // rich forest zen green
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF38573E).withValues(alpha: 0.35),
              blurRadius: 16,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: const [
            Icon(
              Icons.psychology_alt_outlined,
              color: Colors.white,
              size: 22,
            ),
            SizedBox(width: 10),
            Text(
              'Harmonize Next Piece',
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooterCaption(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.menu_book_rounded,
          size: 15,
          color: isDark ? Colors.white54 : const Color(0xFF7A807A),
        ),
        const SizedBox(width: 6),
        Text(
          'Habitrak Mindful Moment • Take your time',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 12.5,
            color: isDark ? Colors.white54 : const Color(0xFF7A807A),
          ),
        ),
      ],
    );
  }
}

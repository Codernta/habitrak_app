import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitrak/core/animations/app_animations.dart';
import 'package:habitrak/core/animations/staggered_entrance.dart';

class WalkTrackerPage extends StatefulWidget {
  const WalkTrackerPage({super.key});

  @override
  State<WalkTrackerPage> createState() => _WalkTrackerPageState();
}

class _WalkTrackerPageState extends State<WalkTrackerPage> with TickerProviderStateMixin {
  bool _isMusicMode = true;
  bool _isPlaying = true;
  int _currentPromptIndex = 0;

  late AnimationController _pulseController;

  final List<String> _conversationPrompts = [
    'What was the high point and low point of your day so far?',
    'Name three simple things that brought you unexpected joy today.',
    'If you could master any skill or hobby instantly, what would it be?',
    'What is an interesting article, book, or podcast you consumed recently?',
    'Describe your ideal morning routine if time and money were no object.',
  ];

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    if (_isPlaying) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _nextPrompt() {
    setState(() {
      _currentPromptIndex = (_currentPromptIndex + 1) % _conversationPrompts.length;
    });
  }

  Widget _buildEqualizer(Color color) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, child) {
        return SizedBox(
          width: 20,
          height: 20,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildBar(_pulseController.value, 0.0, 0.9, color),
              _buildBar(_pulseController.value, 0.3, 0.5, color),
              _buildBar(_pulseController.value, 0.6, 0.8, color),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBar(double animationValue, double offset, double multiplier, Color color) {
    final scale = ((animationValue + offset) % 1.0 - 0.5).abs() * 2.0;
    final height = 4.0 + (scale * 12.0 * multiplier);
    return Container(
      width: 3,
      height: height,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(1.5),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e);
    final cardBg = isDark ? const Color(0xff1e201e) : const Color(0xffffffff);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Walk Tracker',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            StaggeredEntrance(index: 0, child: _buildReadouts(isDark)),
            const SizedBox(height: 28),
            StaggeredEntrance(index: 1, child: _buildModeSelector(isDark)),
            const SizedBox(height: 28),
            StaggeredEntrance(
              index: 2,
              child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 400),
              switchInCurve: Curves.easeOutBack,
              switchOutCurve: Curves.easeIn,
              transitionBuilder: (child, animation) {
                return FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: Offset(_isMusicMode ? -0.05 : 0.05, 0),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                );
              },
              child: _isMusicMode ? _buildMusicModeCard(isDark) : _buildSocialModeCard(isDark),
            ),
            ),
            const SizedBox(height: 32),
            StaggeredEntrance(
              index: 3,
              child: ElevatedButton(
              onPressed: () {
                HapticFeedback.heavyImpact();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Walk Session completed & logged!')),
                );
                Navigator.of(context).pop();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xffba1a1a),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.stop_rounded),
                  SizedBox(width: 8),
                  Text(
                    'End Session',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                  ),
                ],
              ),
            ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildReadouts(bool isDark) {
    final textColor = isDark ? const Color(0xffe2e3df) : const Color(0xff2f312f);
    final labelColor = isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.5) : const Color(0xff615e56).withValues(alpha: 0.6);

    return TweenAnimationBuilder<double>(
      duration: const Duration(milliseconds: 600),
      curve: Curves.easeOutBack,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, (1 - value) * 15),
          child: Opacity(
            opacity: AppAnimations.clampOpacity(value),
            child: child,
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xff1a1c1a) : const Color(0xfff2f1ee),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildStatColumn('Time', '24:18', textColor, labelColor),
            Container(width: 1, height: 40, color: labelColor.withValues(alpha: 0.2)),
            _buildStatColumn('Pace', '12\'45"', textColor, labelColor),
            Container(width: 1, height: 40, color: labelColor.withValues(alpha: 0.2)),
            _buildStatColumn('Distance', '1.8km', textColor, labelColor),
          ],
        ),
      ),
    );
  }

  Widget _buildStatColumn(String label, String value, Color textColor, Color labelColor) {
    return Column(
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 10,
            fontWeight: FontWeight.bold,
            letterSpacing: 1.5,
            color: labelColor,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildModeSelector(bool isDark) {
    final activeColor = isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e);
    final inactiveTextColor = isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.6) : const Color(0xff615e56).withValues(alpha: 0.6);

    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff1a1c1a) : const Color(0xfff2f1ee),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(4),
      child: Stack(
        children: [
          // Sliding Pill background
          AnimatedAlign(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOutBack,
            alignment: _isMusicMode ? Alignment.centerLeft : Alignment.centerRight,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              child: Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff1e201e) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
              ),
            ),
          ),
          // Interactive Text buttons on top
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isMusicMode = true);
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.music_note,
                          color: _isMusicMode ? activeColor : inactiveTextColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Music',
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontWeight: FontWeight.bold,
                            color: _isMusicMode ? activeColor : inactiveTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _isMusicMode = false);
                  },
                  child: Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.group,
                          color: !_isMusicMode ? activeColor : inactiveTextColor,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Social',
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontWeight: FontWeight.bold,
                            color: !_isMusicMode ? activeColor : inactiveTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMusicModeCard(bool isDark) {
    final primaryColor = isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e);
    final cardColor = isDark ? const Color(0xff1e201e) : const Color(0xffffffff);

    return Container(
      key: const ValueKey('music'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xff424842).withValues(alpha: 0.1) : const Color(0xffdbdad7).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xff292a28) : const Color(0xffefeeeb),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.music_note, color: primaryColor, size: 30),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Evening Flow Mix',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isDark ? const Color(0xffe2e3df) : const Color(0xff2f312f),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Solstice Echoes',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 13,
                        color: isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.6) : const Color(0xff615e56).withValues(alpha: 0.6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Player Controls
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.skip_previous),
                onPressed: () {
                  HapticFeedback.lightImpact();
                },
                color: isDark ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 16),
              Stack(
                alignment: Alignment.center,
                children: [
                  if (_isPlaying)
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 40 + (_pulseController.value * 24),
                          height: 40 + (_pulseController.value * 24),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: primaryColor.withValues(alpha: 0.3 * (1.0 - _pulseController.value)),
                          ),
                        );
                      },
                    ),
                  FloatingActionButton(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _isPlaying = !_isPlaying;
                        if (_isPlaying) {
                          _pulseController.repeat(reverse: true);
                        } else {
                          _pulseController.stop();
                        }
                      });
                    },
                    backgroundColor: primaryColor,
                    foregroundColor: isDark ? const Color(0xff1c3622) : Colors.white,
                    mini: true,
                    elevation: 2,
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
                      child: Icon(
                        _isPlaying ? Icons.pause : Icons.play_arrow,
                        key: ValueKey(_isPlaying),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: const Icon(Icons.skip_next),
                onPressed: () {
                  HapticFeedback.lightImpact();
                },
                color: isDark ? Colors.white : Colors.black,
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress bar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '1:42',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.5) : const Color(0xff615e56).withValues(alpha: 0.5),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(2),
                    child: LinearProgressIndicator(
                      value: 0.35,
                      backgroundColor: isDark ? const Color(0xff1a1c1a) : const Color(0xffefeeeb),
                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    ),
                  ),
                ),
              ),
              Text(
                '4:55',
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.5) : const Color(0xff615e56).withValues(alpha: 0.5),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Stat Indicators
          Row(
            children: [
              Expanded(
                child: _buildAudioStat(Icons.speed, 'BPM MATCH', '112', primaryColor, isDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAudioStat(Icons.equalizer, 'SYNC STATUS', 'Active', primaryColor, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAudioStat(IconData icon, String title, String val, Color primary, bool isDark) {
    Widget leadWidget;
    if (icon == Icons.equalizer) {
      leadWidget = _isPlaying
          ? _buildEqualizer(primary)
          : Icon(icon, color: primary.withValues(alpha: 0.5), size: 20);
    } else {
      leadWidget = Icon(icon, color: primary, size: 20);
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff1a1c1a) : const Color(0xfff2f1ee),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          leadWidget,
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.5) : const Color(0xff615e56).withValues(alpha: 0.5),
                ),
              ),
              Text(
                val,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildSocialModeCard(bool isDark) {
    final primaryColor = isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e);
    final cardColor = isDark ? const Color(0xff1e201e) : const Color(0xffffffff);

    return Container(
      key: const ValueKey('social'),
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xff424842).withValues(alpha: 0.1) : const Color(0xffdbdad7).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Group Milestones',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xffe2e3df) : const Color(0xff2f312f),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.favorite, color: primaryColor, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      'Heart Rate Sync',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Collaborative prompt card
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff1a1c1a) : const Color(0xfff2f1ee),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline, color: Color(0xff8ba88e), size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Conversation Starter',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.5) : const Color(0xff615e56).withValues(alpha: 0.5),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Animated prompt switcher
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 450),
                  switchInCurve: Curves.easeOutBack,
                  switchOutCurve: Curves.easeIn,
                  transitionBuilder: (Widget child, Animation<double> animation) {
                    final isIncoming = child.key == ValueKey(_currentPromptIndex);
                    final slideOffset = isIncoming
                        ? Tween<Offset>(begin: const Offset(0.3, 0.0), end: Offset.zero)
                        : Tween<Offset>(begin: const Offset(-0.3, 0.0), end: Offset.zero);

                    return SlideTransition(
                      position: slideOffset.animate(animation),
                      child: FadeTransition(
                        opacity: animation,
                        child: child,
                      ),
                    );
                  },
                  child: Text(
                    _conversationPrompts[_currentPromptIndex],
                    key: ValueKey(_currentPromptIndex),
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : Colors.black,
                      height: 1.4,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton.icon(
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _nextPrompt();
                    },
                    icon: const Icon(Icons.refresh, size: 16, color: Color(0xff8ba88e)),
                    label: const Text(
                      'Next Prompt',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xff8ba88e)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          // Collaborative target progress bar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xff1a1c1a).withValues(alpha: 0.5) : const Color(0xfff2f1ee).withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Collaborative Goal',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white70 : Colors.black87,
                      ),
                    ),
                    Text(
                      '4.5km / 6.0km',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 11,
                        color: isDark ? const Color(0xffc2c8c0) : const Color(0xff615e56),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: 0.75,
                    backgroundColor: isDark ? const Color(0xff1a1c1a) : const Color(0xffefeeeb),
                    valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                    minHeight: 6,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

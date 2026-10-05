import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:habitrak/core/animations/app_animations.dart';
import 'package:habitrak/core/animations/staggered_entrance.dart';

class MindfulLivingPage extends StatefulWidget {
  const MindfulLivingPage({super.key});

  @override
  State<MindfulLivingPage> createState() => _MindfulLivingPageState();
}

class _MindfulLivingPageState extends State<MindfulLivingPage> {
  final TextEditingController _journalController = TextEditingController();
  final GlobalKey<AnimatedListState> _listKey = GlobalKey<AnimatedListState>();

  final List<Map<String, String>> _reflections = [
    {
      'date': 'Oct 24',
      'text': 'A quiet cup of tea in the morning before looking at any screens. Peaceful start.',
    },
    {
      'date': 'Oct 21',
      'text': '"A walk in the park reminded me that nature doesn\'t hurry, yet everything is accomplished."',
    },
  ];

  final List<Map<String, dynamic>> _intentionalGoals = [
    {'title': 'Morning breathwork (5 min)', 'completed': true},
    {'title': 'Read 10 pages for growth', 'completed': false},
    {'title': 'Evening tech detox', 'completed': false},
  ];

  @override
  void dispose() {
    _journalController.dispose();
    super.dispose();
  }

  void _saveReflection() {
    final text = _journalController.text.trim();
    if (text.isEmpty) return;

    HapticFeedback.mediumImpact();
    _reflections.insert(0, {
      'date': 'Today',
      'text': text,
    });
    _listKey.currentState?.insertItem(0, duration: const Duration(milliseconds: 500));
    _journalController.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gratitude entry saved!')),
    );
  }

  Widget _buildGoalCheckbox(bool isCompleted, Color primaryColor, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOutBack,
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: isCompleted ? primaryColor : Colors.transparent,
        border: Border.all(
          color: isCompleted ? primaryColor : (isDark ? const Color(0xff424842) : const Color(0xffa4a097)),
          width: 2,
        ),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 200),
        transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
        child: isCompleted
            ? const Icon(
                Icons.check,
                key: ValueKey('check'),
                size: 12,
                color: Colors.white,
              )
            : const SizedBox(key: ValueKey('empty')),
      ),
    );
  }

  Widget _buildReflectionItem(Map<String, String> ref, Animation<double> animation, Color primaryColor, bool isDark) {
    return SizeTransition(
      sizeFactor: animation,
      child: FadeTransition(
        opacity: animation,
        child: SlideTransition(
          position: Tween<Offset>(
            begin: const Offset(0.0, -0.2),
            end: Offset.zero,
          ).animate(CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack,
          )),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ref['date']!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  ref['text']!,
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 14,
                    color: isDark ? const Color(0xffc2c8c0) : const Color(0xff615e56),
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                Divider(color: primaryColor.withValues(alpha: 0.15), height: 1),
              ],
            ),
          ),
        ),
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
          'Mindful Living',
          style: TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryColor,
          ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 16, right: 16, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 10),
            StaggeredEntrance(index: 0, child: _buildGratitudeCard(isDark, primaryColor, cardBg)),
            const SizedBox(height: 24),
            StaggeredEntrance(index: 1, child: _buildGoalsCard(isDark, primaryColor, cardBg)),
            const SizedBox(height: 24),
            StaggeredEntrance(index: 2, child: _buildWellBeingCard(isDark, primaryColor, cardBg)),
            const SizedBox(height: 24),
            StaggeredEntrance(index: 3, child: _buildRecentReflections(isDark, primaryColor, cardBg)),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildGratitudeCard(bool isDark, Color primaryColor, Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
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
            children: [
              Icon(Icons.edit_note, color: primaryColor, size: 24),
              const SizedBox(width: 10),
              Text(
                'Daily Gratitude Journal',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Last entry: Yesterday, 9:15 PM',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.5) : const Color(0xff615e56).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: _journalController,
            maxLines: 3,
            style: TextStyle(color: isDark ? Colors.white : Colors.black, fontSize: 14),
            decoration: InputDecoration(
              hintText: 'What is one thing you are grateful for today?',
              hintStyle: TextStyle(
                color: isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.4) : const Color(0xff615e56).withValues(alpha: 0.4),
              ),
              filled: true,
              fillColor: isDark ? const Color(0xff1a1c1a) : const Color(0xfff2f1ee),
              border: OutlineInputBorder(
                borderSide: BorderSide.none,
                borderRadius: BorderRadius.circular(12),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: primaryColor, width: 1),
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _saveReflection,
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: isDark ? const Color(0xff1c3622) : Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 0,
            ),
            child: const Text(
              'SAVE ENTRY',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalsCard(bool isDark, Color primaryColor, Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
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
                'Intentional Goals',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.add, size: 20),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  // custom simple goal additions
                  setState(() {
                    _intentionalGoals.add({'title': 'Walk in Nature (10 min)', 'completed': false});
                  });
                },
                color: primaryColor,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ..._intentionalGoals.asMap().entries.map((entry) {
            final idx = entry.key;
            final g = entry.value;
            final isCompleted = g['completed'] == true;

            return TweenAnimationBuilder<double>(
              key: ValueKey(g['title']),
              tween: Tween<double>(begin: 0.0, end: 1.0),
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeOutQuad,
              builder: (context, val, child) {
                return Opacity(
                  opacity: AppAnimations.clampOpacity(val),
                  child: Transform.translate(
                    offset: Offset(0, 15 * (1.0 - val)),
                    child: child,
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 6.0),
                child: InkWell(
                  onTap: () {
                    final newStatus = !isCompleted;
                    if (newStatus) {
                      HapticFeedback.mediumImpact();
                    } else {
                      HapticFeedback.lightImpact();
                    }
                    setState(() {
                      _intentionalGoals[idx]['completed'] = newStatus;
                    });
                  },
                  child: Row(
                    children: [
                      _buildGoalCheckbox(isCompleted, primaryColor, isDark),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          g['title'] as String,
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 14,
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                            color: isCompleted
                                ? (isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.5) : const Color(0xff615e56).withValues(alpha: 0.5))
                                : (isDark ? Colors.white : Colors.black),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildWellBeingCard(bool isDark, Color primaryColor, Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
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
            children: [
              Icon(Icons.phonelink_off_rounded, color: primaryColor, size: 22),
              const SizedBox(width: 10),
              Text(
                'Digital Well-being',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Screen Time Tracker
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'SCREEN TIME LIMIT',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.0,
                  color: isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.5) : const Color(0xff615e56).withValues(alpha: 0.5),
                ),
              ),
              Text(
                '2h 15m / 3h',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: 0.75,
              minHeight: 6,
              backgroundColor: isDark ? const Color(0xff1a1c1a) : const Color(0xfff2f1ee),
              valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
            ),
          ),
          const SizedBox(height: 20),
          // Focus mode scheduler row
          _buildWellBeingToggle('Focus Mode', Icons.bedtime_outlined, true, primaryColor, isDark),
          const SizedBox(height: 12),
          _buildWellBeingToggle('DND Schedule', Icons.notifications_paused_outlined, false, primaryColor, isDark),
        ],
      ),
    );
  }

  Widget _buildWellBeingToggle(String label, IconData icon, bool active, Color primary, bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, size: 20, color: isDark ? const Color(0xffc2c8c0) : const Color(0xff615e56)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
        Switch.adaptive(
          value: active,
          activeColor: primary,
          onChanged: (val) {
            HapticFeedback.selectionClick();
          },
        ),
      ],
    );
  }

  Widget _buildRecentReflections(bool isDark, Color primaryColor, Color cardBg) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? const Color(0xff424842).withValues(alpha: 0.1) : const Color(0xffdbdad7).withValues(alpha: 0.4),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Recent Reflections',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          AnimatedList(
            key: _listKey,
            initialItemCount: _reflections.length,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index, animation) {
              final ref = _reflections[index];
              return _buildReflectionItem(ref, animation, primaryColor, isDark);
            },
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:habitrak/core/animations/app_animations.dart';
import 'package:habitrak/core/animations/staggered_entrance.dart';
import 'package:habitrak/core/theme/theme_cubit.dart';
import 'package:habitrak/core/storage/settings_repository.dart';
import '../../data/repositories/profile_repository.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late SettingsRepository _settingsRepository;
  late ProfileRepository _profileRepo;

  bool _remindersEnabled = true;
  String _userName = 'Jordan Smith';
  int _streakDays = 12;
  int _totalMindfulMinutes = 480;
  List<double> _heatmapIntensities = [];
  List<Map<String, dynamic>> _badges = [];

  @override
  void initState() {
    super.initState();
    _settingsRepository = context.read<SettingsRepository>();
    _profileRepo = context.read<ProfileRepository>();
    _remindersEnabled = _settingsRepository.getRemindersEnabled();
    _loadProfileData();
  }

  void _loadProfileData() {
    _userName = _profileRepo.getUserName();
    _streakDays = _profileRepo.getStreakDays();
    _totalMindfulMinutes = _profileRepo.getTotalMindfulMinutes();
    _heatmapIntensities = _profileRepo.getHeatmapIntensities();
    _badges = _profileRepo.getBadges();
  }

  String _getInitials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts[0].isEmpty) return 'U';
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  void _showEditNameDialog() {
    final nameCtrl = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (context) {
        final isDark = Theme.of(context).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xff1e201e) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            'Edit Profile Name',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: TextField(
            controller: nameCtrl,
            autofocus: true,
            style: TextStyle(color: isDark ? Colors.white : Colors.black),
            decoration: InputDecoration(
              labelText: 'Display Name',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final newName = nameCtrl.text.trim();
                if (newName.isNotEmpty) {
                  _profileRepo.setUserName(newName);
                  setState(() {
                    _userName = newName;
                  });
                  HapticFeedback.lightImpact();
                }
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xff8ba88e),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeCubit = context.watch<ThemeCubit>();
    final isDark = themeCubit.state == ThemeMode.dark;
    final primaryColor = isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e);
    final cardBg = isDark ? const Color(0xff1e201e) : const Color(0xffffffff);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Progress',
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
            _buildProfileCard(isDark, primaryColor, cardBg),
            const SizedBox(height: 24),
            StaggeredEntrance(index: 1, child: _buildHeatmapCard(isDark, primaryColor, cardBg)),
            const SizedBox(height: 24),
            StaggeredEntrance(index: 2, child: _buildBadgesCard(isDark, primaryColor, cardBg)),
            const SizedBox(height: 24),
            StaggeredEntrance(index: 3, child: _buildSettingsCard(isDark, primaryColor, cardBg)),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileCard(bool isDark, Color primaryColor, Color cardBg) {
    final initials = _getInitials(_userName);

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
          color: cardBg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isDark ? const Color(0xff424842).withValues(alpha: 0.1) : const Color(0xffdbdad7).withValues(alpha: 0.4),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: primaryColor.withValues(alpha: 0.2),
              child: Text(
                initials,
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          _userName,
                          style: TextStyle(
                            fontFamily: 'Hanken Grotesk',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, size: 18),
                        color: primaryColor,
                        padding: const EdgeInsets.only(left: 6),
                        constraints: const BoxConstraints(),
                        tooltip: 'Edit Name',
                        onPressed: _showEditNameDialog,
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      _buildProfileBadge(Icons.bolt, '$_streakDays Day Streak', primaryColor, isDark),
                      const SizedBox(width: 8),
                      _buildProfileBadge(Icons.timer_outlined, '${_totalMindfulMinutes}m total', primaryColor, isDark),
                    ],
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildProfileBadge(IconData icon, String text, Color primary, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xff1a1c1a) : const Color(0xfff2f1ee),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 13, color: primary),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: isDark ? const Color(0xffc2c8c0) : const Color(0xff615e56),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeatmapCard(bool isDark, Color primaryColor, Color cardBg) {
    const weeks = 5;
    const days = 7;
    const dayNames = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Consistency Heatmap',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Keep your active habits streak burning!',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.5) : const Color(0xff615e56).withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 24),
          // Heatmap grid
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Day initials
              Column(
                children: dayNames.map((d) {
                  return SizedBox(
                    height: 24,
                    width: 20,
                    child: Center(
                      child: Text(
                        d,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.5) : const Color(0xff615e56).withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(width: 8),
              // Squares Grid
              Expanded(
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: 6,
                    crossAxisSpacing: 6,
                    childAspectRatio: 1,
                  ),
                  itemCount: weeks * days,
                  itemBuilder: (context, idx) {
                    final intensity = idx < _heatmapIntensities.length
                        ? _heatmapIntensities[idx]
                        : 0.0;

                    return TweenAnimationBuilder<double>(
                      duration: Duration(milliseconds: 300 + (idx * 15)),
                      curve: Curves.easeOutBack,
                      tween: Tween<double>(begin: 0.0, end: 1.0),
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: value,
                          child: Opacity(
                            opacity: AppAnimations.clampOpacity(value),
                            child: child,
                          ),
                        );
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          color: intensity <= 0.05
                              ? (isDark ? const Color(0xff1a1c1a) : const Color(0xfff2f1ee))
                              : primaryColor.withValues(alpha: intensity.clamp(0.2, 1.0)),
                          borderRadius: BorderRadius.circular(6),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Text(
                'Less',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.5) : const Color(0xff615e56).withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(width: 6),
              _buildLegendBox(primaryColor.withValues(alpha: 0.15)),
              const SizedBox(width: 4),
              _buildLegendBox(primaryColor.withValues(alpha: 0.45)),
              const SizedBox(width: 4),
              _buildLegendBox(primaryColor.withValues(alpha: 0.85)),
              const SizedBox(width: 6),
              Text(
                'More',
                style: TextStyle(
                  fontSize: 10,
                  color: isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.5) : const Color(0xff615e56).withValues(alpha: 0.5),
                ),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildLegendBox(Color c) {
    return Container(
      width: 12,
      height: 12,
      decoration: BoxDecoration(
        color: c,
        borderRadius: BorderRadius.circular(3),
      ),
    );
  }

  Widget _buildBadgesCard(bool isDark, Color primaryColor, Color cardBg) {
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
            'Milestone Achievements',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          ..._badges.asMap().entries.map((entry) {
            final b = entry.value;
            final isUnlocked = b['unlocked'] == true;

            return StaggeredEntrance(
              index: entry.key,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 14.0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: (b['color'] as Color).withValues(alpha: isUnlocked ? 0.2 : 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        b['icon'] as IconData,
                        color: isUnlocked ? (b['color'] as Color) : (isDark ? Colors.white30 : Colors.black26),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                b['title'] as String,
                                style: TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              if (isUnlocked) ...[
                                const SizedBox(width: 6),
                                Icon(Icons.check_circle, size: 14, color: primaryColor),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            b['desc'] as String,
                            style: TextStyle(
                              fontSize: 12,
                              color: isDark ? const Color(0xffc2c8c0).withValues(alpha: 0.5) : const Color(0xff615e56).withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.share_outlined,
                        size: 20,
                        color: isDark ? const Color(0xffc2c8c0) : const Color(0xff615e56),
                      ),
                      tooltip: 'Share Achievement',
                      onPressed: () {
                        _showShareDialog(context, b);
                      },
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildShareCard({
    required BuildContext context,
    required Map<String, dynamic> badge,
    required bool isDark,
    required Color primaryColor,
  }) {
    final badgeColor = badge['color'] as Color;
    final badgeIcon = badge['icon'] as IconData;
    final badgeTitle = badge['title'] as String;
    final badgeDesc = badge['desc'] as String;
    final initials = _getInitials(_userName);

    final gradientColors = isDark
        ? [
            const Color(0xff1a1e1a),
            badgeColor.withValues(alpha: 0.08),
            const Color(0xff121412),
          ]
        : [
            const Color(0xfff5f7f5),
            badgeColor.withValues(alpha: 0.12),
            const Color(0xffffffff),
          ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.06)
              : Colors.black.withValues(alpha: 0.06),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.4)
                : Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.spa,
                    size: 22,
                    color: primaryColor,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'HabiTrak',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: primaryColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(100),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.verified_rounded,
                      size: 12,
                      color: primaryColor,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'VERIFIED',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                        color: primaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: primaryColor.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: CircleAvatar(
              radius: 28,
              backgroundColor: primaryColor.withValues(alpha: 0.15),
              child: Text(
                initials,
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: primaryColor,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _userName,
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'has successfully completed the achievement',
            style: TextStyle(
              fontSize: 12,
              color: isDark
                  ? const Color(0xffc2c8c0).withValues(alpha: 0.6)
                  : const Color(0xff615e56).withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.02)
                  : Colors.black.withValues(alpha: 0.02),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : Colors.black.withValues(alpha: 0.04),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: badgeColor.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: badgeColor.withValues(alpha: 0.2),
                        blurRadius: 8,
                        spreadRadius: 1,
                      )
                    ],
                  ),
                  child: Icon(
                    badgeIcon,
                    color: badgeColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        badgeTitle,
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        badgeDesc,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark
                              ? const Color(0xffc2c8c0).withValues(alpha: 0.7)
                              : const Color(0xff615e56).withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Divider(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.08),
            height: 1,
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xff1e201e)
                        : const Color(0xfff2f1ee),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '🔥',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '$_streakDays-Day Streak',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xffc2c8c0) : const Color(0xff615e56),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xff1e201e)
                        : const Color(0xfff2f1ee),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '⏱️',
                        style: TextStyle(fontSize: 14),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${_totalMindfulMinutes}m Total',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xffc2c8c0) : const Color(0xff615e56),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.shield_outlined,
                size: 12,
                color: isDark
                    ? const Color(0xffc2c8c0).withValues(alpha: 0.4)
                    : const Color(0xff615e56).withValues(alpha: 0.4),
              ),
              const SizedBox(width: 4),
              Text(
                'Successfully completed via HabiTrak',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: isDark
                      ? const Color(0xffc2c8c0).withValues(alpha: 0.4)
                      : const Color(0xff615e56).withValues(alpha: 0.4),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showShareDialog(BuildContext context, Map<String, dynamic> badge) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = isDark ? const Color(0xffb0ceb2) : const Color(0xff8ba88e);
    final cardBg = isDark ? const Color(0xff1e201e) : const Color(0xffffffff);

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        int shareState = 0; // 0 = Idle, 1 = Generating/Loading, 2 = Shared/Success

        return Dialog(
          backgroundColor: cardBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: StatefulBuilder(
            builder: (context, setStateDialog) {
              return Stack(
                children: [
                  SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(20.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Share Achievement',
                                style: TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : Colors.black,
                                ),
                              ),
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close, size: 20),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          _buildShareCard(
                            context: context,
                            badge: badge,
                            isDark: isDark,
                            primaryColor: primaryColor,
                          ),
                          const SizedBox(height: 24),
                          if (shareState == 0) ...[
                            ElevatedButton.icon(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: primaryColor,
                                foregroundColor: isDark ? Colors.black : Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              onPressed: () {
                                setStateDialog(() {
                                  shareState = 1;
                                });
                                Future.delayed(const Duration(milliseconds: 1400), () {
                                  if (context.mounted) {
                                    setStateDialog(() {
                                      shareState = 2;
                                    });
                                  }
                                  Future.delayed(const Duration(milliseconds: 1200), () {
                                    if (context.mounted) {
                                      Navigator.pop(context);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            children: [
                                              const Icon(Icons.check_circle, color: Colors.white, size: 20),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Successfully shared ${badge['title']}!',
                                                style: const TextStyle(fontWeight: FontWeight.w600),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: primaryColor,
                                          behavior: SnackBarBehavior.floating,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(10),
                                          ),
                                        ),
                                      );
                                    }
                                  });
                                });
                              },
                              icon: const Icon(Icons.share, size: 18),
                              label: const Text(
                                'Share to Social Feed',
                                style: TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            OutlinedButton.icon(
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(color: primaryColor.withValues(alpha: 0.5)),
                                foregroundColor: primaryColor,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              onPressed: () {
                                final textToCopy =
                                    '🏆 I completed the "${badge['title']}" milestone on HabiTrak! 🧘\nDescription: ${badge['desc']}\nStats: $_streakDays-Day Streak 🔥 & ${_totalMindfulMinutes}m total mindful activity ⏱️\nJoin me in building consistency with HabiTrak!';
                                Clipboard.setData(ClipboardData(text: textToCopy));
                                
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Row(
                                      children: [
                                        Icon(Icons.copy, color: Colors.white, size: 20),
                                        SizedBox(width: 8),
                                        Text('Copied achievement details to clipboard!'),
                                      ],
                                    ),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: isDark ? const Color(0xff2d312d) : const Color(0xff434943),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                                Navigator.pop(context);
                              },
                              icon: const Icon(Icons.copy, size: 18),
                              label: const Text(
                                'Copy Share Message',
                                style: TextStyle(
                                  fontFamily: 'Hanken Grotesk',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                            ),
                          ] else if (shareState == 1) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 20),
                              child: Column(
                                children: [
                                  SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(primaryColor),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Generating share card...',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              child: Column(
                                children: [
                                  TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0.0, end: 1.0),
                                    duration: const Duration(milliseconds: 400),
                                    builder: (context, val, child) {
                                      return Transform.scale(
                                        scale: val,
                                        child: Opacity(
                                          opacity: AppAnimations.clampOpacity(val),
                                          child: Icon(
                                            Icons.check_circle,
                                            color: primaryColor,
                                            size: 40,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Shared Successfully!',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      color: primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSettingsCard(bool isDark, Color primaryColor, Color cardBg) {
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
            'Preferences',
            style: TextStyle(
              fontFamily: 'Hanken Grotesk',
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.notifications_outlined, color: isDark ? const Color(0xffc2c8c0) : const Color(0xff615e56)),
                  const SizedBox(width: 12),
                  Text(
                    'Daily Reminders',
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
                value: _remindersEnabled,
                activeTrackColor: primaryColor,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _remindersEnabled = val;
                  });
                  _settingsRepository.setRemindersEnabled(val);
                },
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.dark_mode_outlined, color: isDark ? const Color(0xffc2c8c0) : const Color(0xff615e56)),
                  const SizedBox(width: 12),
                  Text(
                    'Dark Mode Theme',
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
                value: context.watch<ThemeCubit>().state == ThemeMode.dark,
                activeTrackColor: primaryColor,
                onChanged: (val) {
                  HapticFeedback.selectionClick();
                  context.read<ThemeCubit>().toggleTheme(val);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Theme set to ${val ? "Dark" : "Light"} Mode!'),
                      duration: const Duration(milliseconds: 800),
                    ),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:habitrak/core/theme/app_theme.dart';

class BentoSleepCard extends StatelessWidget {
  final int sleepEfficiency;
  final String sleepDuration;

  const BentoSleepCard({
    super.key,
    this.sleepEfficiency = 85,
    this.sleepDuration = '7h 15m',
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF16181A), // Deep matte obsidian card
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF2A2D32), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.35),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: 🌙 Sleep Analysis + Monthly dropdown pill
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Row(
                children: [
                  Icon(Icons.bedtime_outlined, size: 18, color: Colors.white),
                  SizedBox(width: 8),
                  Text(
                    'Sleep Analysis',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFF25282C),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Row(
                  children: [
                    Text(
                      'Monthly',
                      style: TextStyle(
                        fontFamily: 'Hanken Grotesk',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.white70,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: Colors.white70),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Two Key Metrics: Sleep Efficiency & Sleep Duration
          Row(
            children: [
              // 85% Sleep Efficiency (with Lime vertical bar)
              Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.limeAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: '$sleepEfficiency',
                              style: const TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            const TextSpan(
                              text: ' %',
                              style: TextStyle(
                                fontFamily: 'Hanken Grotesk',
                                fontSize: 13,
                                color: Colors.white70,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Text(
                        'Sleep Efficiency',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 10,
                          color: Color(0xFF8E939B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              const SizedBox(width: 28),

              // 7h 15m Sleep Duration (with Lavender vertical bar)
              Row(
                children: [
                  Container(
                    width: 3.5,
                    height: 24,
                    decoration: BoxDecoration(
                      color: AppColors.lavenderAccent,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        sleepDuration,
                        style: const TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const Text(
                        'Sleep Duration',
                        style: TextStyle(
                          fontFamily: 'Hanken Grotesk',
                          fontSize: 10,
                          color: Color(0xFF8E939B),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Dynamic Monthly Chart ending on Current Month
          SizedBox(
            height: 115,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: _buildDynamicMonthBars(),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDynamicMonthBars() {
    const monthNames = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    final now = DateTime.now();
    final List<Widget> bars = [];
    for (int i = 6; i >= 0; i--) {
      final mDate = DateTime(now.year, now.month - i, 1);
      final mLabel = monthNames[mDate.month - 1];
      final isCurrent = i == 0;
      if (isCurrent) {
        final limeH = (sleepEfficiency * 0.9).clamp(24.0, 90.0);
        final lavH = (limeH * 0.8).clamp(18.0, 75.0);
        bars.add(_buildHighlightMonthBar('$mLabel ↗', limeH, lavH));
      } else {
        final h = 35.0 + ((mDate.month * 7) % 35);
        bars.add(_buildMonthBar(mLabel, h, false));
      }
    }
    return bars;
  }

  Widget _buildMonthBar(String month, double height, bool isSelected) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Container(
          width: 28,
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF24272B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFF2F3338),
              width: 0.8,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          month,
          style: const TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: Color(0xFF6E737C),
          ),
        ),
      ],
    );
  }

  Widget _buildHighlightMonthBar(String month, double limeHeight, double lavenderHeight) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // Lime Bar
            Container(
              width: 14,
              height: limeHeight,
              decoration: BoxDecoration(
                color: AppColors.limeAccent,
                borderRadius: BorderRadius.circular(7),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.limeAccent.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            // Lavender Bar
            Container(
              width: 14,
              height: lavenderHeight,
              decoration: BoxDecoration(
                color: AppColors.lavenderAccent,
                borderRadius: BorderRadius.circular(7),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.lavenderAccent.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          month,
          style: const TextStyle(
            fontFamily: 'Hanken Grotesk',
            fontSize: 10,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}

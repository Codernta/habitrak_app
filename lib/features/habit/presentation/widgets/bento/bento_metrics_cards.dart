import 'package:flutter/material.dart';
import 'package:habitrak/core/theme/app_theme.dart';

class BentoMetricsCards extends StatelessWidget {
  final int heartRate;
  final int avgHeartRate;
  final double distanceKm;
  final int activeMinutes;

  const BentoMetricsCards({
    super.key,
    this.heartRate = 62,
    this.avgHeartRate = 78,
    this.distanceKm = 5.8,
    this.activeMinutes = 75,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildMetricCard(
            context: context,
            icon: Icons.favorite_border_rounded,
            title: 'Heart Rate',
            value: heartRate > 0 ? '$heartRate' : '--',
            unit: 'bpm',
            subLabel: avgHeartRate > 0 ? 'Avg\n$avgHeartRate Bpm' : 'Wearable sync',
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _buildMetricCard(
            context: context,
            icon: Icons.directions_run_rounded,
            title: 'Activity',
            value: distanceKm > 0 ? distanceKm.toStringAsFixed(1).replaceAll('.', ',') : '0,0',
            unit: 'km',
            subLabel: activeMinutes > 0 ? 'Active\n$activeMinutes Min' : 'Active\n0 Min',
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String value,
    required String unit,
    required String subLabel,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.charcoalCard : Colors.white;
    final borderCol = isDark ? AppColors.charcoalBorder : const Color(0xFFE8E9EC);
    final textPrimary = isDark ? Colors.white : AppColors.obsidianBlack;
    final textMuted = isDark ? const Color(0xFFA0A5AD) : const Color(0xFF7A7E85);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: borderCol, width: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header: Icon + title + 3-dots
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(icon, size: 16, color: textPrimary),
                  const SizedBox(width: 6),
                  Text(
                    title,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              Icon(Icons.more_vert_rounded, size: 16, color: textMuted),
            ],
          ),

          const SizedBox(height: 14),

          // Big value & Sub-label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    unit,
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: textMuted,
                    ),
                  ),
                ],
              ),
              Text(
                subLabel,
                textAlign: TextAlign.right,
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

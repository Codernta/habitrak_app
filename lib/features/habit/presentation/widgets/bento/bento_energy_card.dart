import 'package:flutter/material.dart';
import 'package:habitrak/core/theme/app_theme.dart';

class BentoEnergyCard extends StatelessWidget {
  final double totalCalories;
  final double runningCalories;
  final double workoutCalories;
  final double walkingCalories;

  const BentoEnergyCard({
    super.key,
    this.totalCalories = 4300,
    this.runningCalories = 2600,
    this.workoutCalories = 1200,
    this.walkingCalories = 500,
  });

  String _formatKcal(double kcal) {
    if (kcal >= 1000) {
      return '${(kcal / 1000).toStringAsFixed(1).replaceAll('.', ',')}k';
    } else {
      return kcal.round().toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.charcoalCard : Colors.white;
    final borderCol = isDark ? AppColors.charcoalBorder : const Color(0xFFE8E9EC);
    final textPrimary = isDark ? Colors.white : AppColors.obsidianBlack;
    final textMuted = isDark ? const Color(0xFFA0A5AD) : const Color(0xFF7A7E85);

    final sum = runningCalories + workoutCalories + walkingCalories;
    final effectiveSum = sum > 0 ? sum : (totalCalories > 0 ? totalCalories : 1.0);
    final runFraction = sum > 0 ? (runningCalories / effectiveSum).clamp(0.0, 1.0) : 0.45;
    final workFraction = sum > 0 ? (workoutCalories / effectiveSum).clamp(0.0, 1.0) : 0.30;
    final walkFraction = sum > 0 ? (walkingCalories / effectiveSum).clamp(0.0, 1.0) : 0.25;

    final runPercentStr = '${(runFraction * 100).round()}%';
    final workPercentStr = '${(workFraction * 100).round()}%';
    final walkPercentStr = '${(walkFraction * 100).round()}%';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: borderCol, width: 0.9),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.bolt_rounded, size: 20, color: textPrimary),
                  const SizedBox(width: 8),
                  Text(
                    'Energy Used',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              Icon(Icons.more_vert_rounded, size: 18, color: textMuted),
            ],
          ),

          const SizedBox(height: 14),

          // Value + pill badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                _formatKcal(totalCalories),
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'kcal today',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 12,
                  color: textMuted,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.limeAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  '+5%',
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.obsidianBlack,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3 Overlapping Modern Circles
          Center(
            child: SizedBox(
              width: 260,
              height: 160,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Lavender Circle (Running / Active)
                  Positioned(
                    left: 20,
                    top: 10,
                    child: Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        color: AppColors.lavenderAccent,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.lavenderAccent.withValues(alpha: 0.4),
                            blurRadius: 14,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatKcal(runningCalories),
                            style: const TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: AppColors.obsidianBlack,
                            ),
                          ),
                          const Text(
                            'kcal',
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 11,
                              color: AppColors.obsidianBlack,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Dark Obsidian Circle (Workouts)
                  Positioned(
                    right: 25,
                    top: 15,
                    child: Container(
                      width: 95,
                      height: 95,
                      decoration: BoxDecoration(
                        color: const Color(0xFF16181A),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.charcoalBorder : Colors.white,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.2),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatKcal(workoutCalories),
                            style: const TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          const Text(
                            'kcal',
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 10,
                              color: Colors.white70,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Electric Lime Circle (Walking)
                  Positioned(
                    bottom: 0,
                    left: 95,
                    child: Container(
                      width: 75,
                      height: 75,
                      decoration: BoxDecoration(
                        color: AppColors.limeAccent,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? AppColors.charcoalCard : Colors.white,
                          width: 2.5,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.limeAccent.withValues(alpha: 0.4),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      alignment: Alignment.center,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _formatKcal(walkingCalories),
                            style: const TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: AppColors.obsidianBlack,
                            ),
                          ),
                          const Text(
                            'kcal',
                            style: TextStyle(
                              fontFamily: 'Hanken Grotesk',
                              fontSize: 9,
                              color: AppColors.obsidianBlack,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Breakdown Progress Bars
          _buildActivityBar(
            percentage: runPercentStr,
            label: 'Running',
            dotColor: AppColors.lavenderAccent,
            barColor: AppColors.lavenderAccent,
            fillFraction: runFraction,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          const SizedBox(height: 12),
          _buildActivityBar(
            percentage: workPercentStr,
            label: 'Workouts',
            dotColor: const Color(0xFF16181A),
            barColor: isDark ? Colors.white70 : const Color(0xFF16181A),
            fillFraction: workFraction,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
          const SizedBox(height: 12),
          _buildActivityBar(
            percentage: walkPercentStr,
            label: 'Walking',
            dotColor: AppColors.limeAccentDark,
            barColor: AppColors.limeAccent,
            fillFraction: walkFraction,
            textPrimary: textPrimary,
            textMuted: textMuted,
          ),
        ],
      ),
    );
  }

  Widget _buildActivityBar({
    required String percentage,
    required String label,
    required Color dotColor,
    required Color barColor,
    required double fillFraction,
    required Color textPrimary,
    required Color textMuted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              percentage,
              style: TextStyle(
                fontFamily: 'Hanken Grotesk',
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: textPrimary,
              ),
            ),
            Row(
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'Hanken Grotesk',
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: textMuted,
                  ),
                ),
                const SizedBox(width: 6),
                Container(
                  width: 6,
                  height: 6,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: Container(
            height: 6,
            color: const Color(0xFFECEEF2),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: fillFraction,
              child: Container(
                decoration: BoxDecoration(
                  color: barColor,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

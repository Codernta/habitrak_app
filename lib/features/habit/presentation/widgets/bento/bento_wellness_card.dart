import 'package:flutter/material.dart';
import 'package:habitrak/core/theme/app_theme.dart';

class BentoWellnessCard extends StatelessWidget {
  final int wellnessScore;
  final int scoreDelta;

  const BentoWellnessCard({
    super.key,
    this.wellnessScore = 78,
    this.scoreDelta = 10,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark ? AppColors.charcoalCard : Colors.white;
    final borderCol = isDark ? AppColors.charcoalBorder : const Color(0xFFE8E9EC);
    final textPrimary = isDark ? Colors.white : AppColors.obsidianBlack;
    final textMuted = isDark ? const Color(0xFFA0A5AD) : const Color(0xFF7A7E85);

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
          // Header: % Wellness Index + menu
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    '%',
                    style: TextStyle(
                      fontFamily: 'Hanken Grotesk',
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Wellness Index',
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

          const SizedBox(height: 12),

          // Big value + Lime badge
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$wellnessScore',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -1,
                  color: textPrimary,
                ),
              ),
              const SizedBox(width: 4),
              Text(
                '%',
                style: TextStyle(
                  fontFamily: 'Hanken Grotesk',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: textMuted,
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.limeAccent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  scoreDelta >= 0 ? '+$scoreDelta%' : '$scoreDelta%',
                  style: const TextStyle(
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

          // Heatmap Matrix Grid (rounded periwinkle dots matching reference)
          SizedBox(
            height: 90,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: List.generate(10, (colIdx) {
                return Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(6, (rowIdx) {
                    final alpha = _getDotIntensity(colIdx, rowIdx);
                    return Container(
                      width: 9,
                      height: 9,
                      decoration: BoxDecoration(
                        color: AppColors.lavenderAccent.withValues(alpha: alpha),
                        shape: BoxShape.circle,
                      ),
                    );
                  }),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  double _getDotIntensity(int col, int row) {
    // Generate organic matrix density responsive to wellness score
    final pattern = [
      [0.2, 0.4, 0.7, 0.9, 0.8, 0.3],
      [0.3, 0.6, 0.8, 0.9, 0.7, 0.4],
      [0.5, 0.8, 0.9, 0.7, 0.5, 0.2],
      [0.2, 0.4, 0.6, 0.8, 0.6, 0.3],
      [0.4, 0.7, 0.9, 0.9, 0.8, 0.5],
      [0.1, 0.3, 0.5, 0.7, 0.4, 0.2],
      [0.3, 0.6, 0.8, 0.9, 0.7, 0.3],
      [0.6, 0.9, 0.9, 0.8, 0.6, 0.4],
      [0.2, 0.5, 0.7, 0.9, 0.8, 0.5],
      [0.4, 0.7, 0.9, 0.8, 0.6, 0.3],
    ];
    double base = 0.5;
    if (col < pattern.length && row < pattern[col].length) {
      base = pattern[col][row];
    }
    final factor = (wellnessScore / 100.0).clamp(0.2, 1.2);
    return (base * factor).clamp(0.08, 0.95);
  }
}
